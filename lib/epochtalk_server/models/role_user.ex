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

  ## === Changesets Functions ===

  def changeset(role_user, attrs \\ %{}) do
    role_user
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  ## === Database Functions ===

  def set_admin(user_id), do: set_user_role(@admin_role_id, user_id)

  def set_user_role(role_id, user_id) do
    case Repo.one(from(ru in RoleUser, where: ru.role_id == ^role_id and ru.user_id == ^user_id)) do
      nil -> Repo.insert(changeset(%RoleUser{}, %{role_id: role_id, user_id: user_id}))
      roleuser_cs -> {:ok, roleuser_cs}
    end
  end

  def delete_user_role(role_id, user_id) do
    query = from ru in RoleUser,
      where: ru.role_id == ^role_id and ru.user_id == ^user_id
    Repo.delete_all(query)
  end
end
