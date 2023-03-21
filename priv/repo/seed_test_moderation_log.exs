alias EpochtalkServer.Models.ModerationLog

logs = [
  %{
    mod:
      %{
        username: "one",
        id: 1,
        ip: "127.0.0.1"
      },
    action:
      %{
        api_url: "/api/boards/all",
        api_method: "post",
        type: "adminBoards.updateCategories",
        obj: %{}
      }
  },
  %{
    mod:
      %{
        username: "two",
        id: 2,
        ip: "127.0.0.1"
      },
    action:
      %{
        api_url: "/api/admin/moderators",
        api_method: "post",
        type: "adminModerators.add",
        obj:
          %{
            usernames: ["test"],
            board_id: 1
          }
      }
  },
  %{
    mod:
      %{
        username: "three",
        id: 3,
        ip: "127.0.0.1"
      },
    action:
      %{
        api_url: "/api/boards/all",
        api_method: "post",
        type: "adminBoards.updateCategories",
        obj: %{}
      }
  },
  %{
    mod:
      %{
        username: "four",
        id: 4,
        ip: "127.0.0.1"
      },
    action:
      %{
        api_url: "/api/boards/all",
        api_method: "post",
        type: "adminBoards.updateCategories",
        obj: %{}
      }
  },
  %{
    mod:
      %{
        username: "five",
        id: 5,
        ip: "127.0.0.1"
      },
    action:
      %{
        api_url: "/api/admin/moderators",
        api_method: "post",
        type: "adminModerators.add",
        obj:
          %{
            usernames: ["test"],
            board_id: 1
          }
      }
  }
]
try do
logs
|> Enum.with_index
|> Enum.filter(fn({log, index}) ->
    ModerationLog.create(log)
    |> case do
      {:ok, _} ->
        if index+1 == length(logs) do
          IO.puts("Successfully Seeded Moderation Log Entries")
        end
      {:error, error} ->
        IO.puts("Error Seeding Moderation Log Entry #{index + 1}")
        IO.inspect(error)
    end
  end)
rescue
  Postgrex.Error -> IO.puts("Error seeding Moderation Log. Moderation Log may already be seeded.")
end
