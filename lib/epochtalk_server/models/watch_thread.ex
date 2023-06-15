defmodule EpochtalkServer.Models.WatchThread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.WatchThread

  @moduledoc """
  `WatchThread` model, for performing actions relating to `WatchThread`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:user_id, :thread_id]}
  @primary_key false
  @schema_prefix "users"
  schema "watch_threads" do
    field :user_id, :integer
    field :thread_id, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `WatchThread` model
  """
  @spec changeset(
          watch_thread :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(watch_thread, attrs \\ %{}) do
    watch_thread
    |> cast(attrs, [:user_id, :thread_id])
    |> validate_required([:user_id, :thread_id])
  end

  ## === Database Functions ===

  @doc """
  Given a `User` model and `thread_id` returns if the `User` is watching the specified `Thread`
  """
  @spec is_watching(user :: EpochtalkServer.Models.User.t(), thread_id :: non_neg_integer) ::
          {:ok, watching :: boolean}
  def is_watching(nil, _thread_id), do: {:ok, false}

  def is_watching(user, thread_id) do
    query =
      from w in WatchThread,
        where: w.user_id == ^user.id and w.thread_id == ^thread_id

    {:ok, Repo.all(query) |> length > 0}
  end
end
