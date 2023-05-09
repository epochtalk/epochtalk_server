defmodule EpochtalkServer.Models.Role do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Cache.Role, as: RoleCache

  @postgres_integer_max 2_147_483_647
  @postgres_varchar255_max 255
  @description_max 1000

  @moduledoc """
  `Role` model, for performing actions relating to user roles
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          lookup: String.t() | nil,
          priority: non_neg_integer | nil,
          highlight_color: String.t() | nil,
          permissions: map() | nil,
          priority_restrictions: [non_neg_integer] | nil,
          created_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :name,
             :description,
             :lookup,
             :priority,
             :highlight_color,
             :permissions,
             :priority_restrictions,
             :created_at,
             :updated_at
           ]}
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
  @spec changeset(role :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(role, attrs \\ %{}) do
    role
    |> cast(attrs, [:name, :description, :lookup, :priority, :permissions])
    |> validate_required([:name, :description, :lookup, :priority, :permissions])
  end

  @doc """
  Create a changeset for updating a `Role`
  permissions and priority restrictions are not included in this changeset
  """
  @spec update_changeset(role :: Role.t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def update_changeset(role, attrs \\ %{}) do
    updated_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    role =
      role
      |> Map.put(:updated_at, updated_at)

    # filter out nil attrs
    attrs =
      attrs
      |> Map.filter(fn {_k, v} -> v != nil end)

    role
    |> cast(attrs, [:id, :name, :description, :priority, :highlight_color, :lookup])
    |> validate_required([:id, :name, :description, :priority, :lookup])
    |> validate_length(:name, min: 1, max: @postgres_varchar255_max)
    |> validate_length(:description, min: 1, max: @description_max)
    |> validate_number(:priority,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: @postgres_integer_max
    )
    |> validate_format(:highlight_color, ~r/^#([0-9a-f]{6})$/i)
    |> validate_length(:lookup, min: 1, max: @postgres_varchar255_max)
    |> unique_constraint(:lookup, name: :roles_lookup_index)
  end

  ## === Database Functions ===

  ## SELECT OPERATIONS

  @doc """
  Returns every `Role` record in the database
  WARNING: Only use for startup/seeding; use Role.all elsewhere
  """
  @spec all_repo() :: [t()] | []
  def all_repo, do: from(r in Role, order_by: r.id) |> Repo.all()

  @doc """
  Uses role cache to returns every `Role` record
  """
  @spec all() :: [t()]
  def all(), do: RoleCache.all()

  @doc """
  Returns id for the `banned` `Role`
  """
  @spec get_banned_role_id() :: integer | nil
  def get_banned_role_id(), do: RoleCache.by_lookup("banned").id

  @doc """
  Returns id for the `newbie` `Role`
  """
  @spec get_newbie_role_id() :: integer | nil
  def get_newbie_role_id(), do: RoleCache.by_lookup("newbie").id

  @doc """
  Returns default `Role`, for base installation this is the `user` role, if `:epochtalk_server[:frontend_config]["newbie_enabled"]`
  configuration is set to true, then `newbie` is the default role.
  """
  @spec get_default() :: t() | nil
  def get_default() do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    newbie_enabled = config["newbie_enabled"]
    RoleCache.by_lookup(if newbie_enabled, do: "newbie", else: "user")
  end

  @doc """
  Returns default `Role`, for base installation this is the `user` role, if `:epochtalk_server[:frontend_config]["newbie_enabled"]`
  configuration is set to true, then `newbie` is the default role.
  """
  @spec get_default_unauthenticated() :: t() | nil
  def get_default_unauthenticated() do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    login_required = config["login_required"]
    RoleCache.by_lookup(if login_required, do: "private", else: "anonymous")
  end

  @doc """
  Returns a `Role` for specified lookup
  WARNING: Only used for startup/seeding; use Role.by_lookup elsewhere
  """
  @spec by_lookup_repo(lookup :: String.t() | [String.t()]) :: t() | nil
  def by_lookup_repo(lookup), do: Repo.get_by(Role, lookup: lookup)

  @doc """
  Uses role cache to return `Role` or list of `Role`s for specified lookup(s)
  """
  @spec by_lookup(lookup_or_lookups :: String.t() | [String.t()]) :: t() | [t()] | [] | nil
  def by_lookup(lookup_or_lookups), do: RoleCache.by_lookup(lookup_or_lookups)

  # @doc """
  # Returns a list containing a user's roles
  # """
  # @spec by_user_id(user_id :: integer) :: [t()]
  # def by_user_id(user_id) do
  #   query =
  #     from ru in RoleUser,
  #       join: r in Role,
  #       on: true,
  #       where: ru.user_id == ^user_id and r.id == ru.role_id,
  #       select: r,
  #       order_by: [asc: r.priority]
  #
  #   case Repo.all(query) do
  #     # user has no roles, return default role
  #     [] -> [get_default()]
  #     # user has roles, return them
  #     users_roles -> users_roles
  #   end
  #   # if banned, only [ banned ] is returned for roles
  #   |> Role.handle_banned_user_role()
  # end

  ## CREATE OPERATIONS

  # For seeding roles

  @doc """
  Inserts a new `Role` into the database
  """
  @spec insert(role_or_roles :: t() | [%{}]) ::
          {:ok, role :: t()} | {non_neg_integer(), nil | [term()]} | {:error, Ecto.Changeset.t()}
  def insert([]), do: {:error, "Role list is empty"}
  def insert(%Role{} = role), do: Repo.insert(role)
  def insert([%{} | _] = roles), do: Repo.insert_all(Role, roles)

  ## UPDATE OPERATIONS
  @doc """
  Updates an existing `Role` in the database and reloads role cache
  """
  @spec update(attrs :: map()) ::
          {:ok, role :: Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(attrs) do
    Role
    |> Repo.get(attrs["id"])
    |> update_changeset(attrs)
    |> Repo.update()
    |> reload_role_cache_on_success()
  end

  @doc """
  Updates the permissions of an existing `Role` in the database
  and reloads role cache
  """
  @spec set_permissions(id :: integer, permissions_attrs :: map()) ::
          {:ok, role :: Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def set_permissions(id, permissions) do
    Role
    |> Repo.get(id)
    |> change(%{permissions: permissions})
    |> Repo.update()
    |> reload_role_cache_on_success()
  end

  @doc """
  Updates the priority_restrictions of an existing `Role` in the database
  and reloads role cache
  """
  @spec set_priority_restrictions(id :: integer, priority_restrictions :: list() | nil) ::
          {:ok, role :: Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def set_priority_restrictions(id, []) do
    id
    |> set_priority_restrictions(nil)
    |> reload_role_cache_on_success()
  end

  def set_priority_restrictions(id, priority_restrictions) do
    Role
    |> Repo.get(id)
    |> change(%{priority_restrictions: priority_restrictions})
    |> Repo.update()
    |> reload_role_cache_on_success()
  end

  ## === External Helper Functions ===

  @doc """
  Default role is not stored in the database, in order to save space
  checks the role array on the user model
  if roles array is empty, sets the default role by appending it

  This helper needs to be called anywhere that modifies a user's roles
  and is expected to return the updated user's roles.
  """
  @spec handle_empty_user_roles(user :: User.t()) :: User.t()
  def handle_empty_user_roles(%User{roles: [%Role{} | _]} = user), do: user

  def handle_empty_user_roles(%User{roles: []} = user),
    do: user |> Map.put(:roles, [Role.get_default()])

  def handle_empty_user_roles(%User{} = user), do: user |> Map.put(:roles, [Role.get_default()])

  @doc """
  The `banned` `Role` takes priority over all other roles
  If a `User` is banned, only return the `banned` `Role`

  This helper needs to be called anywhere that modifies a user's ban
  and is expected to return the updated user's roles.
  """
  @spec handle_banned_user_role(user_or_roles :: User.t() | [t()]) :: User.t() | [t()]
  # called with user model, outputs user model with updated role
  def handle_banned_user_role(%User{roles: [%Role{} | _] = roles} = user) do
    if banned_role = Enum.find(roles, &(&1.lookup == "banned")),
      do: user |> Map.put(:roles, [banned_role]),
      else: user
  end

  # called with just roles, ouput updated roles
  def handle_banned_user_role(roles),
    do: if(ban_role = reduce_ban_role(roles), do: [ban_role], else: roles)

  @doc """
  Takes in list of user's roles, and returns an xored map of all `Role` permissions
  """
  @spec get_masked_permissions(roles :: [t()]) :: map()
  def get_masked_permissions(roles) when is_list(roles) do
    masked_role = Enum.reduce(roles, %{}, &mask_permissions(&2, &1))

    masked_role.permissions
    |> Map.put(:highlight_color, masked_role.highlight_color)
    |> Map.put(:priority_restrictions, masked_role.priority_restrictions)
    |> Map.put(:priority, masked_role.priority)
  end

  ## === Private Helper Functions ===

  defp reload_role_cache_on_success(result) do
    case result do
      {:ok, role} ->
        # reload cache on success
        RoleCache.reload()
        {:ok, role}

      default ->
        default
    end
  end

  defp mask_permissions(target, source) do
    merge_keys = [:highlight_color, :permissions, :priority, :priority_restrictions]
    filtered_source_keys = Map.keys(source) |> Enum.filter(&Enum.member?(merge_keys, &1))
    target_is_lesser_role = !Map.get(target, :priority) or target.priority > source.priority

    Enum.reduce(filtered_source_keys, %{}, fn key, acc ->
      case key do
        :priority_restrictions ->
          merge_priority_restrictions(acc, target, source, target_is_lesser_role)

        :permissions ->
          merge_permissions(acc, target, source)

        :priority ->
          merge_key(:priority, acc, target, source, target_is_lesser_role)

        :highlight_color ->
          merge_key(:highlight_color, acc, target, source, target_is_lesser_role)
      end
    end)
  end

  defp merge_priority_restrictions(acc, target, source, target_is_lesser_role) do
    source_pr = source.priority_restrictions

    if target_is_lesser_role and !!source_pr and length(source_pr),
      do: Map.put(acc, :priority_restrictions, source_pr),
      else: Map.put(acc, :priority_restrictions, Map.get(target, :priority_restrictions))
  end

  defp merge_permissions(acc, target, source) do
    target_permissions = if p = Map.get(target, :permissions), do: p, else: %{}
    Map.put(acc, :permissions, deep_merge(target_permissions, Map.get(source, :permissions)))
  end

  defp merge_key(key, acc, target, source, target_is_lesser_role) do
    if target_is_lesser_role,
      do: Map.put(acc, key, Map.get(source, key)),
      else: Map.put(acc, key, Map.get(target, key))
  end

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, %{} = left, %{} = right), do: deep_merge(left, right)
  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right), do: right

  defp reduce_ban_role([]), do: nil
  defp reduce_ban_role([role | _]) when role.lookup === "banned", do: role
  defp reduce_ban_role([_ | roles]), do: reduce_ban_role(roles)
end
