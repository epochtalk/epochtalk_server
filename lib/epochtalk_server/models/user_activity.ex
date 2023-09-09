defmodule EpochtalkServer.Models.UserActivity do
  use Ecto.Schema
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserActivity

  @period_days 14
  @hours 24
  @minutes 60
  @seconds 60
  @milliseconds 1000

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

  @doc """
  Updates `UserActivity` using the following algorithm

  1) Is current_period_start null, if so populate current_period_start and current_period_offset with user registration date
  2) check if current date is past (current_period_start + 14) if so update current_period_start and remaining_period_activity set to 14 and set current_period_offset to match start
  3) query remaining_period_activity if 0 then return else move to step 4

  # algorithm
  4) current_period_offset - (current_period_start + 14 days) postsFound = (Query posts between this time for user)
  5) if (postsFound >= remaining_period_activity) {
       total_activity += remaining_period_activity;
       remaining_period_activity = 0;
     }
    else {
      total_activity += postsFound;
      remaining_period_activity = remaining_period_activity - postsFound;
    }

  7) update total_activity, remaining_period_activity current_period_offset
  """
  @spec update(user_id :: non_neg_integer) :: {non_neg_integer, nil}
  def update(user_id) do
    query =
      from u in User,
        left_join: b in UserActivity,
        on: b.user_id == ^user_id,
        where: u.id == ^user_id,
        select: %{
          registered_at: u.created_at,
          user_id: u.id,
          current_period_start: b.current_period_start,
          current_period_offset: b.current_period_offset,
          remaining_period_activity: b.remaining_period_activity,
          total_activity: b.total_activity
        }

    db_info = Repo.one(query)
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

  @doc """
  Used to update `UserActivity` upon creating a `Post` or `Thread`. Removes newbie
  `Role` from `User` if activity reaches 30 or greater. Sends websocket notification
  to reauthenticate `User` after `Role` is removed.
  """
  @spec update_user_activity(user_id :: non_neg_integer) :: :ok
  def update_user_activity(user_id) do
    # TODO(akinsey): implement after update_user_activity
    :ok
  end
end
