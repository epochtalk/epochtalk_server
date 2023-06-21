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

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `UserThreadView` model
  """
  @spec changeset(
          user_thread_view :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(user_thread_view, attrs \\ %{}) do
    user_thread_view
    |> cast(attrs, [:user_id, :thread_id, :time])
    |> validate_required([:user_id, :thread_id, :time])
  end
end
