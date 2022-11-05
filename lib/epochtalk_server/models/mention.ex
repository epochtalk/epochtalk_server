defmodule EpochtalkServer.Models.Mention do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  # alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Mention
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Notification
  alias EpochtalkServerWeb.Helpers.Pagination

  @moduledoc """
  `Mention` model, for performing actions relating to forum categories
  """
  @type t :: %__MODULE__{
    id: non_neg_integer | nil,
    thread_id: non_neg_integer | nil,
    post_id: non_neg_integer | nil,
    mentioner_id: non_neg_integer | nil,
    mentionee_id: non_neg_integer | nil,
    created_at: NaiveDateTime.t() | nil
  }
  @schema_prefix "mentions"
  schema "mentions" do
    belongs_to :thread, Thread
    belongs_to :post, Post
    belongs_to :mentioner, User
    belongs_to :mentionee, User
    field :created_at, :naive_datetime
    field :viewed, :boolean, virtual: true
    field :notification_id, :integer, virtual: true
  end

  ## === Changesets Functions ===

  @doc """
  Create generic changeset for `Mention` model
  """
  @spec changeset(mention :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def changeset(mention, attrs) do
    mention
    |> cast(attrs, [:id, :thread_id, :post_id, :mentioner_id, :mentionee_id, :created_at])
    |> unique_constraint(:id, name: :mentions_pkey)
  end

  ## === Database Functions ===

  @doc """
  Page `Mention` models by for a specific `User`
  ### Valid Options
  | name        | type              | details                                             |
  | ----------- | ----------------- | --------------------------------------------------- |
  | `:per_page` | `non_neg_integer` | records per page to return                          |
  | `:extended` | `boolean`         | returns board and post details with mention if true |
  """
  @spec page_by_user_id(user_id :: non_neg_integer, page :: non_neg_integer, per_page: non_neg_integer, extended: boolean) :: {:ok, mentions :: [t()] | [], pagination_data :: map()}
  def page_by_user_id(user_id, page \\ 1, opts \\ []) do
    page_query(user_id, opts[:extended])
    |> Pagination.page_simple(page, per_page: opts[:per_page])
  end

  ## === Helper Functions ===

  # doesn't load board association
  defp page_query(user_id, nil = _extended), do: page_query(user_id, false)
  defp page_query(user_id, false = _extended) do
    from m in Mention,
      where: m.mentionee_id == ^user_id,
      left_join: notification in Notification,
      on: m.id == type(notification.data["mentionId"], :integer),
      left_join: mentioner in assoc(m, :mentioner),
      left_join: profile in assoc(mentioner, :profile),
      left_join: post in assoc(m, :post),
      left_join: thread in assoc(m, :thread),
      order_by: [desc: m.created_at, desc: m.id], # sort by id fixes duplicate timestamp issues
      select_merge: %{notification_id: notification.id, viewed: notification.viewed}, # set virtual field from notification join
      preload: [mentioner: {mentioner, profile: profile}, post: post, thread: thread]
  end
  defp page_query(user_id, true = _extended) do # loads board association on thread
    from m in Mention,
      where: m.mentionee_id == ^user_id,
      left_join: notification in Notification,
      on: m.id == type(notification.data["mentionId"], :integer),
      left_join: mentioner in assoc(m, :mentioner),
      left_join: profile in assoc(mentioner, :profile),
      left_join: post in assoc(m, :post),
      left_join: thread in assoc(m, :thread),
      left_join: board in assoc(thread, :board),
      order_by: [desc: m.created_at, desc: m.id], # sort by id fixes duplicate timestamp issues
      select_merge: %{notification_id: notification.id, viewed: notification.viewed}, # set virtual field from notification join
      preload: [mentioner: {mentioner, profile: profile}, post: post, thread: {thread, board: board}]
  end
end
