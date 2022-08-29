json_file = "#{__DIR__}/../../priority_restrictions.json"

alias Epoch.Role

json_file
|> File.read!()
|> Jason.decode!
# for each priority_restriction, set in db
|> Enum.each(&(Role.set_priority_restrictions_by_lookup(&1)))
|> case do
  :ok -> IO.puts("Successfully Seeded Priority Restrictions")
  _ -> IO.puts("Error Seeding Priority Restrictions")
end
