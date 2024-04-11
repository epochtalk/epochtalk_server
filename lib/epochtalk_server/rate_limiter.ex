defmodule EpochtalkServer.RateLimiter do
  import Hammer, only: [check_rate_inc: 4]

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
end
