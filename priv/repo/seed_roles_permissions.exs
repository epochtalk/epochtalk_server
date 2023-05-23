json_file = "#{__DIR__}/seeds/roles_permissions.json"

alias EpochtalkServer.Models.RolePermission
alias EpochtalkServer.Models.Role
alias EpochtalkServer.Repo
alias EpochtalkServer.Cache.Role, as: RoleCache

# helper function to create role permissions changeset before upsert
create_role_permission_changeset = fn({role_lookup, permissions}) ->
  role = Role.by_lookup_repo(role_lookup)
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
  Role.all_repo
  |> Enum.map(fn role -> {role, RolePermission.permissions_map_by_role_id(role.id)} end)
  |> Enum.each(fn {role, permissions} -> Role.set_permissions(role.id, permissions) end)
end)
|> case do
  {:ok, _} ->
    # reload role cache after successful role permissions transaction
    RoleCache.reload()
    IO.puts("Successfully Seeded Role Permissions")
  {:error, _} -> IO.puts("Error Seeding Role Permissions")
end
