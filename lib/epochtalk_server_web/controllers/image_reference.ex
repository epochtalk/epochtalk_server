defmodule EpochtalkServerWeb.Controllers.ImageReference do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Image Reference` related API requests
  """
  alias EpochtalkServer.Models.ImageReference
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  # alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Create new `ImageReference` and return presigned post
  """
  def s3_request_upload(conn, attrs) do
    # with :ok <- ACL.allow!(conn, "images.requestUpload"),
    with length <- Validate.cast(attrs, "length", :integer, required: true),
         file_type <- Validate.cast(attrs, "file_type", :string, required: true),
         # checksum <- Validate.cast(attrs, "checksum", :string, required: true),
         create_result <- ImageReference.create(%{length: length, type: file_type}) do
      render(conn, :s3_request_upload, %{
        create_result: create_result
      })
    else
      _ -> ErrorHelpers.render_json_error(conn, 400, "Error, image request upload failed")
    end
  end
end
