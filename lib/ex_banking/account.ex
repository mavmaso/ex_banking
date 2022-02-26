defmodule ExBanking.Account do
  use Agent

  @spec start_link(name :: atom() | String.t()) :: {:ok, pid()} | {:error, {:already_started, pid}} | {:error, any()}
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
  end

  defp execute(user, {_, :deposit, args} = task) do
    remove_queue(user, task)

    currency =
      args.currency
      |> String.downcase()
      |> String.to_atom()

    state = Agent.get_and_update(global_name(user), fn %{balance: balance} = state ->

      old_amount = if balance[currency], do: balance[currency], else: 0

      state = Map.merge(
        state,
        %{balance: Map.merge(balance, %{currency => args.amount + old_amount})}
        )

      {state, state}
    end)

    {:ok, %{currency => state.balance[currency]}}
  end

  defp get_queue(user), do: Agent.get(global_name(user), & &1)[:queue]

  defp global_name(name), do: {:global, {__MODULE__, name}}

  defp data, do: %{
    balance: %{},
    queue: []
  }
end
