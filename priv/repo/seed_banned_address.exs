alias EpochtalkServer.Models.BannedAddress
alias EpochtalkServer.Repo

banned_address =
  %{
    # either use hostname OR ip; not both
    # ip: "127.0.0.1",
    hostname: "localhost",
    weight: 1.0,
    created_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    imported_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }


try do
  Repo.insert(BannedAddress.upsert_changeset(%BannedAddress{}, banned_address), returning: true)
  |> case do
      {:ok, _} -> IO.puts("Successfully Seeded Banned Address")
      {:error, error} ->
        IO.puts("Error Seeding Banned Address")
        IO.inspect(error)
    end
rescue
  Postgrex.Error -> IO.puts("Error seeding Banned Address. Banned Address may already be seeded.")
end

