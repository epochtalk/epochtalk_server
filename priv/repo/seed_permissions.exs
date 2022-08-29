json_file = "#{__DIR__}/seeds/permissions.json"

alias Epoch.Permission
alias Epoch.Repo
alias Ecto.Multi

create_permission_changeset = fn(data) ->
  %{path: data}
end

permissions_changesets = json_file
|> File.read!()
|> Jason.decode! # []
|> Enum.map(create_permission_changeset)

Multi.new()
|> Multi.delete_all(:delete_all, Permission)
|> Multi.insert_all(:insert_all, Permission, permissions_changesets)
|> Repo.transaction()
|> case do
  {:ok, _} -> IO.puts("Successfully Seeded Permissions")
  {:error, _} -> IO.puts("Error Seeding Permissions")
end
