defmodule EpochtalkServer.Seed.User do
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Repo

  def process_args([username, email, password, "admin" = admin]) do
    case process_args([username, email, password]) do
      {:ok, user} ->
        %RoleUser{}
        |>RoleUser.changeset(%{user_id: user.id, role_id: 1})
        |> Repo.insert
        |> case do
          {:ok, role_user} ->
            IO.puts("Successfully seeded admin role")
            IO.inspect(role_user)
        end
    end
  end
  def process_args([username, email, password]) do
    attrs = %{username: username, email: email, password: password}
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert
    |> case do
      {:ok, user} ->
        IO.puts("Successfully seeded user")
        IO.inspect(user)
        {:ok, user}
      {:error, changeset} ->
        IO.puts("Error seeding user")
        IO.inspect(changeset)
        {:error, changeset}
      _ ->
        IO.puts("Unknown issue seeding user")
        IO.inspect(attrs)
    end
  end
end
