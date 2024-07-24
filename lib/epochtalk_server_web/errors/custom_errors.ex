defmodule EpochtalkServerWeb.CustomErrors do
  # Auto Moderator Error Handling
  # credo:disable-for-next-line
  defmodule AutoModeratorReject do
    @moduledoc """
    Exception raised when api request payload is incorrect
    """
    @default_message "Post rejected by Auto Moderator"
    defexception plug_status: 400, message: @default_message

    @impl true
    def exception(value) do
      case value do
        [message: nil] -> %AutoModeratorReject{}
        [message: message] -> %AutoModeratorReject{message: message}
        _ -> %AutoModeratorReject{}
      end
    end
  end

  # ACL Permissions
  # credo:disable-for-next-line
  defmodule InvalidPermission do
    @moduledoc """
    Exception raised when api request payload is incorrect
    """
    @default_message "Forbidden, invalid permissions to perform this action"
    defexception plug_status: 403, message: @default_message

    @impl true
    def exception(value) do
      case value do
        [message: nil] -> %InvalidPermission{}
        [message: message] -> %InvalidPermission{message: message}
        _ -> %InvalidPermission{}
      end
    end
  end

  # Rate Limiter error handling
  # credo:disable-for-next-line
  defmodule RateLimitExceeded do
    @moduledoc """
    Exception raised when api request rate limit is exceeded
    """
    @default_message "Rate limit exceeded"
    defexception plug_status: 429, message: @default_message

    @impl true
    def exception(value) do
      case value do
        [message: nil] -> %RateLimitExceeded{}
        [message: message] -> %RateLimitExceeded{message: message}
        _ -> %RateLimitExceeded{}
      end
    end
  end

  # API Payload Handling
  defmodule InvalidPayload do
    @moduledoc """
    Exception raised when api request payload is incorrect
    """
    @default_message "Invalid payload, check that the request payload is correct"
    defexception plug_status: 400, message: @default_message

    @impl true
    def exception(value) do
      case value do
        [] -> %InvalidPayload{}
        [message: message] -> %InvalidPayload{message: message}
        _ -> %InvalidPayload{message: gen_message(Enum.into(value, %{required: false}))}
      end
    end

    # Handle error messages for integer min/max
    defp gen_message(%{key: k, type: :integer, required: _, max: max, min: min}),
      do: "Invalid payload, key '#{k}' should be of type 'integer' and between #{min} and #{max}"

    defp gen_message(%{key: k, type: :integer, required: _, min: m}),
      do:
        "Invalid payload, key '#{k}' should be of type 'integer' and greater than or equal to #{m}"

    defp gen_message(%{key: k, type: :integer, required: _, max: m}),
      do: "Invalid payload, key '#{k}' should be of type 'integer' and less than or equal to #{m}"

    defp gen_message(%{key: k, type: :string, required: _, max: max, min: min}),
      do:
        "Invalid payload, key '#{k}' should be of type 'string' with length between #{min} and #{max}"

    defp gen_message(%{key: k, type: :string, required: _, min: m}),
      do:
        "Invalid payload, key '#{k}' should be of type 'string' with length greater than or equal to #{m}"

    defp gen_message(%{key: k, type: :string, required: _, max: m}),
      do:
        "Invalid payload, key '#{k}' should be of type 'string' with length less than or equal to #{m}"

    # Handle error messages for required (boolean)
    defp gen_message(%{key: k, type: t, required: _}),
      do: "Invalid payload, key '#{k}' should be of type '#{Atom.to_string(t)}'"

    # Handle error messages, when no options are passed
    defp gen_message(%{type: t, required: _}),
      do: "Invalid payload, cannot parse, parameter should be of type '#{Atom.to_string(t)}'"

    # Fallback
    defp gen_message(_), do: @default_message
  end

  defmodule MalformedPayload do
    @moduledoc """
    Exception raised when api request payload JSON is malformed
    """
    defexception plug_status: 400, message: "Malformed JSON in request body"
  end

  defmodule OversizedPayload do
    @moduledoc """
    Exception raised when api request payload is too large
    """
    defexception plug_status: 400, message: "Payload too large"
  end
end
