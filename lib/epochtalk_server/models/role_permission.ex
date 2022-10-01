defmodule EpochtalkServer.Models.RolePermission do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.RolePermission
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.Permission

  @primary_key false
  schema "roles_permissions" do
    belongs_to :role, Role, foreign_key: :role_id, type: :integer
    belongs_to :permission, Permission, foreign_key: :permission_path, references: :path, type: :string
    # value XOR modified -> final value
    # (value || modified) && !(value && modified)
    # elixir is not as awesome as erlang because no XOR on booleans
    field :value, :boolean
    field :modified, :boolean
  end

  ## === Changesets Functions ===

  def changeset(role_permission, attrs \\ %{}) do
    role_permission
    |> cast(attrs, [:role_id, :permission_path, :value, :modified])
    |> validate_required([:role_id, :permission_path, :value, :modified])
  end

  ## === Database Functions ===

  def insert([]), do: {:error, "Role permission list is empty"}
  def insert(%RolePermission{} = role_permission), do: Repo.insert(role_permission)
  def insert([%{}|_] = roles_permissions), do: Repo.insert_all(RolePermission, roles_permissions)

  ## for admin api use, modifying permissions for a role
  # no permissions to modify
  # def modify_by_role(role, []), do: {:error, "No permissions to modify"}
  # def modify_by_role(role, [%Permission{}|_] = permissions) do
  #   # change role permission for each permission
  #     # check default value
  #     # check new value
  #     # if new value is different, set modified true
  #     # if new value is same, set modified false
  #   # update roles table
  # end
  # def modify_by_role(role, %RolePermission{} = permission) do
  #   # change role permission
  #     # check default value
  #     # check new value
  #     # if new value is different, set modified true
  #     # if new value is same, set modified false
  #   # update roles table
  # end

  # change the default values of roles permissions
  def upsert_value([]), do: {:error, "Role permission list is empty"}
  def upsert_value([%{}|_] = roles_permissions) do
    Repo.insert_all(
      RolePermission,
      roles_permissions,
      on_conflict: {:replace, [:value]}, # only replace default value, :value
      conflict_target: [:role_id, :permission_path] # check conflicts on unique index keys
    )
  end

  # derives a single nested map of all permissions for a role
  def permissions_map_by_role_id(role_id) do
    from(rp in RolePermission,
      where: rp.role_id == ^role_id)
    |> Repo.all
    # filter for true permissions
    |> Enum.filter(fn %{value: value, modified: modified} -> (value || modified) && !(value && modified) end)
    # convert results to map; keyed by permissions_path
    |> Enum.reduce(%{}, fn %{permission_path: permission_path, value: value}, acc -> Map.put(acc, permission_path, value) end)
    |> Iteraptor.from_flatmap
  end

  # for server-side role-loading use, only runs if roles permissions table is currently empty
  # sets all roles permissions to value: false, modified: false
  def maybe_init! do
    if Repo.one(from rp in RolePermission, select: count(rp.value)) == 0, do: Enum.each(Role.all, fn role ->
      Enum.each(Permission.all, fn permission ->
        %RolePermission{}
        |> changeset(%{ role_id: role.id, permission_path: permission.path, value: false, modified: false })
        |> Repo.insert!
      end)
    end)
  end
end
