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
  import EpochtalkServer.RateLimiter, only: [check_rate_limited: 3]

  # TODO(boka): move to config
  @max_images_per_request 10

  @doc """
  Create new `ImageReference` and return presigned post
  """
  def s3_request_upload(conn, %{"images" => attrs_list}) do
    with :ok <- ACL.allow!(conn, "images.upload.request"),
         user <- Guardian.Plug.current_resource(conn),
         attrs_length <- length(attrs_list),
         # ensure list does not exceed max length
         :ok <- validate_max_length(attrs_length, @max_images_per_request),
         # ensure hourly rate limit not exceeded
         {:allow, hourly_count} <- check_rate_limited(:s3_hourly, user, attrs_length),
         casted_attrs_list <- Enum.map(attrs_list, &cast_upload_attrs/1),
         {:ok, presigned_posts} <- ImageReference.create(casted_attrs_list) do
      Logger.debug("Hourly count for user #{user.username}: #{hourly_count}")
      render(conn, :s3_request_upload, %{presigned_posts: presigned_posts})
    else
      {:max_length_error, message} ->
        ErrorHelpers.render_json_error(conn, 400, message)

      {:s3_hourly, count} ->
        ErrorHelpers.render_json_error(conn, 429, "Hourly upload rate limit exceeded (#{count})")

      {:rate_limiter_error, message} ->
        ErrorHelpers.render_json_error(conn, 500, "Rate limiter error #{message}")

      _ ->
        ErrorHelpers.render_json_error(conn, 400, "Error, image request upload failed")
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
