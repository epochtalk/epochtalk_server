defmodule EpochtalkServer.Models.RolePermission do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.RolePermission
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.Permission

  @moduledoc """
  `RolePermission` model, for performing actions relating to a roles permissions
  """

  @type t :: %__MODULE__{
          role: Role.t() | term(),
          permission: Permission.t() | term(),
          value: boolean | nil,
          modified: boolean | nil
        }
  @primary_key false
  schema "roles_permissions" do
    belongs_to :role, Role, foreign_key: :role_id, type: :integer

    belongs_to :permission, Permission,
      foreign_key: :permission_path,
      references: :path,
      type: :string

    # value XOR modified -> final value
    # (value || modified) && !(value && modified)
    # elixir is not as awesome as erlang because no XOR on booleans
    field :value, :boolean
    field :modified, :boolean
  end

  ## === Changesets Functions ===

  @doc """
  Creates a generic changeset for `RolePermission` model
  """
  @spec changeset(role_permission :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(role_permission, attrs \\ %{}) do
    role_permission
    |> cast(attrs, [:role_id, :permission_path, :value, :modified])
    |> validate_required([:role_id, :permission_path, :value, :modified])
  end

  ## === Database Functions ===

  @doc """
  Inserts a new `RolePermission` into the database
  """
  @spec insert(role_permission_or_role_permissions :: t() | [map()]) ::
          {:ok, role :: t()} | {non_neg_integer(), nil | [term()]} | {:error, Ecto.Changeset.t()}
  def insert([]), do: {:error, "Role permission list is empty"}
  def insert(%RolePermission{} = role_permission), do: Repo.insert(role_permission)

  def insert([%{} | _] = roles_permissions),
    do: Repo.insert_all(RolePermission, roles_permissions)

  @doc """
  For admin api use.

  Updates the `modified` value of `RolePermission`s for a `Role`
  and updates the `Role`'s permissions and priority restrictions

  This method sets any permissions not specified in `new_permissions`
  to `false`. If all permissions should be set to `false`, `new_permissions`
  may be an empty list.
  """
  @spec modify_by_role(role :: Role.t()) :: {:ok, :success}
  def modify_by_role(
        %Role{
          id: role_id,
          permissions: new_permissions,
          priority_restrictions: priority_restrictions
        } = _new_role
      ) do
    # get current set of role permissions
    current_role_permissions =
      from(rp in RolePermission,
        where: rp.role_id == ^role_id
      )
      |> Repo.all()

    # flat map the new permissions into permissions paths
    new_permissions_paths = new_permissions |> Iteraptor.to_flatmap()

    # change a permission if it's different
    new_role_permissions =
      Enum.reduce(current_role_permissions, [], fn %{
                                                 permission_path: permission_path,
                                                 value: old_value
                                               } = _current_role_permission,
                                               acc ->
        # check new value for permission_path
        # if value is not there, set it to false
        new_value = new_permissions_paths[permission_path] || false
        # if new value is different
        new_role_permission =
          if old_value != new_value do
            # set modified true
            %{role_id: role_id, permission_path: permission_path, modified: true}
            # if new value is same, set modified false
          else
            %{role_id: role_id, permission_path: permission_path, modified: false}
          end

        [new_role_permission | acc]
      end)

    # update role permissions for this role
    upsert_modified(new_role_permissions)

    # update role's permissions
    permissions = RolePermission.permissions_map_by_role_id(role_id)
    Role.set_permissions(role_id, permissions)

    # update role's priority_restrictions
    Role.set_priority_restrictions(role_id, priority_restrictions)

    # return success
    {:ok, :success}
  end

  defp upsert_modified([%{} | _] = roles_permissions) do
    Repo.insert_all(
      RolePermission,
      roles_permissions,
      # only replace modified value, :modified
      on_conflict: {:replace, [:modified]},
      # check conflicts on unique index keys
      conflict_target: [:role_id, :permission_path]
    )
  end

  @doc """
  Used to update the value of a `RolePermission` in the database, if it exists or create it, if it doesnt
  """
  @spec upsert_value(role_permissions :: [%{}]) :: {non_neg_integer(), nil | [term()]}
  # change the default values of roles permissions
  def upsert_value([]), do: {:error, "Role permission list is empty"}

  def upsert_value([%{} | _] = roles_permissions) do
    Repo.insert_all(
      RolePermission,
      roles_permissions,
      # only replace default value, :value
      on_conflict: {:replace, [:value]},
      # check conflicts on unique index keys
      conflict_target: [:role_id, :permission_path]
    )
  end

  @doc """
  Derives a single nested map of all permissions for a role
  """
  @spec permissions_map_by_role_id(role_id :: integer) :: map()
  def permissions_map_by_role_id(role_id) do
    from(rp in RolePermission,
      where: rp.role_id == ^role_id
    )
    |> Repo.all()
    # filter for true permissions
    |> Enum.filter(fn %{value: value, modified: modified} ->
      (value || modified) && !(value && modified)
    end)
    # convert results to map; keyed by permissions_path
    |> Enum.reduce(%{}, fn %{permission_path: permission_path}, acc ->
      Map.put(acc, permission_path, true)
    end)
    |> Iteraptor.from_flatmap()
  end

  @doc """
  Sets all roles permissions to value: false, modified: false

  For server-side role-loading use, only runs if roles permissions table is currently empty
  """
  @spec maybe_init!() :: [t()] | nil
  def maybe_init!() do
    if Repo.one(from rp in RolePermission, select: count(rp.value)) == 0,
      do:
        Enum.each(Role.all(), fn role ->
          Enum.each(Permission.all(), fn permission ->
            %RolePermission{}
            |> changeset(%{
              role_id: role.id,
              permission_path: permission.path,
              value: false,
              modified: false
            })
            |> Repo.insert!()
          end)
        end)
  end
end
