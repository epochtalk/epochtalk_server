defmodule EpochtalkServerWeb.Helpers.Validate do
  @moduledoc """
  Helper for validating and casting query parameters not associated with a model.

  *Note:* Changesets are used to validate query parameters that are associated with a model.
  """
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload

  @doc """
  Helper used to validate and cast request parameters directly out of the incoming
  paylod map (usually a controller function's `attrs` parameter) to the specified type.
  Will raise an `EpochtalkServerWeb.CustomErrors.InvalidPayload` exception if map value does
  not pass validation and casting.

  ### Valid Types
  | type       | supported options                   |
  | ---------- | ----------------------------------- |
  | `:integer` | `:required`, `:key`, `:min`, `:max` |
  | `:boolean` | `:required`, `:key`                 |

  ### Valid Options
  | option      | description                                       |
  | ----------- | ------------------------------------------------- |
  | `:required` | `true` will raise an exception if casting nil     |
  | `:min`      | `min` of value being cast to `:integer`           |
  | `:max`      | `max` of value being cast to `:integer`           |

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Validate
      iex> attrs = %{"page" => "42", "extended" => "true", "debug" => "false"}
      iex> Validate.cast(attrs, "page", :integer, min: 1, max: 99, required: true)
      42
      iex> Validate.cast(attrs, "limit", :integer, min: 1)
      nil
      iex> Validate.cast(attrs, "debug", :boolean)
      false
      iex> Validate.cast(attrs, "extended", :unsupported) # returns input if type not supported
      "true"
      iex> Validate.cast(attrs, "post_count", :integer, required: true)
      ** (EpochtalkServerWeb.CustomErrors.InvalidPayload) Invalid payload, key 'post_count' should be of type 'integer'
  """
  @spec cast(attrs :: map, key :: String.t(), type :: atom, required: boolean, min: integer, max: integer) :: any()
  def cast(attrs, key, type, opts \\ []) when is_map(attrs) and is_binary(key) and is_atom(type) and is_list(opts),
    do: (if is_nil(attrs[key]), do: nil, else: "#{attrs[key]}") |> cast_str(type, opts ++ [key: key])

  @doc """
  Helper used to validate and cast request parameters. Takes in a `String.t()` and casts it
  to the specified type. Will raise an `EpochtalkServerWeb.CustomErrors.InvalidPayload`
  exception if string does not pass validation and casting.

  ### Valid Types
  | type       | supported options                   |
  | ---------- | ----------------------------------- |
  | `:integer` | `:required`, `:key`, `:min`, `:max` |
  | `:boolean` | `:required`, `:key`                 |

  ### Valid Options
  | option      | description                                       |
  | ----------- | ------------------------------------------------- |
  | `:key`      | reference name of the value attempting to be cast |
  | `:required` | `true` will raise an exception if casting nil     |
  | `:min`      | `min` of value being cast to `:integer`           |
  | `:max`      | `max` of value being cast to `:integer`           |

  ## Example
      iex> alias EpochtalkServerWeb.Helpers.Validate
      iex> Validate.cast_str("15", :integer, key: "page", min: 1, max: 99, required: true)
      15
      iex> Validate.cast_str(nil, :integer, key: "limit", min: 1)
      nil
      iex> Validate.cast_str("false", :boolean)
      false
      iex> Validate.cast_str("true", :unsupported) # returns input if type not supported
      "true"
      iex> Validate.cast_str(nil, :integer, key: "post_count", required: true)
      ** (EpochtalkServerWeb.CustomErrors.InvalidPayload) Invalid payload, key 'post_count' should be of type 'integer'
  """
  @spec cast_str(str :: String.t(), type :: atom, key: String.t(), required: boolean, min: integer, max: integer) :: any()
  def cast_str(str, type, opts \\ [])
  def cast_str(nil, type, opts) when is_atom(type) and is_list(opts), # if nil and required, raise
    do: (if opts[:required], do: raise(InvalidPayload, opts ++ [type: type]), else: nil)
  def cast_str("", type, opts) when is_atom(type), # cannot cast empty string, raise
    do: raise(InvalidPayload, opts ++ [type: type])
  def cast_str(str, type, opts) when is_binary(str) and is_atom(type) and is_list(opts) do
    opts = opts ++ [type: type] # add type to opts so InvalidPayload raise has metadata
    case type do
      :integer -> cast_to_int(str, opts)
      :boolean -> cast_to_bool(str, opts)
      _ -> str # type not supported, return string
    end
  end

  defp cast_to_int(str, opts) do
    case Integer.parse(str) do
      {num, ""} ->
        min = !!opts[:min]
        max = !!opts[:max]
        if min or max,
          do: (valid_min = min and !max and num >= opts[:min]
            valid_max = max and !min and num <= opts[:max]
            valid_range = max and min and num <= opts[:max] and num >= opts[:min]
            if valid_range or valid_max or valid_min, do: num, else: raise(InvalidPayload, opts)),
        else: num
      _ -> raise(InvalidPayload, opts)
    end
  end

  defp cast_to_bool(str, opts) do
    case str do
      "true" -> true
      "false" -> false
      "1" -> true # not necessary, but can support js frontends and harms nothing
      "0" -> false
      _ -> raise(InvalidPayload, opts)
    end
  end
end
