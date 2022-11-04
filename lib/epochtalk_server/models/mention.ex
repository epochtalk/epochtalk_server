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
  ### Valid Attrs
  | name       | type              | details                                             |
  | ---------- | ----------------- | --------------------------------------------------- |
  | `page`     | `non_neg_integer` | the page to return                                  |
  | `limit`    | `non_neg_integer` | records per page to return                          |
  | `extended` | `boolean`         | returns board and post details with mention if true |
  """
  @spec page_by_user_id(user_id :: integer, attrs :: map() | nil) :: {:ok, mentions :: [t()] | [], pagination_data :: map()}
  def page_by_user_id(user_id, attrs \\ %{}) do
    page_query(user_id, extended: attrs["extended"] == "true")
    |> Pagination.page_simple(attrs["page"], per_page: attrs["limit"])
  end

  ## === Helper Functions ===

  defp page_query(user_id, extended: false) do # doesn't load board association
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
  defp page_query(user_id, extended: true) do # loads board association on thread
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


  # def page_by_user_id(user_id, attrs) do
  #   limit = String.to_integer(attrs["limit"] || "25")
  #   page = String.to_integer(attrs["page"] || "1")
  #   extended = String.to_existing_atom(attrs["extended"] || "false")
  #   options = [
  #     limit: limit + 1, # query one extra, to see if there's a next page
  #     offset: (page * limit) - limit,
  #     extended: extended
  #   ]
  #   query = page_query(user_id, options)
  #   mentions = Repo.all(query, prefix: "public")
  #   next = length(mentions) > limit # check if theres a next page
  #   mentions = if next, do: mentions |> Enum.reverse() |> tl() |> Enum.reverse(), else: mentions
  #   {:ok, mentions, %{
  #     next: next,
  #     prev: page > 1,
  #     page: page,
  #     limit: limit,
  #     extended: extended
  #   }}
  # end

  # def page_by_user_id(user_id, options \\ []) do
  #   page = Keyword.get(options, :page, @defaults.page)
  #   limit = Keyword.get(options, :limit, @defaults.limit) + 1
  #   offset = (page * limit) - limit
  #   extended = Keyword.get(options, :extended, @defaults.extended)
  #   query = Mention
  #     |> where([m], m.mentionee_id == ^user_id)
  #     |> join(:left, [m], mentioner in assoc(m, :mentioner))
  #     |> join(:left, [m], post in assoc(m, :post))
  #     |> join(:left, [m], thread in assoc(m, :thread))
  #     |> order_by(desc: :created_at)
  #     |> limit(^limit)
  #     |> offset(^offset)
  #   query = if extended do
  #       join(query, :left, [thread], board in assoc(thread, :board))
  #       |> preload([m, mentioner, post, thread, board], [mentioner: mentioner, post: post, thread: {thread, board: board}])
  #     else
  #       preload(query, [m, mentioner, post, thread], [mentioner: mentioner, post: post, thread: thread])
  #     end
  #   Repo.all(query, prefix: "public")
  # end
end
