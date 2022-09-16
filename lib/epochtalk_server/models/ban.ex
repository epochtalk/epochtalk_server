defmodule EpochtalkServer.Models.Ban do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Models.Ban

  @schema_prefix "users"
  schema "bans" do
    belongs_to :user, User, primary_key: true
    field :expiration, :naive_datetime
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  def changeset(ban, attrs \\ %{}) do
    ban
    |> cast(attrs, [:id, :user_id, :expiration, :created_at, :updated_at])
    |> validate_required([:user_id])
  end

  def unban_changeset(ban, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:expiration, now)
    |> Map.put(:updated_at, now)
    ban
    |> cast(attrs, [:user_id, :expiration, :updated_at])
    |> validate_required([:user_id])
  end

  def insert(%Ban{} = ban), do: Repo.insert(ban)
  def unban(user_id) when is_integer(user_id) do
    Repo.transaction(fn ->
      db_ban = case Repo.get_by(Ban, user_id: user_id) do
        nil -> %{ user_id: user_id }
        cs -> Repo.update!(unban_changeset(cs, %{ user_id: user_id }))
      end # unban the user
      User.clear_malicious_score(user_id) # clear user malicious score
      RoleUser.delete(Role.get_banned_role_id, user_id) # delete ban role from user
      Map.put(db_ban, :roles, Role.by_user_id(user_id)) # append user roles
    end)
  end
end
