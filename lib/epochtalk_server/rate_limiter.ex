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

  @valid_classes [:http, :api]

  # do not use a rate limit lower base rate limits
  @minimum_priority_multiplier 1.0

  # priority multipliers
  @super_admin_priority_multiplier @minimum_priority_multiplier
  @admin_priority_multiplier @minimum_priority_multiplier
  @global_moderator_priority_multiplier @minimum_priority_multiplier
  @moderator_priority_multiplier @minimum_priority_multiplier
  @user_priority_multiplier @minimum_priority_multiplier
  @patroller_priority_multiplier @minimum_priority_multiplier
  @newbie_priority_multiplier 5.0
  @anonymous_priority_multiplier 5.0
  @banned_priority_multiplier 10.0
  @private_priority_multiplier 5.0

  import Hammer,
    only: [
      check_rate_inc: 4,
      delete_buckets: 1
    ]

  def init() do
    config :epochtalk_server, __MODULE__,
      http: %{
        "GET" => {
          @one_second_in_ms,
          @max_get_per_second
        },
        "POST" => {
          @one_second_in_ms,
          @max_post_per_second
        },
        "PUT" => {
          @one_second_in_ms,
          @max_put_per_second
        },
        "PATCH" => {
          @one_second_in_ms,
          @max_patch_per_second
        },
        "DELETE" => {
          @one_second_in_ms,
          @max_delete_per_second
        }
      },
      api: %{
        :s3_hourly => {
          @one_hour_in_ms,
          @max_images_per_hour
        }
      },
      priority_multipliers: %{
        # admins
        "0" => @super_admin_priority_multiplier,
        "1" => @admin_priority_multiplier,
        # moderators
        "2" => @global_moderator_priority_multiplier,
        "3" => @moderator_priority_multiplier,
        # user and patroller
        "4" => @user_priority_multiplier,
        "5" => @patroller_priority_multiplier,
        # newbie
        "6" => @newbie_priority_multiplier,
        # banned, anonymous, private
        "7" => @banned_priority_multiplier,
        "8" => @anonymous_priority_multiplier,
        "9" => @private_priority_multiplier
      }
  end

  # default to a single action
  @default_count 1

  @doc """
  Updates rate limit of specified action_type for specified user
  and checks if the action is within the limits

  Returns action_type and error message if action is denied
  """
  @type option :: {:count, non_neg_integer} | {:priority, non_neg_integer}
  @spec check_rate_limited(
          class :: atom,
          action_type :: atom,
          user_id :: String.t(),
          options :: [option]
        ) ::
          {:allow, count :: non_neg_integer}
          | {class :: atom, action_type :: atom, max_count :: non_neg_integer}
          | {:error, message :: String.t()}
  def check_rate_limited(class, action_type, user_id, options \\ []) do
    with count <- Keyword.get(options, :count, @default_count),
         priority <- Keyword.get(options, :priority),
         {:ok, {period, limit}} <- {class, action_type, priority} |> get_configs(),
         key <- build_key(action_type, user_id),
         # use Hammer to check rate limit
         {:allow, count} <- check_rate_inc(key, period, limit, count) do
      {:allow, count}
    else
      {:deny, max_count} -> {class, action_type, max_count}
      {:bypass, message} -> {:allow, message}
      {:error, message} -> raise message
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
  defp get_configs({class, action_type, priority}) do
    with configs <- Application.get_env(:epochtalk_server, __MODULE__),
         {:ok, {period, limit}} <- get_period_and_limit(configs, class, action_type),
         {:ok, priority_multiplier} <- get_priority_multiplier(configs, priority) do
      {:ok, {period * priority_multiplier, limit}}
    else
      {:error, :class_invalid} ->
        # return error if class is not valid
        {:error, "Could not get rate limit configs for class #{class}"}

      {:error, :no_multiplier_for_priority} ->
        # return error if class is not valid
        {:error, "Could not get rate limit configs for user priority #{priority}"}

      {:error, :no_configs} ->
        # configs were not found in map
        if class == :api do
          # bypass if for api route
          {:bypass, "No configuration for this api route, bypassing"}
        else
          # return error if for http action
          {:error, "Could not get rate limit configs for action_type #{action_type}"}
        end
    end
  end

  # get period and limit from configs for class and action type
  defp get_period_and_limit(configs, class, action_type) do
    with {:ok, class} <- class |> class_valid?(),
         {period, limit} <- configs |> Keyword.get(class) |> Map.get(action_type) do
      {:ok, {period, limit}}
    else
      # class is invalid, bubble up
      {:error, :class_invalid} -> {:error, :class_invalid}
      # period and limit not found
      nil -> {:error, :no_configs}
      # something went really wrong
      _ -> {:error, "oops"}
    end
  end

  ## get priority multiplier from configs for priority number
  # if priority is nil, return minimum priority multiplier
  defp get_priority_multiplier(_configs, nil), do: {:ok, @minimum_priority_multiplier}

  defp get_priority_multiplier(configs, priority) do
    priority_string = priority |> Integer.to_string()

    configs
    |> Keyword.get(:priority_multipliers)
    |> Map.get(priority_string)
    |> case do
      nil ->
        {:error, :no_multiplier_for_priority}

      priority_multiplier ->
        # return priority_multiplier or @minimum_priority_multiplier
        # if priority_multiplier is lower for some reason
        {:ok, max(priority_multiplier, @minimum_priority_multiplier)}
    end
  end

  # check if class is valid
  defp class_valid?(class) do
    if class in @valid_classes do
      {:ok, class}
    else
      {:error, :class_invalid}
    end
  end

  # build key with id for rate limit check
  defp build_key(action_type, id) do
    "#{to_string(action_type)}:user:#{id}"
  end
end
