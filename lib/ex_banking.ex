defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.AccountSupervisor
  alias ExBanking.Account

  @spec create_user(user :: String.t) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_bitstring(user) do
    case AccountSupervisor.open(user) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    with :ok <- check_args(user, amount, currency),
      {:ok, user} <- check_user(user) do
      Account.request(:deposit, %{user: user, amount: amount, currency: currency})
    end
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :not_enough_money | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    with :ok <- check_args(user, amount, currency),
      {:ok, user} <- check_user(user) do
        Account.request(:withdraw, %{user: user, amount: amount, currency: currency})
    end
  end

  # @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  # Returns balance of the user in given format

  defp check_user(user) do
    case Account.whereis(user) do
      nil -> {:error, :user_does_not_exist}
      _pid -> {:ok, user}
    end
  end

  defp check_args(user, amount, currency) do
    if is_bitstring(user) and is_number(amount) and is_bitstring(currency) do
      :ok
    else
      {:error, :wrong_arguments}
    end
  end
end
