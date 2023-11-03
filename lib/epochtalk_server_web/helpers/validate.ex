defmodule EpochtalkServerWeb.Helpers.Validate do
  @moduledoc """
  Helper for validating and casting query parameters not associated with a model.

  *Note:* Changesets are used to validate query parameters that are associated with a model.
  """
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload

  @doc """
  Ensure that `keys` provided in list are mutually exclusive within `attrs` map.
  """
  @spec mutually_exclusive!(attrs :: map, keys :: [String.t()]) :: :ok | no_return
  def mutually_exclusive!(attrs, keys) when is_map(attrs) and is_list(keys) do
    if map_contains_any_two_keys_in_list?(attrs, keys),
      do:
        raise(InvalidPayload,
          message:
            "The following payload parameters cannot be passed at the same time: #{Enum.join(keys, ", ")}"
        ),
      else: :ok
  end

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
  | option      | description                                         |
  | ----------- | --------------------------------------------------- |
  | `:required` | `true` will raise an exception if casting nil       |
  | `:default`  | default value for `attr` if not provided by request |
  | `:min`      | `min` of value being cast to `:integer`             |
  | `:max`      | `max` of value being cast to `:integer`             |

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
  @spec cast(attrs :: map, key :: String.t(), type :: atom,
          required: boolean,
          default: any,
          min: integer,
          max: integer
        ) :: any()
  def cast(attrs, key, type, opts \\ [])
      when is_map(attrs) and is_binary(key) and is_atom(type) and is_list(opts),
      do:
        if(is_nil(attrs[key]), do: nil, else: "#{attrs[key]}")
        |> cast_str(type, opts ++ [key: key])

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
  | option      | description                                         |
  | ----------- | --------------------------------------------------- |
  | `:key`      | reference name of the value attempting to be cast   |
  | `:required` | `true` will raise an exception if casting nil       |
  | `:default`  | default value for `attr` if not provided by request |
  | `:min`      | `min` of value being cast to `:integer`             |
  | `:max`      | `max` of value being cast to `:integer`             |

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
  @spec cast_str(str :: String.t(), type :: atom,
          key: String.t(),
          required: boolean,
          default: any,
          min: integer,
          max: integer
        ) :: any()
  def cast_str(str, type, opts \\ [])

  # if nil and required then raise or if default is provided return default
  def cast_str(nil, type, opts) when is_atom(type) and is_list(opts) do
    if !!opts[:required] and !opts[:default] do
      # required and no default
      raise(InvalidPayload, opts ++ [type: type])
    else
      # default exists, return default
      if opts[:default], do: opts[:default], else: nil
    end
  end

  # cannot cast empty string, raise
  def cast_str("", type, opts) when is_atom(type),
    do: raise(InvalidPayload, opts ++ [type: type])

  def cast_str(str, type, opts) when is_binary(str) and is_atom(type) and is_list(opts) do
    # add type to opts so InvalidPayload raise has metadata
    opts = opts ++ [type: type]

    case type do
      :boolean -> to_bool(str, opts)
      :integer -> to_int(str, opts)
      # type not supported, return string
      _ -> to_str(str, opts)
    end
  end

  # entrypoint
  defp map_contains_any_two_keys_in_list?(map, list),
    do: map_contains_any_two_keys_in_list?(map, list, false)

  # if map is empty, return false
  defp map_contains_any_two_keys_in_list?(map, _list, _key_found?) when map == %{}, do: false
  # if list is empty, return false
  defp map_contains_any_two_keys_in_list?(_map, [], _key_found?), do: false
  # if key_found? is false
  defp map_contains_any_two_keys_in_list?(map, [key | keys] = _list, false = _key_found?) do
    # check next key with updated key_found?
    map_contains_any_two_keys_in_list?(map, keys, Map.has_key?(map, key))
  end

  # if key_found? is true
  defp map_contains_any_two_keys_in_list?(map, [key | keys] = _list, true = key_found?) do
    # if current key is in map, return true
    if Map.has_key?(map, key),
      do: true,
      # otherwise, check next key
      else: map_contains_any_two_keys_in_list?(map, keys, key_found?)
  end

  defp to_bool(str, opts) do
    case str do
      "true" -> true
      "false" -> false
      # not necessary, but can support js frontends and harms nothing
      "1" -> true
      "0" -> false
      _ -> raise(InvalidPayload, opts)
    end
  end

  defp to_int(str, opts) do
    case Integer.parse(str) do
      {num, ""} -> validate_min_max_opts(num, opts)
      _ -> raise(InvalidPayload, opts)
    end
  end

  defp to_str(str, opts) do
    str_len = String.length(str)
    if str_len == validate_min_max_opts(str_len, opts), do: str
  end

  defp validate_min_max_opts(value, opts),
    do: validate_min_max_opts(value, opts[:min], opts[:max], opts)

  defp validate_min_max_opts(value, nil, nil, _opts), do: value
  defp validate_min_max_opts(value, min, max, _opts) when value >= min and value <= max, do: value
  defp validate_min_max_opts(value, min, nil, _opts) when value >= min, do: value
  defp validate_min_max_opts(value, nil, max, _opts) when value <= max, do: value
  defp validate_min_max_opts(_value, _min, _max, opts), do: raise(InvalidPayload, opts)
end
