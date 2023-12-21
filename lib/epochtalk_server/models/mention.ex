defmodule EpochtalkServer.Models.Mention do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Mailer
  alias EpochtalkServer.Models.Mention
  alias EpochtalkServer.Models.MentionIgnored
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Board
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Preference
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

    mention =
      mention
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
  Iterates through list of `Post`, converts mentioned `User` id to a `User` usernames within the body of posts.
  Used when retreiving posts from the database
  """
  @spec user_id_to_username(posts :: map() | [map()]) ::
          updated_posts :: [map()]
  def user_id_to_username(post) when is_map(post),
    do: user_id_to_username([post])

  def user_id_to_username(posts) when is_list(posts) do
    # iterate over each post
    Enum.map(posts, fn post ->
      # move post_body to body and body_html so it is processed properly
      post =
        if Map.has_key?(post, :post_body),
          do: post |> Map.put(:body, post.post_body) |> Map.put(:body_html, post.post_body),
          else: post

      if Map.has_key?(post, :body) do
        user_ids =
          Regex.scan(EpochtalkServer.Regex.pattern(:user_id), post.body)
          # only need unique list of user_ids
          |> Enum.uniq()
          # remove "{@}" from mentioned user_id
          |> Enum.map(&String.slice(&1, 2..-1))

        Enum.reduce(user_ids, post, fn user_id, modified_post ->
          username = User.username_by_id(user_id)

          profile_link =
            "<router-link :to=\"{path: '/profile/#{String.downcase(username)}'}\">@#{username}</router-link>"

          # swap {@user_id} for @username in post_body
          updated_body = String.replace(modified_post.body, "{@#{user_id}}", "@#{username}")

          updated_body_html =
            String.replace(
              modified_post.body_html,
              EpochtalkServer.Regex.pattern(:user_id),
              profile_link
            )

          modified_post =
            Map.put(modified_post, :body, updated_body) |> Map.put(:body_html, updated_body_html)

          # returns modified post, but handles case where post_body exists
          handle_post_body(post, modified_post)
        end)
      else
        post
      end
    end)
  end

  @doc """
  Within `Post`, converts mentioned `User` usernames to a `User` ids within the body of posts.
  Used before storing `Post` in the database
  """
  @spec username_to_user_id(user :: map(), post_attrs :: map()) ::
          updated_post_attrs :: map()
  def username_to_user_id(%{id: _id, roles: _roles} = user, post_attrs) do
    with :ok <- ACL.allow!(user, "mentions.create") do
      body = post_attrs["body"]

      # store original body, before modifying mentions
      post_attrs = Map.put(post_attrs, "body_original", body)

      # replace "@UsErNamE" mention with "{@username}"
      body =
        String.replace(
          body,
          EpochtalkServer.Regex.pattern(:username_mention),
          &"{#{String.downcase(&1)}}"
        )

      # update post_attrs with modified body
      post_attrs = Map.put(post_attrs, "body", body)

      # get list of unique usernames that were mentioned in the post body
      possible_usernames =
        Regex.scan(EpochtalkServer.Regex.pattern(:username_mention_curly), body)
        # only need unique list of usernames
        |> Enum.uniq()
        # extract username from regex scan
        |> Enum.map(fn [_match, username] -> username end)

      # get map of ids from list of possible_usernames
      # to determine if a possible_username should be replaced
      mentioned_usernames_to_id_map =
        possible_usernames
        # get ids for usernames that exist
        |> User.ids_from_usernames()
        # map usernames to user_ids
        |> Enum.reduce(%{}, fn %User{id: user_id, username: username}, acc ->
          Map.put(acc, username, user_id)
        end)

      # initialize mentioned_ids to empty
      post_attrs = Map.put(post_attrs, "mentioned_ids", [])

      # update post body, converting username mentions to user id mentions
      # and unmatched possible_usernames back to unused mentions
      # and add mentioned_ids, return post attrs
      Enum.reduce(possible_usernames, post_attrs, fn possible_username, acc ->
        # check if possible_username is mapped in mentioned_usernames_to_id_map
        {replacement, user_id} =
          case Map.get(mentioned_usernames_to_id_map, possible_username) do
            # username was invalid, replace with original text
            nil -> {"@#{possible_username}", nil}
            # username was valid, replace with user id bracket
            user_id -> {"{@#{user_id}}", user_id}
          end

        # get downcased version of username for replacement matching
        username_mention = "{@#{String.downcase(possible_username)}}"

        # replace usernames mentions in body with user id mention OR original text
        body = acc["body"]
        body = String.replace(body, username_mention, replacement)

        # if mention was valid, update list of unique user ids mentioned in the post body
        mentioned_ids = acc["mentioned_ids"]
        mentioned_ids = if user_id != nil, do: mentioned_ids ++ [user_id], else: mentioned_ids

        # update post_attrs
        acc
        |> Map.put("body", body)
        |> Map.put("mentioned_ids", mentioned_ids)
      end)
    else
      # no permissions to create mentions, do nothing
      _ -> post_attrs
    end
  end

  @doc """
  Fixes text search vector, since usernames are being converted to user ids before
  `Post` is created, the created `Post` will have the ids in the tsv field. To correct
  this we recreate the tsv field using the original `Post` body.
  """
  @spec correct_text_search_vector(post_attrs :: map()) ::
          :ok | {non_neg_integer(), nil}
  def correct_text_search_vector(post_attrs) do
    mentioned_ids = post_attrs["mentioned_ids"] || []

    if mentioned_ids == [],
      do: :ok,
      else: Post.fix_text_search_vector(post_attrs)
  end

  @doc """
  Handles logic tied to the creation of `Mention`. Performs the following actions:

  * Checks that `User` has permission to create `Mention`
  * Iterates though each mentioned `User`
    * Checks that mentioned `User` is not ignoring the authenticated `User`
    * Creates mentions
    * Sends websocket notification
    * Checks mention email settings
      * Sends email to mentioned user if applicable
  """
  @spec handle_user_mention_creation(user :: map(), post_attrs :: map(), post :: Post.t()) ::
          :ok
  def handle_user_mention_creation(user, post_attrs, post) do
    with :ok <- ACL.allow!(user, "mentions.create") do
      mentioned_ids = post_attrs["mentioned_ids"] || []

      # iterate through each mentioned user id
      Enum.each(mentioned_ids, fn mentionee_id ->
        # check that authed user isn't being ignored by the mentioned user
        authed_user_ignored = MentionIgnored.is_user_ignored?(mentionee_id, post.user_id)

        # check that user isn't mentioning themselves and that they aren't ignored
        if post.user_id != mentionee_id && authed_user_ignored == false do
          mention = %{
            "thread_id" => post.thread_id,
            "post_id" => post.id,
            "mentioner_id" => post.user_id,
            "mentionee_id" => mentionee_id
          }

          # create mention
          {:ok, mention} = Mention.create(mention)

          notification = %{
            "sender_id" => post.user_id,
            "receiver_id" => mentionee_id,
            "type" => "user",
            "data" => %{
              action: "refreshMentions",
              mention_id: mention.id
            }
          }

          # create notification associated with mention (for mentions dropdown)
          Notification.create(notification)

          # send websocket notification to mentionee
          EpochtalkServerWeb.Endpoint.broadcast("user:#{mentionee_id}", "refreshMentions", %{})

          # check mentionee's email settings for mentions and then maybe send email
          if Preference.email_mentions?(mentionee_id) do
            thread_post_data = Thread.get_first_post_data_by_id(post.thread_id)
            # get mentionee's email
            mentionee_email = User.email_by_id(mentionee_id)

            # send email
            Mailer.send_mention_notification(%{
              email: mentionee_email,
              post_id: post.id,
              post_position: post.position,
              post_author: user.username,
              thread_slug: post.thread_slug,
              thread_title: thread_post_data.title
            })
          end
        end
      end)

      :ok
    else
      # no permissions to create mentions, do nothing
      _ -> :ok
    end
  end

  ## === Private Helper Functions ===

  defp handle_post_body(post, modified_post) do
    if Map.has_key?(post, :post_body),
      do:
        modified_post
        |> Map.put(:post_body, modified_post.body_html)
        |> Map.delete(:body)
        |> Map.delete(:body_html),
      else: modified_post
  end

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
