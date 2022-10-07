defmodule EpochtalkServer.Models.RoleUser do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  @moduledoc """
  `RoleUser` model, for performing actions relating a setting a `Role` for a `User`
  """

  @admin_role_id 1
  @primary_key false
  schema "roles_users" do
    belongs_to :user, User
    belongs_to :role, Role
  end

  ## === Changesets Functions ===

  @doc """
  Creates a generic changeset for `RoleUser` model
  """
  @spec changeset(
    role_user :: %EpochtalkServer.Models.RoleUser{},
    attrs :: %{} | nil
  ) :: %EpochtalkServer.Models.RoleUser{}
  def changeset(role_user, attrs \\ %{}) do
    role_user
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  ## === Database Functions ===

  @doc """
  Assigns a specific `User` to have the `superAdministrator` `Role`
  """
  @spec set_admin(
    user_id :: integer
  ) :: {:ok, role_user :: %EpochtalkServer.Models.RoleUser{}} | {:error, Ecto.Changeset.t()}
  def set_admin(user_id), do: set_user_role(@admin_role_id, user_id)

  @doc """
  Assigns a specific `User` to have the specified `Role`
  """
  @spec set_user_role(
    role_id :: integer,
    user_id :: integer
  ) :: {:ok, role_user :: %EpochtalkServer.Models.RoleUser{}} | {:error, Ecto.Changeset.t()}
  def set_user_role(role_id, user_id) do
    case Repo.one(from(ru in RoleUser, where: ru.role_id == ^role_id and ru.user_id == ^user_id)) do
      nil -> Repo.insert(changeset(%RoleUser{}, %{role_id: role_id, user_id: user_id}))
      role_user -> {:ok, role_user}
    end
  end

  @doc """
  Removes specified `Role` from specified `User`
  """
  @spec delete_user_role(
    role_id :: integer,
    user_id :: integer
  ) :: {non_neg_integer(), nil | [term()]}
  def delete_user_role(role_id, user_id) do
    query = from ru in RoleUser,
      where: ru.role_id == ^role_id and ru.user_id == ^user_id
    Repo.delete_all(query)
  end
end
