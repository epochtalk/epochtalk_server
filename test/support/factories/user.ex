defmodule Test.Support.Factories.User do
  @moduledoc """
  Factory for `User`

  This factory is really slow; DO NOT USE anywhere except user seed

  Usage:
  build(:user, [attributes])

  (optional role id)
  build(:user, [attributes]) |> with_role_id(1)
  """
  alias EpochtalkServer.Models.User

  defmacro __using__(_opts) do
    quote do
      def with_role_id(user, role_id) do
        insert(:role_user, role_id: role_id, user: user)
        user
      end

      def user_factory(attributes) do
        attributes
        |> User.create()
        |> case do
          {:ok, user} -> user
        end
      end
    end
  end
end
