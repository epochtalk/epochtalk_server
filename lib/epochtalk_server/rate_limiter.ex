defmodule EpochtalkServer.RateLimiter do
  import Hammer, only: [
    check_rate_inc: 4,
    delete_buckets: 1
  ]

  # default to a single action
  @default_count 1

  @doc """
  Updates rate limit of specified type for specified user
  and checks if the action is within the limits

  Returns type of action and error message on if action is denied
  """
  @spec check_rate_limited(type :: atom, user :: EpochtalkServer.Models.User.t()) :: {:allow, count :: non_neg_integer} | {type :: atom, count :: non_neg_integer} | {:error, message :: String.t()}
  def check_rate_limited(type, user), do: check_rate_limited(type, user, @default_count)

  @spec check_rate_limited(type :: atom, user :: EpochtalkServer.Models.User.t(), count :: non_neg_integer) :: {:allow, count :: non_neg_integer} | {type :: atom, count :: non_neg_integer} | {:error, message :: String.t()}
  def check_rate_limited(type, user, count) do
    type
    |> get_configs()
    |> case do
      [period, limit] ->
        # use Hammer to check rate limit
        build_key(type, user.id)
        |> check_rate_inc(period, limit, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {type, count}
        end
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Resets rate limit of specified type for specified user
  """
  @spec reset_rate_limit(type :: atom, user :: EpochtalkServer.Models.User.t()) :: {:ok, num_reset :: non_neg_integer}
  def reset_rate_limit(type, user) do
    # use Hammer to reset rate limit
    build_key(type, user.id)
    |> delete_buckets()
  end

  # get configs and handle case when config type is missing
  defp get_configs(type) do
    EpochtalkServer.ConfigServer.by_module(__MODULE__)
    |> Map.get(type)
    |> case do
      # return error if config not found in map
      nil -> {:error, "Could not get rate limit configs for type #{type}"}
      result -> result
    end
  end

  # build key with id for rate limit check
  defp build_key(type, id) do
    "#{to_string(type)}:user:#{id}"
  end
end
