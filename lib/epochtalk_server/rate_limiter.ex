defmodule EpochtalkServer.RateLimiter do
  import Hammer, only: [
    check_rate_inc: 4,
    delete_buckets: 1
  ]

  def check_rate_limited(type, user, count) do
    # get configs
    configs = EpochtalkServer.ConfigServer.by_module(__MODULE__)

    [key_fn, period, limit] = configs[type]
    user.id
    # build key with user id for rate limit check
    |> key_fn.()
    |> check_rate_inc(period, limit, count)
    |> case do
      {:allow, count} -> {:allow, count}
      {:deny, count} -> {type, count}
    end
  end

  @doc """
  Resets rate limit of specified type for specified user
  """
  @spec reset_rate_limit(type :: atom, user :: EpochtalkServer.Models.User.t()) :: {:ok, num_reset :: non_neg_integer}
  def reset_rate_limit(type, user) do
    # get configs
    configs = EpochtalkServer.ConfigServer.by_module(__MODULE__)

    [key_fn, _, _] = configs[type]
    user.id
    # build key with user id for rate limit check
    |> key_fn.()
    |> delete_buckets()
  end
end
