defmodule EpochtalkServer.Models.UserThreadView do
  use Ecto.Schema
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.UserThreadView

  @moduledoc """
  `UserThreadView` model, for performing actions relating to `User` `UserThreadView`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil,
          time: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :thread_id,
             :time
           ]}
  @schema_prefix "users"
  @primary_key false
  schema "thread_views" do
    belongs_to :user, User
    belongs_to :thread, Thread
    field :time, :naive_datetime
  end

  ## === Database Functions ===

  @doc """
  Used to upsert a `UserThreadView`. Used to update `time` field everytime `User` views
  a specific `Thread`
  """
  @spec upsert(user_id :: non_neg_integer, thread_id :: non_neg_integer) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def upsert(user_id, thread_id) when is_integer(user_id) and is_integer(thread_id) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    Repo.insert(
      %UserThreadView{user_id: user_id, thread_id: thread_id, time: now},
      on_conflict: [
        set: [time: now]
      ],
      conflict_target: [:user_id, :thread_id]
    )
  end
end
