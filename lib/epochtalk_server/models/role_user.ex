defmodule EpochtalkServer.Models.RoleUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role

  schema "roles_users" do
    belongs_to :user, User
    belongs_to :role, Role
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end
end
