defmodule EpochtalkServer.Models.RoleUser do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser

  schema "roles_users" do
    belongs_to :user, User
    belongs_to :role, Role
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  def delete(role_id, user_id) do
    query = from ru in RoleUser,
      where: ru.role_id == ^role_id and ru.user_id == ^user_id
    Repo.delete_all(query)
  end
end
