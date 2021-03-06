defmodule ExBanking.Account do
  use Agent

  @spec start_link(name :: atom() | String.t()) ::
          {:ok, pid()} | {:error, {:already_started, pid}} | {:error, any()}
  def start_link(name) do
    Agent.start_link(fn -> data() end, name: global_name(name))
  end

  @spec whereis(name :: atom() | String.t()) :: nil | pid()
  def whereis(name) do
    case :global.whereis_name({__MODULE__, name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def request(action, %{user: user} = args) do
    with {:ok, task} <- queue(user, action, args),
         {:ok, info} <- execute(user, task) do
      {:ok, info}
    end
  end

  defp execute(user, {_, :deposit, args} = task) do
    remove_queue(user, task)

    currency =
      args.currency
      |> String.to_atom()

    state =
      Agent.get_and_update(global_name(user), fn %{balance: balance} = state ->
        old_amount = if balance[currency], do: balance[currency], else: 0
        final = args.amount + old_amount

        state =
          Map.merge(
            state,
            %{balance: Map.merge(balance, %{currency => final})}
          )

        {state, state}
      end)

    {:ok, state.balance[currency]}
  end

  defp execute(user, {_, :withdraw, args} = task) do
    remove_queue(user, task)

    currency = String.to_atom(args.currency)

    get_money(user, currency, args.amount)
  end

  defp execute(user, {_, :get, args} = task) do
    remove_queue(user, task)

    currency = String.to_atom(args.currency)

    case get_currency(user, currency) do
      nil -> {:error, :wrong_arguments}
      amount -> {:ok, amount}
    end
  end

  defp execute(user, {_, :send, args} = task) do
    currency = String.to_atom(args.currency)

    user
    |> remove_queue(task)
    |> take_money(currency, args.amount)
    |> put_money(args.amount, args.to_user, args.currency)
  end

  defp take_money({:error, reason}, _currency, _amount), do: {:error, reason}

  defp take_money(user, currency, amount) do
    case get_money(user, currency, amount) do
      {:ok, money} -> money
      {:error, reason} -> {:error, reason}
    end
  end

  defp put_money({:error, reason}, _a, _t, _c), do: {:error, reason}

  defp put_money(money, amount, to_user, currency) do
    case request(:deposit, %{user: to_user, amount: amount, currency: currency}) do
      {:ok, amount} ->
        {:ok, money, amount}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_money(user, currency, amount) do
    case get_currency(user, currency) do
      nil ->
        {:error, :wrong_arguments}

      old_amount ->
        update_amount(user, currency, old_amount, amount)
    end
  end

  defp update_amount(user, currency, old_amount, amount) do
    if (real = old_amount - amount) >= 0 do
      state =
        Agent.get_and_update(global_name(user), fn %{balance: balance} = state ->
          final = Float.ceil(real, 2)

          state =
            Map.merge(
              state,
              %{balance: Map.merge(balance, %{currency => final})}
            )

          {state, state}
        end)

      {:ok, state.balance[currency]}
    else
      {:error, :not_enough_money}
    end
  end

  defp get_currency(user, currency), do: Agent.get(global_name(user), & &1)[:balance][currency]

  defp global_name(name), do: {:global, {__MODULE__, name}}

  defp data,
    do: %{
      balance: %{},
      queue: []
    }

  defp get_queue(user), do: Agent.get(global_name(user), & &1)[:queue]

  defp queue(user, action, args) do
    if get_queue(user) |> length() <= 9 do
      add_queue(user, action, args)
    else
      {:error, :too_many_requests_to_user}
    end
  end

  defp add_queue(user, action, args) do
    id = System.unique_integer([:positive])

    Agent.get_and_update(global_name(user), fn %{queue: queue} = state ->
      state = Map.merge(state, %{queue: queue ++ [{id, action, args}]})

      {state, state}
    end)

    {:ok, {id, action, args}}
  end

  defp remove_queue(user, task) do
    Agent.get_and_update(global_name(user), fn %{queue: queue} = state ->
      state = Map.merge(state, %{queue: queue -- [task]})

      {state, state}
    end)

    user
  end
end
