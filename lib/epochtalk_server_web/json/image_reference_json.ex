defmodule EpochtalkServerWeb.Controllers.ImageReferenceJSON do
  @moduledoc """
  Renders and formats `Controllers.ImageReference` data, in JSON format for frontend
  """

  @doc """
  Renders S3 presigned post response
  """
  def s3_request_upload(%{create_result: {:ok, image_reference, presigned_post}}) do
    %{presigned_post: presigned_post}
  end
end
