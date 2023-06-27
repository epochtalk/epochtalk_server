alias EpochtalkServer.Models.BannedAddress
alias EpochtalkServer.Repo

banned_ip = %{
  # either use hostname OR ip; not both
  ip: "127.0.0.1",
  weight: 1.0,
  created_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
  imported_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
}

banned_hostname = %{
  # either use hostname OR ip; not both
  hostname: "localhost",
  weight: 1.0,
  created_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
  imported_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
}

try do
  Repo.insert(BannedAddress.upsert_changeset(%BannedAddress{}, banned_ip), returning: true)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully Seeded Banned Address (IP)")

    {:error, error} ->
      IO.puts("Error Seeding Banned Address (IP)")
      IO.inspect(error)
  end

  Repo.insert(BannedAddress.upsert_changeset(%BannedAddress{}, banned_hostname), returning: true)
  |> case do
    {:ok, _} ->
      IO.puts("Successfully Seeded Banned Address (hostname)")

    {:error, error} ->
      IO.puts("Error Seeding Banned Address (hostname)")
      IO.inspect(error)
  end
rescue
  Postgrex.Error ->
    IO.puts("Error seeding Banned Address. Banned Address may already be seeded.")
    raise Postgrex.Error
end
