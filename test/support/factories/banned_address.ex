defmodule Test.Support.Factories.BannedAddress do
  @moduledoc """
  Factory for `BannedAddress`

  Usage:
  build(:banned_address, ip: ip, weight: weight)
  OR
  build(:banned_address, hostname: hostname, weight: weight)
  """
  alias EpochtalkServer.Models.BannedAddress

  defmacro __using__(_opts) do
    quote do
      def banned_address_factory(attributes), do: BannedAddress.upsert(attributes)
    end
  end
end
