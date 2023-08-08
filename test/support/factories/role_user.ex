defmodule Test.Support.Factories.RoleUser do
  @moduledoc """
  Factory for `RoleUser`
  """
  alias EpochtalkServer.Models.RoleUser

  defmacro __using__(_opts) do
    quote do
      def role_user_factory(%{role_id: role_id, user: user}) do
        %RoleUser{
          user: user,
          role_id: role_id
        }
      end
    end
  end
end
