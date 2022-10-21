defmodule EpochtalkServerWeb.CustomErrors do
  # API Payload Handling
  defmodule InvalidPayload do
    @moduledoc """
    Exception raised when api request payload is incorrect
    """
    defexception plug_status: 400, message: "Invalid payload, check that the request payload is correct", conn: nil, router: nil
  end

  defmodule MalformedPayload do
    @moduledoc """
    Exception raised when api request payload JSON is malformed
    """
    defexception plug_status: 400, message: "Malformed JSON in request body", conn: nil, router: nil
  end

  defmodule OversizedPayload do
    @moduledoc """
    Exception raised when api request payload is too large
    """
    defexception plug_status: 400, message: "Payload too large", conn: nil, router: nil
  end
end
