defmodule ExBanking.AccountSupervisor do
  use DynamicSupervisor

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec open(user :: String.t()) :: {:ok, pid()} | {:error, {:already_started, pid()}}
  def open(name) do
    DynamicSupervisor.start_child(__MODULE__, {ExBanking.Account, name})
  end
end
