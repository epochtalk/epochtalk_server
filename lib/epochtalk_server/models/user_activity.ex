defmodule EpochtalkServer.Models.UserActivity do
  use Ecto.Schema
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserActivity

  @moduledoc """
  `UserActivity` model, for performing actions relating to `UserActivity`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          current_period_start: NaiveDateTime.t() | nil,
          current_period_offset: NaiveDateTime.t() | nil,
          remaining_period_activity: non_neg_integer | nil,
          total_activity: non_neg_integer | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :current_period_start,
             :current_period_offset,
             :remaining_period_activity,
             :total_activity
           ]}
  @primary_key false
  schema "user_activity" do
    belongs_to :user, User
    field :current_period_start, :naive_datetime
    field :current_period_offset, :naive_datetime
    field :remaining_period_activity, :integer, default: 14
    field :total_activity, :integer, default: 0
  end

  ## === Database Functions ===

  @doc """
  Used to get the `UserActivity` for a specific `User`
  """
  @spec get_by_user_id(user_id :: non_neg_integer) ::
          user_activity :: non_neg_integer
  def get_by_user_id(user_id) when is_integer(user_id) do
    query =
      from u in UserActivity,
        where: u.user_id == ^user_id,
        select: u.total_activity

    Repo.one(query) || 0
  end

  ## === Public Helper Functions ===

  @doc """
  Appends `UserActivity` data to list of `Post`
  """
  @spec append_user_activity_to_posts(posts :: []) ::
          posts :: []
  def append_user_activity_to_posts(posts) when is_list(posts) do
    Enum.map(posts, fn post ->
      if post.user_deleted,
        do: post,
        else: post |> Map.put(:user_activity, UserActivity.get_by_user_id(post.user_id))
    end)
  end
end
