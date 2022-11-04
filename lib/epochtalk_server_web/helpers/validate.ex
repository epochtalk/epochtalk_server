defmodule EpochtalkServerWeb.Helpers.Validate do
  @moduledoc """
  Helper for validating query params not associated with a model. 

  *Note:* Changesets are used to validate query params that are associated with a model.
  """
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload

  @doc """
  Used to validate/parse a incoming request parameters, into a positive integer or nil.

  Specify field name to customize error, leave blank for default
  `EpochtalkServerWeb.CustomErrors.InvalidPayload` exception.

  Will raise a `EpochtalkServerWeb.CustomErrors.InvalidPayload` exception if string
  is not a valid positive integer or nil.

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Validate
      iex> Validate.optional_pos_int("15", "page")
      15
      iex> Validate.optional_pos_int(nil, "limit")
      nil
      iex> Validate.optional_pos_int("1")
      1
      iex> Validate.optional_pos_int("hey", "count")
      ** (EpochtalkServerWeb.CustomErrors.InvalidPayload) Invalid payload, 'count' should be a positive integer or nil
  """
  @spec optional_pos_int(str :: String.t(), field :: String.t() | nil) :: integer | nil
  def optional_pos_int(str, field \\ nil)
  def optional_pos_int(nil, _), do: nil
  def optional_pos_int(str, field) do
    msg = "Invalid payload, '#{field}' should be a positive integer or nil"
    case Integer.parse(str) do
      {num, ""} -> if num > 0,
        do: num,
        else: (if field, do: raise(InvalidPayload, msg), else: raise(InvalidPayload))
      _ -> (if field, do: raise(InvalidPayload, msg), else: raise(InvalidPayload))
    end
  end
end
