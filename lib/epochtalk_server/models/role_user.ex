defmodule EpochtalkServer.Models.RoleUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  @admin_role_id 1

  @primary_key false
  schema "roles_users" do
    belongs_to :user, User
    belongs_to :role, Role
  end

  def changeset(role_user, attrs \\ %{}) do
    role_user
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end
  def set_admin(%User{} = user), do: set_role(user, @admin_role_id)
  def set_role(%User{} = user, role_id) do
    %RoleUser{}
    |> RoleUser.changeset(%{user_id: user.id, role_id: role_id})
    |> Repo.insert
  end
end
