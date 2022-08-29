json_file = "#{__DIR__}/../../roles_permissions.json"

alias Epoch.RolePermission
alias Epoch.Role
alias Epoch.Repo

# helper function to create role permissions changeset beore upsert
create_role_permission_changeset = fn({role_lookup, permissions}) ->
  role = Role.by_lookup(role_lookup)
  permissions
  |> Iteraptor.to_flatmap
  |> Enum.map(fn {permission_path, value} ->
    %{ role_id: role.id, permission_path: permission_path, value: value, modified: false}
  end)
end

# maybe init RP, set RP values from file, update each role's permissions
Repo.transaction(fn ->
  # init if necessary
  RolePermission.maybe_init!()

  # read actual permission values from file and update for each role
  json_file
  |> File.read!()
  |> Jason.decode! # convert from json
  |> Enum.map(create_role_permission_changeset)
  |> Enum.each(&RolePermission.upsert_value(&1))

  # generate permissions map for each role then update role
  Role.all
  |> Enum.map(fn role -> {role, RolePermission.permissions_map_by_role_id(role.id)} end)
  |> Enum.each(fn {role, permissions} -> Role.set_permissions(role.id, permissions) end)
end)
|> case do
  {:ok, _} -> IO.puts("Successfully Seeded Role Permissions")
  {:error, _} -> IO.puts("Error Seeding Role Permissions")
end
