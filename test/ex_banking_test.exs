defmodule ExBankingTest do
  use ExUnit.Case, async: true

  alias ExBanking.Account

  describe "create_user/1" do
    test "returns ok, when create a new user" do
      user = "user"
      assert ExBanking.create_user(user) == :ok
    end

    test "returns error, when wrong args" do
      assert ExBanking.create_user(:user) == {:error, :wrong_arguments}
    end

    test "returns error, when user already exists" do
      user = "novo"

      assert ExBanking.create_user(user) == :ok
      assert ExBanking.create_user(user) == {:error, :user_already_exists}
    end
  end

  describe "deposit/3" do

  end

  describe "withdraw/3" do

  end

  describe "get_balance/2" do

  end
end
