defmodule EpochtalkServer.Models.Ban do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Role
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Models.Ban
  @moduledoc """
  `Ban` model, for performing actions relating to banning
  """

  # max naivedatetime, used for permanent bans
  @max_date ~N[9999-12-31 00:00:00.000]

  @type t :: %__MODULE__{
    id: non_neg_integer | nil,
    user_id: non_neg_integer | nil,
    expiration: NaiveDateTime.t() | nil,
    created_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }
  @schema_prefix "users"
  @derive {Jason.Encoder, only: [:user_id, :expiration, :created_at, :updated_at]}
  schema "bans" do
    belongs_to :user, User, primary_key: true
    field :expiration, :naive_datetime
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Ban` model
  """
  @spec changeset(ban :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(ban, attrs \\ %{}) do
    ban
    |> cast(attrs, [:id, :user_id, :expiration, :created_at, :updated_at])
    |> validate_required([:user_id])
  end

  @doc """
  Create ban changeset for `Ban` model, handles upsert of ban for banning
  """
  @spec ban_changeset(ban :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
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

  @doc """
  Create unban changeset for `Ban` model, handles update of ban for unbanning
  """
  @spec unban_changeset(ban :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def unban_changeset(ban, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:expiration, now)
    |> Map.put(:updated_at, now)
    ban
    |> cast(attrs, [:user_id, :expiration, :updated_at])
    |> validate_required([:user_id])
  end

  ## === Database Functions ===

  @doc """
  Fetches `Ban` associated with a specific `User`
  """
  @spec by_user_id(
    user_id :: integer
  ) :: {:ok, ban_changeset :: Ecto.Changeset.t()} | {:error, ban_changeset :: Ecto.Changeset.t()}
  def by_user_id(user_id) when is_integer(user_id), do: Repo.get_by(Ban, user_id: user_id)

  @doc """
  Used to ban a `User` by `user_id` until supplied `expiration`. Passing `nil` for `expiration` will
  permanently ban the `User`
  """
  @spec ban_by_user_id(
    user_id :: integer,
    expiration :: Calendar.naive_datetime() | nil
  ) :: {:ok, ban_changeset :: Ecto.Changeset.t()} | {:error, :ban_error}
  def ban_by_user_id(user_id, expiration) do
    Repo.transaction(fn ->
      RoleUser.set_user_role(Role.get_banned_role_id, user_id)
      case Repo.get_by(Ban, user_id: user_id) do # look for existing ban
        nil -> ban_changeset(%Ban{}, %{user_id: user_id, expiration: expiration}) # create new
        ban -> ban_changeset(ban, %{user_id: user_id, expiration: expiration}) # update existing
      end
      |> Repo.insert_or_update!
    end)
    |> case do
      {:ok, ban_changeset} -> {:ok, ban_changeset}
      {:error, err} -> # print error, return error atom
        # TODO(akinsey): handle in logger (telemetry possibly)
        Logger.error(inspect(err))
        {:error, :ban_error}
    end
  end

  @doc """
  Used to ban a `User` permanently. Updates supplied `User` model to reflect ban and returns.
  """
  @spec ban(
    user :: User.t()
  ) :: {:ok, user_changeset :: Ecto.Changeset.t()} | {:error, :ban_error}
  def ban(%User{} = user), do: ban(user, nil)

  @doc """
  Used to ban a `User` until supplied `expiration`. Passing `nil` for `expiration` will
  permanently ban the `User`. Updates supplied `User` model to reflect ban and returns.
  """
  @spec ban(
    user :: User.t(),
    expiration :: Calendar.naive_datetime() | nil
  ) :: {:ok, user_changeset :: Ecto.Changeset.t()} | {:error, :ban_error}
  def ban(%User{id: id} = user, expiration) do
    case ban_by_user_id(id, expiration) do
      {:ok, _ban_info} -> # successful ban, update roles/ban info on user
        user = user
        |> Repo.preload([:ban_info, :roles], force: true)
        |> Role.handle_banned_user_role() # only return banned role inside roles once user is banned
        {:ok, user}
      {:error, _} -> {:error, :ban_error}
    end
  end

  @doc """
  Used to unban a `User` by `user_id`. Will return `{:ok, nil}` if user was never banned.
  """
  @spec unban_by_user_id(
    user_id :: integer
  ) :: {:ok, ban_changeset :: Ecto.Changeset.t()} | {:ok, nil} | {:error, :unban_error}
  def unban_by_user_id(user_id) when is_integer(user_id) do
    Repo.transaction(fn ->
      RoleUser.delete_user_role(Role.get_banned_role_id, user_id) # delete ban role from user
      User.clear_malicious_score_by_id(user_id) # clear user malicious score
      case Repo.get_by(Ban, user_id: user_id) do
        nil -> {:ok, nil}
        cs -> Repo.update!(unban_changeset(cs, %{user_id: user_id}))
      end # unban the user
    end)
    |> case do
      {:ok, ban_changeset} -> {:ok, ban_changeset}
      {:error, err} -> # print error, return error atom
        Logger.error(inspect(err))
        {:error, :unban_error}
    end
  end

  @doc """
  Used to unban a `User`. Updates supplied `User` model to reflect unbanning and returns.
  """
  @spec unban(user :: User.t()) :: {:ok, user :: User.t()} | {:error, :unban_error}
  def unban(%User{ban_info: %Ban{expiration: expiration}, id: user_id} = user) do
    if NaiveDateTime.compare(expiration, NaiveDateTime.utc_now) == :lt do
      case unban_by_user_id(user_id) do
        {:ok, nil} -> {:ok, user} # user wasn't banned, return user
        {:ok, _result} -> # successful unban, update user roles and ban_info
          user = user
          |> Repo.preload([:roles], force: true)
          |> Role.handle_empty_user_roles() # if user's roles empty, default to user role
          |> Map.put(:malicious_score, nil) # clear malicious score
          |> Map.put(:ban_info, nil) # clear ban info so session gets updated
          {:ok, user}
        {:error, _} -> {:error, :unban_error}
      end
    else
     {:ok, user}
    end
  end
  # unban with no ban_expiration, just output user do nothing
  def unban(%User{id: _user_id} = user), do: {:ok, user}
end
