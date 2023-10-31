defmodule Test.EpochtalkServerWeb.Helpers.Validate do
  use Test.Support.ConnCase, async: true
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.CustomErrors.InvalidPayload
  doctest Validate

  describe "mutually_exclusive/2" do
    test "given cases, returns correct result" do
      cases = [
        %{
          attrs: %{"page" => 1},
          keys: ["page", "start"],
          result: :ok
        },
        %{
          attrs: %{"start" => 1},
          keys: ["page", "start"],
          result: :ok
        },
        %{
          attrs: %{"start" => 1},
          keys: ["start"],
          result: :ok
        },
        %{
          attrs: %{"page" => 1, "start" => 1},
          keys: ["page", "start"],
          result: :error
        },
        %{
          attrs: %{"page" => 1, "start" => 1, "stop" => 1},
          keys: ["page", "start"],
          result: :error
        },
        %{
          attrs: %{"page" => 1, "stop" => 1},
          keys: ["page", "start", "stop", "enter"],
          result: :error
        }
      ]

      cases
      |> Enum.each(fn
        %{attrs: attrs, keys: keys, result: :error} ->
          assert_raise InvalidPayload,
                       ~r/^The following payload parameters cannot be passed at the same time:/,
                       fn ->
                         Validate.mutually_exclusive!(attrs, keys)
                       end

        %{attrs: attrs, keys: keys, result: :ok} ->
          assert Validate.mutually_exclusive!(attrs, keys) == :ok
      end)
    end
  end
end
