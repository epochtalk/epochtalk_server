json_file = "#{__DIR__}/seeds/priority_restrictions.json"

alias EpochtalkServer.Models.Role

json_file
|> File.read!()
|> Jason.decode!
# for each priority_restriction, set in db
|> Enum.each(&(Role.set_priority_restrictions_by_lookup(&1)))
|> case do
  :ok -> IO.puts("Successfully Seeded Priority Restrictions")
  _ -> IO.puts("Error Seeding Priority Restrictions")
end
