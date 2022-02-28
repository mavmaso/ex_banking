defmodule ExBankingTest do
  use ExUnit.Case, async: true

  alias ExBanking.Account

  describe "create_user/1" do
    test "returns ok when create a new user" do
      user = "user"
      assert ExBanking.create_user(user) == :ok
    end

    test "returns error when wrong args" do
      assert ExBanking.create_user(:user) == {:error, :wrong_arguments}
    end

    test "returns error when user already exists" do
      user = "novo"

      assert ExBanking.create_user(user) == :ok
      assert ExBanking.create_user(user) == {:error, :user_already_exists}
    end
  end

  describe "deposit/3" do
    setup do
      user = "deposito"
      ExBanking.create_user(user)

      {:ok, user: user}
    end

    test "returns ok when valid data and request can be accept", %{user: user} do
      amount = 10.00

      assert ExBanking.deposit(user, amount, "BRL") == {:ok, 10.00}
      assert ExBanking.deposit(user, 15.10, "BRL") == {:ok, 25.10}
      assert ExBanking.deposit(user, 5, "BRL") == {:ok, 30.10}

      assert ExBanking.deposit(user, amount, "USD") == {:ok, 10.00}
    end

    test "returns error when wrong args", %{user: user} do
      assert ExBanking.deposit(123, "32", "BRL") == {:error, :wrong_arguments}
      assert ExBanking.deposit(user, "32", "BRL") == {:error, :wrong_arguments}
      assert ExBanking.deposit(user, 10.00, :usd) == {:error, :wrong_arguments}
    end

    test "returns error when invalid user" do
      user = "non"
      assert ExBanking.deposit(user, 10.00, "BRL") == {:error, :user_does_not_exist}
    end

    test "returns error when too many request", %{user: user} do
      queue_factory(user, [1,2,3,4,5,6,7,8,9,10])

      assert ExBanking.deposit(user, 100, "err") == {:error, :too_many_requests_to_user}

      queue_factory(user, [])
    end
  end

  describe "withdraw/3" do
    setup do
      user = "retirada"
      ExBanking.create_user(user)

      {:ok, user: user}
    end

    test "returns ok when valid data and request can be accept", %{user: user} do
      amount = 10.00

      assert ExBanking.deposit(user, amount, "sol") == {:ok, 10.00}
      assert ExBanking.withdraw(user, 9.99, "sol") == {:ok, 0.01}
    end

    test "returns error when don't have enough money", %{user: user} do
      amount = 10.00

      assert ExBanking.deposit(user, amount, "lua") == {:ok, 10.00}
      assert ExBanking.withdraw(user, 10.01, "lua") == {:error, :not_enough_money}
    end

    test "returns error when wrong args", %{user: user} do
      amount = 10.00

      assert ExBanking.withdraw(:user, amount, "sol") == {:error, :wrong_arguments}
      assert ExBanking.withdraw(user, "123", "sol") == {:error, :wrong_arguments}
      assert ExBanking.withdraw(user, amount, 123) == {:error, :wrong_arguments}
    end

    test "returns error when invalid user" do
      user = "non"
      assert ExBanking.withdraw(user, 21, "sol") == {:error, :user_does_not_exist}
    end

    test "returns error when too many request", %{user: user} do
      queue_factory(user, [1,2,3,4,5,6,7,8,9,10])

      assert ExBanking.withdraw(user, 21, "sol")  == {:error, :too_many_requests_to_user}

      queue_factory(user, [])
    end
  end

  describe "get_balance/2" do
    setup do
      user = "saldo"
      ExBanking.create_user(user)

      {:ok, user: user}
    end

    test "returns ok when valid data and request can be accept", %{user: user} do
      amount = 10.00

      assert ExBanking.deposit(user, amount, "VIE") == {:ok, amount}
      assert ExBanking.get_balance(user, "VIE") == {:ok, amount}
      refute ExBanking.get_balance(user, "vie") == {:ok, amount}
    end

    test "returns error when wrong args", %{user: user} do
      assert ExBanking.get_balance(:user, "vie") == {:error, :wrong_arguments}
      assert ExBanking.get_balance(user,  123) == {:error, :wrong_arguments}
    end

    test "returns error when invalid user" do
      user = "non"
      assert ExBanking.get_balance(user, "VIE") == {:error, :user_does_not_exist}
    end

    test "returns error when too many request", %{user: user} do
      queue_factory(user, [1,2,3,4,5,6,7,8,9,10])

      assert ExBanking.get_balance(user, "vie")  == {:error, :too_many_requests_to_user}

      queue_factory(user, [])
    end
  end

  describe "send/4" do
    setup do
      user = "envio"
      to_user = "recebe"
      ExBanking.create_user(user)
      ExBanking.create_user(to_user)

      {:ok, user: user, to_user: to_user}
    end

    test "returns ok when valid data and request can be accept", %{user: user, to_user: to_user} do
      amount = 11.00

      assert ExBanking.deposit(user, amount, "brl") == {:ok, amount}
      assert ExBanking.send(user, to_user, amount, "brl") == {:ok, 0.00, 11.00}
    end

    test "returns error when sender don't have enough money", %{user: user,  to_user: to_user} do
      amount = 1.00

      assert ExBanking.deposit(user, amount, "lua") == {:ok, 1.00}
      assert ExBanking.send(user, to_user, 12.01, "lua") == {:error, :not_enough_money}
    end
  end

  defp queue_factory(user, value) do
    Agent.get_and_update(Account.whereis(user), fn state ->
      state = Map.merge(state, %{queue: value})

      {state, state}
    end)
  end
end
