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

  defp global_name(name), do: {:global, {__MODULE__, name}}

  defp data, do: %{
    balance: %{},
    queue: []
  }
end
