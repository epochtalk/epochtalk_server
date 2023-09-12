defmodule EpochtalkServer.Models.WatchBoard do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.WatchBoard
  alias EpochtalkServer.Models.User

  @moduledoc """
  `WatchBoard` model, for performing actions relating to `WatchBoard`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          board_id: non_neg_integer | nil
        }
  @derive {Jason.Encoder, only: [:user_id, :board_id]}
  @primary_key false
  @schema_prefix "users"
  schema "watch_boards" do
    field :user_id, :integer
    field :board_id, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for `WatchBoard` model
  """
  @spec create_changeset(
          watch_thread :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(watch_thread, attrs \\ %{}) do
    watch_thread
    |> cast(attrs, [:user_id, :board_id])
    |> validate_required([:user_id, :board_id])
    |> unique_constraint([:user_id, :board_id],
      name: :watch_boards_user_id_board_id_index
    )
    |> foreign_key_constraint(:board_id, name: :watch_boards_board_id_fkey)
    |> foreign_key_constraint(:user_id, name: :watch_boards_user_id_fkey)
  end

  ## === Database Functions ===

  @doc """
  Creates a new `WatchBoard` record in the database. Used to assign a `User` to watch
  a particular `Thread`. Won't recreate record if it exists, will just return existing values.
  """
  @spec create(user :: User.t(), board_id :: non_neg_integer) ::
          {:ok, watch_thread :: t()} | {:error, Ecto.Changeset.t()}
  def create(%User{} = user, board_id) do
    watch_thread_cs = create_changeset(%WatchBoard{user_id: user.id, board_id: board_id})

    case Repo.insert(watch_thread_cs) do
      {:ok, db_watch_thread} ->
        db_watch_thread

      {:error,
       %Ecto.Changeset{
         errors: [
           user_id:
             {_, [constraint: :unique, constraint_name: "watch_boards_user_id_board_id_index"]}
         ]
       }} ->
        {:ok, %WatchBoard{user_id: user.id, board_id: board_id}}

      {:error, cs} ->
        {:error, cs}
    end
  end

  @doc """
  Deletes a specific `WatchBoard` record from the database. Used to stop watching a `Thread`
  """
  @spec delete(user :: User.t(), board_id :: non_neg_integer) ::
          {non_neg_integer(), nil | [term()]}
  def delete(%User{} = user, board_id) do
    query =
      from w in WatchBoard,
        where: w.user_id == ^user.id and w.board_id == ^board_id

    Repo.delete_all(query)
  end

  @doc """
  Given a `User` model and `board_id` returns if the `User` is watching the specified `Thread`
  """
  @spec is_watching(user :: User.t(), board_id :: non_neg_integer) ::
          {:ok, watching :: boolean}
  def is_watching(nil, _board_id), do: {:ok, false}

  def is_watching(user, board_id) do
    query =
      from w in WatchBoard,
        where: w.user_id == ^user.id and w.board_id == ^board_id

    {:ok, Repo.all(query) |> length > 0}
  end
end
