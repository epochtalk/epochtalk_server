defmodule EpochtalkServer.RateLimiter do
  @moduledoc """
  Handle rate limits for action type by user
  """
  import Config

  @one_hour_in_ms 1000 * 60 * 60
  @max_images_per_hour 100
  @one_second_in_ms 1000
  @max_get_per_second 10
  @max_post_per_second 2
  @max_put_per_second 2
  @max_patch_per_second 2
  @max_delete_per_second 2

  import Hammer,
    only: [
      check_rate_inc: 4,
      delete_buckets: 1
    ]

  def init() do
    config :epochtalk_server, __MODULE__,
      get: {
        @one_second_in_ms,
        @max_get_per_second
      },
      post: {
        @one_second_in_ms,
        @max_post_per_second
      },
      put: {
        @one_second_in_ms,
        @max_put_per_second
      },
      patch: {
        @one_second_in_ms,
        @max_patch_per_second
      },
      delete: {
        @one_second_in_ms,
        @max_delete_per_second
      },
      s3_hourly: {
        @one_hour_in_ms,
        @max_images_per_hour
      }
  end

  # default to a single action
  @default_count 1

  @doc """
  Updates rate limit of specified action_type for specified user
  and checks if the action is within the limits

  Returns action_type and error message if action is denied
  """
  @spec check_rate_limited(action_type :: atom, user_id :: String.t()) ::
          {:allow, count :: non_neg_integer}
          | {action_type :: atom, count :: non_neg_integer}
          | {:error, message :: String.t()}
  def check_rate_limited(action_type, user_id), do: check_rate_limited(action_type, user_id, @default_count)

  @spec check_rate_limited(
          action_type :: atom,
          user_id :: String.t(),
          count :: non_neg_integer
        ) ::
          {:allow, count :: non_neg_integer}
          | {action_type :: atom, count :: non_neg_integer}
          | {:error, message :: String.t()}
  def check_rate_limited(action_type, user_id, count) do
    action_type
    |> get_configs()
    |> case do
      {:error, message} -> raise message

      {period, limit} ->
        # use Hammer to check rate limit
        build_key(action_type, user_id)
        |> check_rate_inc(period, limit, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {action_type, count}
        end
    end
  end

  @doc """
  Resets rate limit of specified action_type for specified user
  """
  @spec reset_rate_limit(action_type :: atom, user_id :: String.t()) ::
          {:ok, num_reset :: non_neg_integer}
  def reset_rate_limit(action_type, user_id) do
    # use Hammer to reset rate limit
    build_key(action_type, user_id)
    |> delete_buckets()
  end

  # get configs and handle case when config action_type is missing
  defp get_configs(action_type) do
    Application.get_env(:epochtalk_server, __MODULE__)
    |> Keyword.get(action_type)
    |> case do
      # return error if config not found in map
      nil -> {:error, "Could not get rate limit configs for action_type #{action_type}"}
      result -> result
    end
  end

  # build key with id for rate limit check
  defp build_key(action_type, id) do
    "#{to_string(action_type)}:user:#{id}"
  end
end
