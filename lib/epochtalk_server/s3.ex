defmodule EpochtalkServer.S3 do
  @moduledoc """
  Handles server-side communication with AWS S3
  """
  require Logger

  @dialyzer {:no_return, generate_presigned_post: 1}

  @doc """
  Generate a presigned post with specified params:
    filename: name of the file
  """
  @spec generate_presigned_post(params :: map) :: ExAws.S3.presigned_post_result()
  def generate_presigned_post(%{filename: filename}) do
    config = Application.get_env(:epochtalk_server, __MODULE__)

    opts = [
      expires_in: config[:expire_after_hours],
      content_length_range: [config[:min_size_bytes], config[:max_size_bytes]],
      virtual_host: config[:virtual_host],
      starts_with: ["$Content-Type", config[:content_type_starts_with]]
    ]

    ExAws.Config.new(:s3, [])
    |> ExAws.S3.presigned_post(config[:bucket], config[:path] <> filename, opts)
  end
end
