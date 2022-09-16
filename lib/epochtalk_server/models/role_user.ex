defmodule EpochtalkServer.Models.RoleUser do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
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

  def delete_user_role(role_id, user_id) do
    query = from ru in RoleUser,
      where: ru.role_id == ^role_id and ru.user_id == ^user_id
    Repo.delete_all(query)
  end
end
