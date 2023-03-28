defmodule EpochtalkServer.Models.Preference do
  use Ecto.Schema
  import Ecto.Changeset
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
  Creates a generic changeset for `Preference` model
  """
  @spec changeset(preference :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(preference, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("user_id", Map.get(attrs, "id"))
      |> Map.delete("id")

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

  ## === Database Functions ===

  @doc """
  Creates `Preference` record for a specific `User`
  """
  @spec create(attrs :: map) :: {:ok, preference :: t()} | {:error, Ecto.Changeset.t()}
  def create(attrs), do: changeset(%Preference{}, attrs) |> Repo.insert(returning: true)

  @doc """
  Updates `Preference` record for a specific `User`
  """
  @spec update(attrs :: map) :: {:ok, preference :: t()} | {:error, :preference_does_not_exist | Ecto.Changeset.t()}
  def update(attrs) do
    db_preference = Preference
    |> Repo.get_by(user_id: Map.get(attrs, "id"))

    if is_nil(db_preference),
      do: {:error, :preference_does_not_exist},
      else: db_preference |> changeset(attrs) |> Repo.update()
  end

  @doc """
  Fetches `Preference` associated with a specific `User`
  """
  @spec by_user_id(user_id :: integer) ::
          {:ok, preference_changeset :: Ecto.Changeset.t()}
          | {:error, preference_changeset :: Ecto.Changeset.t()}
  def by_user_id(user_id) when is_integer(user_id), do: Repo.get_by(Preference, user_id: user_id)
end
