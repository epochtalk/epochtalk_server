defmodule EpochtalkServer.RateLimiter do
  # TODO(boka): move to config
  @one_day_in_ms 1000 * 60 * 60 * 24
  @one_hour_in_ms 1000 * 60 * 60
  @max_images_per_day 1000
  @max_images_per_hour 100

  import Hammer, only: [check_rate_inc: 4]

  def check_rate_limited(type, user, count) do
    case type do
      :s3_daily ->
        check_rate_inc("s3_request_upload:user:#{user.id}", @one_day_in_ms, @max_images_per_day, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {:s3_daily, count}
        end
      :s3_hourly ->
        check_rate_inc("s3_request_upload:user:#{user.id}", @one_hour_in_ms, @max_images_per_hour, count)
        |> case do
          {:allow, count} -> {:allow, count}
          {:deny, count} -> {:s3_hourly, count}
        end
    end
  end
end
