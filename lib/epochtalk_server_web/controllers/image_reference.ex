defmodule EpochtalkServerWeb.Controllers.ImageReference do
  require Logger
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Image Reference` related API requests
  """
  alias EpochtalkServer.Models.ImageReference
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL

  # TODO(boka): move to config
  @max_images_per_request 10
  @one_day_in_ms 1000 * 60 * 60 * 24
  @one_hour_in_ms 1000 * 60 * 60
  @max_images_per_day 1000
  @max_images_per_hour 100

  @doc """
  Create new `ImageReference` and return presigned post
  """
  def s3_request_upload(conn, attrs_list) do
    with :ok <- ACL.allow!(conn, "images.upload.request"),
         user <- Guardian.Plug.current_resource(conn),
         # unwrap list from _json
         attrs_list <- attrs_list["_json"],
         attrs_length <- length(attrs_list),
         # ensure list does not exceed max length
         :ok <- validate_max_length(attrs_length, @max_images_per_request),
         # ensure daily rate limit not exceeded
         {:allow, daily_count} <- Hammer.check_rate_inc("s3_request_upload:user:#{user.id}", @one_day_in_ms, @max_images_per_day, attrs_length),
         # ensure hourly rate limit not exceeded
         {:allow, hourly_count} <- Hammer.check_rate_inc("s3_request_upload:user:#{user.id}", @one_hour_in_ms, @max_images_per_hour, attrs_length),
         casted_attrs_list <- Enum.map(attrs_list, &cast_upload_attrs/1),
         {:ok, presigned_posts} <- ImageReference.create(casted_attrs_list) do
      Logger.debug("Hourly count for user #{user.username}: #{hourly_count}/#{@max_images_per_hour}")
      Logger.debug("Daily count for user #{user.username}: #{daily_count}/#{@max_images_per_day}")
      render(conn, :s3_request_upload, %{presigned_posts: presigned_posts})
    else
      {:max_length_error, message} -> ErrorHelpers.render_json_error(conn, 400, message)
      {:deny, message} ->
        if message == @max_images_per_hour do
          ErrorHelpers.render_json_error(conn, 400, "Hourly upload rate limit exceeded (#{@max_images_per_hour})")
        else
          ErrorHelpers.render_json_error(conn, 400, "Daily rate limit exceeded (#{@max_images_per_day})")
        end
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, image request upload failed")
    end
  end

  defp validate_max_length(attrs_length, max_length) do
    if attrs_length <= max_length do
      :ok
    else
      {:max_length_error, "Requested images amount #{attrs_length} exceeds max of #{max_length}"}
    end
  end

  defp cast_upload_attrs(attrs) do
    with length <- Validate.cast(attrs, "length", :integer, required: true),
         # checksum <- Validate.cast(attrs, "checksum", :string, required: true),
         file_type <- Validate.cast(attrs, "file_type", :string, required: true) do
      %{length: length, type: file_type}
    else
      _ -> %{error: "Invalid attrs"}
    end
  end
end
