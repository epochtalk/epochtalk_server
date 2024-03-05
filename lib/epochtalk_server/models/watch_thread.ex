defmodule EpochtalkServer.Models.WatchThread do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.WatchThread
  alias EpochtalkServer.Models.User

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
  Create changeset for `WatchThread` model
  """
  @spec create_changeset(
          watch_thread :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(watch_thread, attrs \\ %{}) do
    watch_thread
    |> cast(attrs, [:user_id, :thread_id])
    |> validate_required([:user_id, :thread_id])
    |> unique_constraint([:user_id, :thread_id],
      name: :watch_threads_user_id_thread_id_index
    )
    |> foreign_key_constraint(:thread_id, name: :watch_threads_thread_id_fkey)
    |> foreign_key_constraint(:user_id, name: :watch_threads_user_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `WatchThread` record in the database. Used to assign a `User` to watch
  a particular `Thread`. Won't recreate record if it exists, will just return existing values.
  """
  @spec create(user :: User.t(), thread_id :: non_neg_integer) ::
          {:ok, watch_thread :: t()} | {:error, Ecto.Changeset.t()}
  def create(%{} = user, thread_id) do
    watch_thread_cs = create_changeset(%WatchThread{user_id: user.id, thread_id: thread_id})

    case Repo.insert(watch_thread_cs) do
      {:ok, db_watch_thread} ->
        db_watch_thread

      {:error,
       %Ecto.Changeset{
         errors: [
           user_id:
             {_, [constraint: :unique, constraint_name: "watch_threads_user_id_thread_id_index"]}
         ]
       }} ->
        {:ok, %WatchThread{user_id: user.id, thread_id: thread_id}}

      {:error, cs} ->
        {:error, cs}
    end
  end

  @doc """
  Deletes a specific `WatchThread` record from the database. Used to stop watching a `Thread`
  """
  @spec delete(user :: User.t(), thread_id :: non_neg_integer) ::
          {non_neg_integer(), nil | [term()]}
  def delete(%User{} = user, thread_id) do
    query =
      from w in WatchThread,
        where: w.user_id == ^user.id and w.thread_id == ^thread_id

    Repo.delete_all(query)
  end

  @doc """
  Given a `User` model and `thread_id` returns if the `User` is watching the specified `Thread`
  """
  @spec user_is_watching(user :: User.t(), thread_id :: non_neg_integer) ::
          {:ok, watching :: boolean}
  def user_is_watching(nil, _thread_id), do: {:ok, false}

  def user_is_watching(user, thread_id) do
    query =
      from w in WatchThread,
        where: w.user_id == ^user.id and w.thread_id == ^thread_id

    {:ok, Repo.all(query) |> length > 0}
  end
end
