defmodule EpochtalkServerWeb.Controllers.ImageReferenceJSON do
  @moduledoc """
  Renders and formats `Controllers.ImageReference` data, in JSON format for frontend
  """

  @doc """
  Renders S3 presigned post response
  """
  def s3_request_upload(%{presigned_posts: presigned_posts}) do
    %{presigned_posts: presigned_posts}
  end
end
