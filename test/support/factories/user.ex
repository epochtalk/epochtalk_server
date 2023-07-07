defmodule Test.Support.Factories.User do
  @moduledoc """
  Factory for `User`

  Usage:
  build(:user)
  OR
  build(:user, admin: true)
  """
  alias EpochtalkServer.Models.User

  defmacro __using__(_opts) do
    quote do
      def user_attributes_factory do
        %{
          username: sequence(:user_username, &"username#{&1}"),
          email: sequence(:user_email, &"email#{&1}@test.com"),
          password: sequence(:user_password, &"password#{&1}")
        }
      end
      def user_factory(%{admin: true}) do
        build(:user_attributes)
        |> User.create(true)
        |> case do
          {:ok, user} -> user
        end
      end
      def user_factory(_attrs) do
        build(:user_attributes)
        |> User.create()
        |> case do
          {:ok, user} -> user
        end
      end
    end
  end
end
