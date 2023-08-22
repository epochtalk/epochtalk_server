defmodule EpochtalkServer.Models.Preference do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Preference
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Preference` model, for performing actions relating to a user's preferences
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          posts_per_page: non_neg_integer | nil,
          threads_per_page: non_neg_integer | nil,
          collapsed_categories: %{} | nil,
          ignored_boards: %{} | nil,
          timezone_offset: String.t() | nil,
          notify_replied_threads: boolean | nil,
          ignore_newbies: boolean | nil,
          patroller_view: boolean | nil,
          email_mentions: boolean | nil,
          email_messages: boolean | nil
        }
  @primary_key false
  @schema_prefix "users"
  schema "preferences" do
    belongs_to :user, User
    field :posts_per_page, :integer
    field :threads_per_page, :integer
    field :collapsed_categories, :map
    field :ignored_boards, :map
    field :timezone_offset, :string
    field :notify_replied_threads, :boolean
    field :ignore_newbies, :boolean
    field :patroller_view, :boolean
    field :email_mentions, :boolean
    field :email_messages, :boolean
  end

  ## === Changesets Functions ===

  @doc """
  Creates a create changeset for `Preference` model
  """
  @spec create_changeset(preference :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(preference, attrs \\ %{}) do
    preference
    |> cast(attrs, [
      :user_id,
      :posts_per_page,
      :threads_per_page,
      :collapsed_categories,
      :ignored_boards,
      :timezone_offset,
      :notify_replied_threads,
      :ignore_newbies,
      :patroller_view,
      :email_mentions,
      :email_messages
    ])
    |> validate_required([:user_id])
  end

  @doc """
  Creates an update changeset for `Preference` model
  """
  @spec update_changeset(preference :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def update_changeset(preference, attrs \\ %{}) do
    preference
    |> cast(attrs, [
      :user_id,
      :posts_per_page,
      :threads_per_page,
      :collapsed_categories,
      :ignored_boards,
      :timezone_offset,
      :notify_replied_threads,
      :ignore_newbies,
      :patroller_view,
      :email_mentions,
      :email_messages
    ])
    |> validate_required([
      :user_id,
      :posts_per_page,
      :threads_per_page,
      :collapsed_categories,
      :ignored_boards,
      :timezone_offset,
      :notify_replied_threads,
      :ignore_newbies,
      :patroller_view,
      :email_mentions,
      :email_messages
    ])
  end

  ## === Database Functions ===

  @doc """
  Creates `Preference` record for a specific `User`
  """
  @spec create(user_id :: non_neg_integer, attrs :: map | nil) ::
          {:ok, preference :: t()} | {:error, Ecto.Changeset.t()}
  def create(user_id, attrs \\ %{}),
    do: create_changeset(%Preference{user_id: user_id}, attrs) |> Repo.insert(returning: true)

  @doc """
  Upserts `Preference` record for a specific `User`
  """
  @spec upsert(user_id :: non_neg_integer, attrs :: map | nil) ::
          {:ok, preference :: t()} | {:error, :preference_does_not_exist | Ecto.Changeset.t()}
  def upsert(user_id, attrs \\ %{}) do
    # get existing preference row for user
    if db_preference = Repo.get_by(Preference, user_id: user_id) do
      cs_data = update_changeset(db_preference, attrs)

      updated_cs = Map.merge(cs_data.data, cs_data.changes)

      from(p in Preference, where: p.user_id == ^user_id)
      |> Repo.update_all(
        set: [
          posts_per_page: Map.get(updated_cs, :posts_per_page),
          threads_per_page: Map.get(updated_cs, :threads_per_page),
          collapsed_categories: Map.get(updated_cs, :collapsed_categories),
          ignored_boards: Map.get(updated_cs, :ignored_boards),
          timezone_offset: Map.get(updated_cs, :timezone_offset),
          notify_replied_threads: Map.get(updated_cs, :notify_replied_threads),
          ignore_newbies: Map.get(updated_cs, :ignore_newbies),
          patroller_view: Map.get(updated_cs, :patroller_view),
          email_mentions: Map.get(updated_cs, :email_mentions),
          email_messages: Map.get(updated_cs, :email_messages)
        ]
      )

      {:ok, updated_cs}
    else
      create(user_id, attrs)
    end
  end

  @doc """
  Fetches `Preference` associated with a specific `User`
  """
  @spec by_user_id(user_id :: integer) ::
          {:ok, preference_changeset :: Ecto.Changeset.t()}
          | {:error, preference_changeset :: Ecto.Changeset.t()}
  def by_user_id(user_id) when is_integer(user_id), do: Repo.get_by(Preference, user_id: user_id)

  @doc """
  Returns boolean indicating if specific `User` has `notify_replied_threads` `Preference` set
  """
  @spec notify_replied_threads?(user_id :: integer) :: boolean
  def notify_replied_threads?(user_id) when is_integer(user_id) do
    query =
      from p in Preference,
        where: p.user_id == ^user_id,
        select: p.notify_replied_threads

    case Repo.one(query) do
      true -> true
      _ -> false
    end
  end

  @doc """
  Enables Email Notifications (`notify_replied_threads`) for `ThreadSubscriptions`
  """
  @spec toggle_notify_replied_threads(user_id :: integer, enabled :: boolean) ::
          boolean | {:error, Ecto.Changeset.t()}
  def toggle_notify_replied_threads(user_id, enabled)
      when is_integer(user_id) and is_boolean(enabled) do
    case Repo.insert(
           %Preference{user_id: user_id, notify_replied_threads: enabled},
           on_conflict: [set: [notify_replied_threads: enabled]],
           conflict_target: [:user_id]
         ) do
      {:ok, _} -> enabled
      {:error, err} -> {:error, err}
    end
  end
end
