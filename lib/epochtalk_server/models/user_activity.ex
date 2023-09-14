defmodule EpochtalkServer.Models.UserActivity do
  use Ecto.Schema
  require Logger
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.RoleUser
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.UserActivity
  alias EpochtalkServer.Session

  @period_days 14
  @hours 24
  @minutes 60
  @seconds 60
  @milliseconds 1000
  @period_length_ms @period_days * @hours * @minutes * @seconds * @milliseconds

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
  @spec update(user_id :: non_neg_integer) :: map() | :ok | :error
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
    db_total_activity = db_info.total_activity
    # If user has a start period they have preexisting activity info
    has_prev_activity = !!db_info.current_period_start

    # if user has existing user activity use it, otherwise create defaults
    info =
      if has_prev_activity,
        do: db_info,
        else: %{
          current_period_offset: db_info.registered_at,
          current_period_start: db_info.registered_at,
          remaining_period_activity: 14,
          user_id: user_id,
          total_activity: 0
        }

    period_start_unix = to_unix(info.current_period_start)
    period_end_naive = from_unix(period_start_unix + @period_length_ms)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # update info if period has ended
    period_ended = NaiveDateTime.compare(now, period_end_naive) == :gt

    info =
      if period_ended,
        do:
          info
          |> Map.put(:current_period_start, now)
          |> Map.put(:current_period_offset, now)
          # one point per day
          |> Map.put(:remaining_period_activity, @period_days),
        else: info

    # update period_end_naive with new info if period ended
    period_end_naive =
      if period_ended do
        period_start_unix = to_unix(info.current_period_start)
        from_unix(period_start_unix + @period_length_ms)
      else
        period_end_naive
      end

    if info.remaining_period_activity <= 0 do
      # do nothing, no remaining activity for this 2 week period
      :ok
    else
      # there is more activity remaining
      # add post count between offset and period end to total activity
      post_count =
        Post.count_by_user_id_in_range(user_id, info.current_period_offset, period_end_naive)

      posts_in_period = if period_ended, do: 1, else: post_count

      info =
        if posts_in_period >= info.remaining_period_activity,
          do:
            info
            |> Map.put(:total_activity, info.total_activity + info.remaining_period_activity)
            |> Map.put(:remaining_period_activity, 0),
          else:
            info
            |> Map.put(:total_activity, info.total_activity + posts_in_period)
            |> Map.put(
              :remaining_period_activity,
              info.remaining_period_activity - posts_in_period
            )

      handle_upsert(user_id, info, db_total_activity)
    end
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
  @spec update_user_activity(user :: map) :: :ok
  def update_user_activity(%{id: user_id} = _user) do
    info = UserActivity.update(user_id)

    if is_map(info) and info.old_activity < 30 and info.updated_activity >= 30 do
      # remove newbie role from user in db
      RoleUser.delete_newbie(user_id)
      # update user session because we changed user's roles
      Session.update(user_id)
      # send websocket notification to reauthenticate user
      EpochtalkServerWeb.Endpoint.broadcast("user:#{user_id}", "reauthenticate", %{})
    end

    :ok
  end

  ## === Private Helper Functions ===

  defp to_unix(naive_datetime),
    do: naive_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:millisecond)

  defp from_unix(naive_datetime),
    do: naive_datetime |> DateTime.from_unix!(:millisecond) |> DateTime.to_naive()

  defp handle_upsert(user_id, info, db_total_activity) do
    case Repo.insert(
           %UserActivity{
             user_id: user_id,
             current_period_start: info.current_period_start,
             current_period_offset: info.current_period_offset,
             remaining_period_activity: info.remaining_period_activity,
             total_activity: info.total_activity
           },
           on_conflict: [
             set: [
               current_period_start: info.current_period_start,
               current_period_offset: info.current_period_offset,
               remaining_period_activity: info.remaining_period_activity,
               total_activity: info.total_activity
             ]
           ],
           conflict_target: [:user_id]
         ) do
      {:ok, _} ->
        %{old_activity: db_total_activity, updated_activity: info.total_activity}

      {:error, err} ->
        Logger.error(inspect(err))
        :error
    end
  end
end
