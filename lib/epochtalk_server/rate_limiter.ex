defmodule EpochtalkServer.RateLimiter do
  import Hammer, only: [check_rate_inc: 4]

  def check_rate_limited(type, user, count) do
    # get configs
    configs = EpochtalkServer.ConfigServer.by_module(__MODULE__)

    case type do
      :s3_daily ->
        [key_fn, period, limit] = configs[:s3_daily]
        key_fn.(user.id)
        |> check_rate_inc(period, limit, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {:s3_daily, count}
        end
      :s3_hourly ->
        [key_fn, period, limit] = configs[:s3_hourly]
        key_fn.(user.id)
        |> check_rate_inc(period, limit, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {:s3_hourly, count}
        end
    end
  end
end
