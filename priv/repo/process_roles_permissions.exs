json_file = "#{__DIR__}/seeds/roles_permissions.json"

File.rm("#{__DIR__}/seeds/permissions.json")
output_file = File.open!("#{__DIR__}/seeds/permissions.json", [:write])

output_list = json_file
|> File.read!()
|> Jason.decode! # convert from json
|> Enum.reduce([], fn { _role, permissions }, all_permissions ->
  all_permissions ++ (permissions
  |> Iteraptor.to_flatmap
  |> Enum.reduce([], fn { permission, _value }, role_permissions ->
    role_permissions ++ [permission]
  end))
end)
|> Enum.uniq
|> Enum.sort

output_json = output_list
|> Jason.encode!
|> Jason.Formatter.pretty_print

output_file
|> IO.write(output_json)
