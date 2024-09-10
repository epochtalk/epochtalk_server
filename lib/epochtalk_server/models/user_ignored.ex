defmodule EpochtalkServer.Models.UserIgnored do
  use Ecto.Schema
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.UserIgnored

  @moduledoc """
  `UserIgnored` model, for performing actions relating to `UserIgnored`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          ignored_user_id: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :ignored_user_id,
             :created_at
           ]}
  @schema_prefix "users"
  @primary_key false
  schema "ignored" do
    belongs_to :user, User
    belongs_to :ignored_user, User
    field :created_at, :naive_datetime_usec
  end

  ## === Database Functions ===

  @doc """
  Used to get `UserIgnored` data for a specific `User` on a list of `user_id`
  """
  @spec by_user_ids(user_id :: non_neg_integer, user_ids :: [non_neg_integer]) ::
          ignored_users_list :: [non_neg_integer]
  def by_user_ids(user_id, user_ids) when is_integer(user_id) and is_list(user_ids) do
    query =
      from u in UserIgnored,
        where: u.user_id == ^user_id and u.ignored_user_id in ^user_ids,
        select: u.ignored_user_id

    Repo.all(query)
  end

  ## === Public Helper Functions ===

  @doc """
  Appends `UserIgnored` data to list of `Post`
  """
  @spec append_user_ignored_data_to_posts(
          posts :: [],
          authed_user :: User.t() | nil
        ) :: [Post.t()]
  def append_user_ignored_data_to_posts(posts, authed_user)
  def append_user_ignored_data_to_posts(posts, nil), do: posts

  def append_user_ignored_data_to_posts(posts, authed_user) when is_list(posts) do
    posts_user_ids = Enum.map(posts, & &1.user_id)
    ignored_user_ids = UserIgnored.by_user_ids(authed_user.id, posts_user_ids)

    Enum.map(posts, fn post ->
      if post.user_id in ignored_user_ids,
        do: post |> Map.put(:user_ignored, true),
        else: post
    end)
  end
end
