defmodule EpochtalkServer.Models.UserIp do
  use Ecto.Schema
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserIp

  @moduledoc """
  `UserIp` model, for performing actions relating to tracking a `User` IP addresses
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          user_ip: String.t() | nil,
          created_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :user_ip,
             :created_at
           ]}
  @schema_prefix "users"
  @primary_key false
  schema "ips" do
    belongs_to :user, User
    field :user_ip, :string
    field :created_at, :naive_datetime
  end

  ## === Database Functions ===

  @doc """
  Inserts `UserIp` record into the database if it doesn't already exist
  """
  @spec track(user_id :: non_neg_integer, user_ip :: String.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def track(user_id, user_ip) do
    Repo.insert(
      %UserIp{
        user_id: user_id,
        user_ip: user_ip,
        created_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      },
      on_conflict: :nothing,
      conflict_target: [:user_id, :user_ip]
    )
  end
end
