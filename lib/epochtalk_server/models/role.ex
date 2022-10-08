defmodule EpochtalkServer.Models.Role do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  @moduledoc """
  `Role` model, for performing actions relating to user roles
  """

  @derive {Jason.Encoder, only: [:name, :description, :lookup, :priority, :highlight_color, :permissions, :priority_restrictions, :created_at, :updated_at]}
  schema "roles" do
    field :name, :string
    field :description, :string
    field :lookup, :string
    field :priority, :integer
    field :highlight_color, :string

    field :permissions, :map
    field :priority_restrictions, {:array, :integer}

    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for the `Role` model
  """
  @spec changeset(
    role :: %EpochtalkServer.Models.Role{},
    attrs :: %{} | nil
  ) :: %EpochtalkServer.Models.Role{}
  def changeset(role, attrs \\ %{}) do
    role
    |> cast(attrs, [:name, :description, :lookup, :priority, :permissions])
    |> validate_required([:name, :description, :lookup, :priority, :permissions])
  end

  ## === Database Functions ===

  ## SELECT OPERATIONS

  @doc """
  Returns every `Role` record in the database
  """
  @spec all() :: [%EpochtalkServer.Models.Role{}] | []
  def all, do: from(r in Role, order_by: r.id) |> Repo.all

  @doc """
  Returns id for the `banned` `Role`
  """
  @spec get_banned_role_id() :: integer | nil
  def get_banned_role_id(), do: Repo.one(from(r in Role, select: r.id, where: r.lookup == "banned"))

  @doc """
  Returns id for the `newbie` `Role`
  """
  @spec get_newbie_role_id() :: integer | nil
  def get_newbie_role_id(), do: Repo.one(from(r in Role, select: r.id, where: r.lookup == "newbie"))

  @doc """
  Returns default `Role`, for base installation this is the `user` role
  """
  @spec get_default() :: %EpochtalkServer.Models.Role{} | nil
  def get_default(), do: by_lookup("user")

  @doc """
  Returns a `Role` or list of roles, for specified lookup(s)
  """
  @spec by_lookup(
    lookup_or_lookups :: String.t() | [String.t()]
  ) :: %EpochtalkServer.Models.Role{} | [%EpochtalkServer.Models.Role{}] | [] | nil
  def by_lookup(lookups) when is_list(lookups) do
    from(r in Role, where: r.lookup in ^lookups) |> Repo.all
  end
  def by_lookup(lookup), do: Repo.get_by(Role, lookup: lookup)

  @doc """
  Returns a list containing a user's roles
  """
  @spec by_user_id(
    user_id :: integer
  ) :: [%EpochtalkServer.Models.Role{}]
  def by_user_id(user_id) do
    query = from ru in RoleUser,
      join: r in Role,
      where: ru.user_id == ^user_id and r.id == ru.role_id,
      select: r,
      order_by: [asc: r.priority]
    case Repo.all(query) do
      [] -> [get_default()] # user has no roles, return default role
      users_roles -> users_roles # user has roles, return them
    end
    |> Role.handle_banned_user_role # if banned, only [ banned ] is returned for roles
  end

  ## CREATE OPERATIONS

  # For seeding roles

  @doc """
  Inserts a new `Role` into the database
  """
  @spec insert(
    role_or_roles :: %EpochtalkServer.Models.Role{} | [%{}]
  ) :: {:ok, role :: %EpochtalkServer.Models.Role{}} | {non_neg_integer(), nil | [term()]} | {:error, Ecto.Changeset.t()}
  def insert([]), do: {:error, "Role list is empty"}
  def insert(%Role{} = role), do: Repo.insert(role)
  def insert([%{}|_] = roles), do: Repo.insert_all(Role, roles)

  ## UPDATE OPERATIONS

  @doc """
  Updates the permissions of an existing `Role` in the database
  """
  @spec set_permissions(
    id :: integer,
    permissions_attrs :: %{}
  ) :: {:ok, role :: %EpochtalkServer.Models.Role{}} | {:error, Ecto.Changeset.t()}
  def set_permissions(id, permissions) do
    Role
    |> Repo.get(id)
    |> change(%{ permissions: permissions })
    |> Repo.update
  end

  ## === External Helper Functions ===


  @doc """
  Default role is not stored in the database, in order to save space
  checks the role array on the user model
  if roles array is empty, sets the default role by appending it

  This helper needs to be called anywhere that modifies a user's roles
  and is expected to return the updated user's roles.
  """
  @spec handle_empty_user_roles(
    user :: %EpochtalkServer.Models.User{}
  ) :: %EpochtalkServer.Models.User{}
  def handle_empty_user_roles(%User{roles: [%Role{} | _]} = user), do: user
  def handle_empty_user_roles(%User{roles: []} = user), do: user |> Map.put(:roles, [Role.get_default()])
  def handle_empty_user_roles(%User{} = user), do: user |> Map.put(:roles, [Role.get_default()])

  @doc """
  The `banned` `Role` takes priority over all other roles
  If a `User` is banned, only return the `banned` `Role`

  This helper needs to be called anywhere that modifies a user's ban
  and is expected to return the updated user's roles.
  """
  @spec handle_banned_user_role(
    user_or_roles :: %EpochtalkServer.Models.User{} | [%EpochtalkServer.Models.Role{}]
  ) :: %EpochtalkServer.Models.User{} | [%EpochtalkServer.Models.Role{}]
  # called with user model, outputs user model with updated role
  def handle_banned_user_role(%User{roles: [%Role{} | _] = roles} = user) do
    if banned_role = Enum.find(roles, &(&1.lookup == "banned")),
      do: user |> Map.put(:roles, [banned_role]),
      else: user
   end
  # called with just roles, ouput updated roles
  def handle_banned_user_role(roles), do: if ban_role = reduce_ban_role(roles), do: [ban_role], else: roles


  @doc """
  Takes in list of user's roles, and returns an xored map of all `Role` permissions
  """
  @spec get_masked_permissions(
    roles :: [%EpochtalkServer.Models.Role{}]
  ) :: %{}
  # Given %User{}.roles, outputs xored permissions
  def get_masked_permissions(roles) when is_list(roles), do: Enum.reduce(roles, %{}, &mask_permissions(&2, &1))

  ## === Private Helper Functions ===

  defp mask_permissions(target, source) do
    merge_keys = [:highlight_color, :permissions, :priority, :priority_restrictions]
    filtered_source_keys = Map.keys(source) |> Enum.filter(&Enum.member?(merge_keys, &1))
    target_is_lesser_role = !Map.get(target, :priority) or target.priority > source.priority
    Enum.reduce(filtered_source_keys, %{}, fn key, acc ->
      case key do
        :priority_restrictions -> # merge priority restrictions
          source_pr = source.priority_restrictions
          if target_is_lesser_role and !!source_pr and length(source_pr),
            do: Map.put(acc, :priority_restrictions, source_pr),
            else: Map.put(acc, :priority_restrictions, Map.get(target, :priority_restrictions))
        :permissions -> # merge permissions
          target_permissions = if p = Map.get(target, key), do: p, else: %{}
          Map.put(acc, key, deep_merge(target_permissions, Map.get(source, key)))
        key when key in [:priority, :highlight_color] -> # merge priority/highlight_color
          if target_is_lesser_role, do: Map.put(acc, key, Map.get(source, key)), else: Map.put(acc, key, Map.get(target, key))
      end
    end)
  end

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}), do: deep_merge(left, right)
  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right), do: right

  defp reduce_ban_role([]), do: nil
  defp reduce_ban_role([role | _]) when role.lookup === "banned", do: role
  defp reduce_ban_role([_ | roles]), do: reduce_ban_role(roles)
end
