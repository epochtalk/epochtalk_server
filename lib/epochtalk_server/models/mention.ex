defmodule EpochtalkServer.Models.Mention do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Mention
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Notification
  alias EpochtalkServerWeb.Helpers.Pagination
  alias EpochtalkServerWeb.Helpers.ACL

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
  Create changeset for `Mention` model
  """
  @spec create_changeset(mention :: t(), attrs :: map() | nil) :: Ecto.Changeset.t()
  def create_changeset(mention, attrs) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    attrs =
      attrs
      |> Map.put(:created_at, now)

    mention
    |> cast(attrs, [:id, :thread_id, :post_id, :mentioner_id, :mentionee_id, :created_at])
    |> unique_constraint(:id, name: :mentions_pkey)
    |> foreign_key_constraint(:mentionee_id, name: :mentions_mentionee_id_fkey)
    |> foreign_key_constraint(:mentioner_id, name: :mentions_mentioner_id_fkey)
    |> foreign_key_constraint(:post_id, name: :mentions_post_id_fkey)
    |> foreign_key_constraint(:thread_id, name: :mentions_thread_id_fkey)
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
  @spec page_by_user_id(user_id :: non_neg_integer, page :: non_neg_integer,
          per_page: non_neg_integer,
          extended: boolean
        ) :: {:ok, mentions :: [t()] | [], pagination_data :: map()}
  def page_by_user_id(user_id, page \\ 1, opts \\ []) do
    page_query(user_id, opts[:extended])
    |> Pagination.page_simple(page, per_page: opts[:per_page])
  end

  @doc """
  Create a `Mention` if the mentioned `User` has permission to view `Board` they are being mentioned in.
  """
  @spec create(mention_attrs :: map) ::
          {:ok, mention :: t() | boolean} | {:error, Ecto.Changeset.t()}
  def create(mention_attrs) do
    query =
      from b in Board,
        where:
          fragment(
            """
              ? = (SELECT board_id FROM threads WHERE id = ?)
              AND (? IS NULL OR ? >= (SELECT r.priority FROM roles_users ru, roles r WHERE ru.role_id = r.id AND ru.user_id = ? ORDER BY r.priority limit 1))
              AND (SELECT EXISTS ( SELECT 1 FROM board_mapping WHERE board_id = (SELECT board_id FROM threads WHERE id = ?)))
            """,
            b.id,
            ^mention_attrs["thread_id"],
            b.viewable_by,
            b.viewable_by,
            ^mention_attrs["mentionee_id"],
            ^mention_attrs["thread_id"]
          ),
        select: true

    can_view_board = !!Repo.one(query)

    if can_view_board,
      do: create_changeset(%Mention{}, mention_attrs) |> Repo.insert(returning: true),
      else: {:ok, false}
  end

  @doc """
  Delete all `Mention` for a specific `User`
  """
  @spec delete_by_user_id(user_id :: non_neg_integer) ::
          {:ok, deleted :: boolean}
  def delete_by_user_id(user_id) when is_integer(user_id) do
    query =
      from m in Mention,
        where: m.mentionee_id == ^user_id

    {num_deleted, _} = Repo.delete_all(query)

    {:ok, num_deleted > 0}
  end

  @doc """
  Delete specific `Mention` by `id`
  """
  @spec delete(id :: non_neg_integer) ::
          {:ok, deleted :: boolean}
  def delete(id) when is_integer(id) do
    query =
      from m in Mention,
        where: m.id == ^id

    {num_deleted, _} = Repo.delete_all(query)

    {:ok, num_deleted > 0}
  end

  ## === Public Helper Functions ===
  @doc """
  Iterates through list of `Post`, converts mentioned `User` usernames to a `User` ids within the body of posts
  """
  @spec username_to_user_id(conn :: Plug.Conn.t(), post_attrs :: map()) :: updated_post_attrs :: map()
  def username_to_user_id(conn, post_attrs) do
    with :ok <- ACL.allow!(conn, "mentions.create") do
      post_attrs
    else
      _ -> post_attrs
    end
  end

  ## === Private Helper Functions ===

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
      # sort by id fixes duplicate timestamp issues
      order_by: [desc: m.created_at, desc: m.id],
      # set virtual field from notification join
      select_merge: %{notification_id: notification.id, viewed: notification.viewed},
      preload: [mentioner: {mentioner, profile: profile}, post: post, thread: thread]
  end

  # loads board association on thread
  defp page_query(user_id, true = _extended) do
    from m in Mention,
      where: m.mentionee_id == ^user_id,
      left_join: notification in Notification,
      on: m.id == type(notification.data["mentionId"], :integer),
      left_join: mentioner in assoc(m, :mentioner),
      left_join: profile in assoc(mentioner, :profile),
      left_join: post in assoc(m, :post),
      left_join: thread in assoc(m, :thread),
      left_join: board in assoc(thread, :board),
      # sort by id fixes duplicate timestamp issues
      order_by: [desc: m.created_at, desc: m.id],
      # set virtual field from notification join
      select_merge: %{notification_id: notification.id, viewed: notification.viewed},
      preload: [
        mentioner: {mentioner, profile: profile},
        post: post,
        thread: {thread, board: board}
      ]
  end
end
