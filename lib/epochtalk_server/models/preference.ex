defmodule EpochtalkServer.Models.Preference do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Models.User
  @moduledoc """
  `Preference` model, for performing actions relating to a user's preferences
  """
  @type t :: %__MODULE__{
    user_id: non_neg_integer,
    posts_per_page: non_neg_integer,
    threads_per_page: non_neg_integer,
    collapsed_categories: %{},
    ignored_boards: %{},
    timezone_offset: String.t(),
    notify_replied_threads: boolean,
    ignore_newbies: boolean,
    patroller_view: boolean,
    email_mentions: boolean,
    email_messages: boolean
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
  @spec changeset(
    preference :: t(),
    attrs :: %{} | nil
  ) :: t()
  def changeset(preference, attrs \\ %{}) do
    preference
    |> cast(attrs, [:user_id, :posts_per_page, :threads_per_page,
      :collapsed_categories, :ignored_boards, :timezone_offset,
      :notify_replied_threads, :ignore_newbies, :patroller_view,
      :email_mentions, :email_messages])
    |> validate_required([:user_id])
  end
end
