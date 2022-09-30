defmodule EpochtalkServer.Models.Ban do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Models.Ban

  # max naivedatetime, used for permanent bans
  @max_date ~N[9999-12-31 00:00:00.000]

  @schema_prefix "users"
  @derive {Jason.Encoder, only: [:user_id, :expiration, :created_at, :updated_at]}
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

  # handles upsert of ban for banning
  def ban_changeset(ban, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:created_at, (if created_at = Map.get(ban, :created_at), do: created_at, else: now))
    |> Map.put(:updated_at, now)
    |> Map.put(:expiration, (if exp = Map.get(attrs, :expiration), do: exp, else: @max_date))
    ban
    |> cast(attrs, [:id, :user_id, :expiration, :updated_at, :created_at])
    |> validate_required([:user_id])
  end

  # handles update of ban for unbanning
  def unban_changeset(ban, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:expiration, now)
    |> Map.put(:updated_at, now)
    ban
    |> cast(attrs, [:user_id, :expiration, :updated_at])
    |> validate_required([:user_id])
  end
  def by_user_id(user_id) when is_integer(user_id), do: Repo.get_by(Ban, user_id: user_id)

  def ban(%User{} = user), do: ban(user, nil)
  def ban(%User{ id: id} = user, expiration) do
    case ban_by_user_id(id, expiration) do
      {:ok, _ban_info} -> # successful ban, update roles/ban info on user
        user = user |> Repo.preload([:ban_info, roles: [:role]], force: true)
        {:ok, user}
      {:error, err} -> # print error, return human readable message
        IO.inspect err
        {:error, :ban_error}
    end
  end
  defp ban_by_user_id(user_id, expiration) do
    Repo.transaction(fn ->
      RoleUser.set_user_role(Role.get_banned_role_id, user_id)
      case Repo.get_by(Ban, user_id: user_id) do
        nil -> ban_changeset(%Ban{}, %{user_id: user_id, expiration: expiration})
        ban -> ban_changeset(ban, %{user_id: user_id, expiration: expiration})
      end
      |> Repo.insert_or_update!
    end)
  end

  defp unban_by_user_id(user_id) when is_integer(user_id) do
    Repo.transaction(fn ->
      RoleUser.delete_user_role(Role.get_banned_role_id, user_id) # delete ban role from user
      User.clear_malicious_score_by_id(user_id) # clear user malicious score
      case Repo.get_by(Ban, user_id: user_id) do
        nil -> {:ok, nil}
        cs -> Repo.update!(unban_changeset(cs, %{ user_id: user_id }))
      end # unban the user
    end)
  end

  # unban if ban is expired, return user's roles
  def unban_fixed(%User{ban_info: %Ban{expiration: expiration}, id: user_id} = user) do
    if NaiveDateTime.compare(expiration, NaiveDateTime.utc_now) == :lt do
      case unban_by_user_id(user_id) do
        {:ok, _result} -> #successful unban, update user roles and ban_info
          user = user |> Repo.preload([:ban_info, roles: [:role]], force: true)
          {:ok, user}
        {:error, err} -> # print error, return human readable message
          IO.inspect err
          {:error, :unban_error}
      end
    else
     {:ok, user}
    end
  end
  # unban with not ban_expiration, just return user do nothing
  def unban_fixed(%User{id: _user_id} = user), do: {:ok, user}

  def unban(%{ban_expiration: expiration, id: user_id} = user) do
    if NaiveDateTime.compare(expiration, NaiveDateTime.utc_now) == :lt do
      case unban_by_user_id(user_id) do
        {:ok, _result} -> #successful unban, append updated user roles
          user = user
          |> Map.put(:roles, Role.by_user_id(user_id))
          |> Map.delete(:ban_expiration)
          {:ok, user}
        {:error, err} -> # print error, return human readable message
          IO.inspect err
          {:error, :unban_error}
      end
    else
     {:ok, user}
    end
  end
  # unban with not ban_expiration, just return user do nothing
  def unban(%{id: _user_id} = user), do: {:ok, user}
end
