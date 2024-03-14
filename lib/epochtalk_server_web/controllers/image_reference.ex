defmodule EpochtalkServerWeb.Controllers.ImageReference do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Image Reference` related API requests
  """
  alias EpochtalkServer.Models.ImageReference
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL

  # TODO(boka): move to config
  @max_images 10

  @doc """
  Create new `ImageReference` and return presigned post
  """
  def s3_request_upload(conn, attrs_list) do
    with :ok <- ACL.allow!(conn, "images.upload.request"),
         # unwrap list from _json
         attrs_list <- attrs_list["_json"],
         # ensure list does not exceed max size
         true <- length(attrs_list) <= @max_images,
         casted_attrs_list <- Enum.map(attrs_list, &cast_upload_attrs/1),
         create_result <- ImageReference.create(casted_attrs_list) do
      render(conn, :s3_request_upload, %{
        create_result: create_result
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, image request upload failed")
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
