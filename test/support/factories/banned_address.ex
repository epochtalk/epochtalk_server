defmodule Test.Support.Factories.BannedAddress do
  @moduledoc """
  Factory for `BannedAddress`

  Usage:
  build(:banned_address, ip: ip, weight: weight)
  OR
  build(:banned_address, hostname: hostname, weight: weight)
  """
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.BannedAddress

  defmacro __using__(_opts) do
    quote do
      def banned_address_attributes_factory(%{ip: ip, weight: weight}) do
        %{
          ip: ip,
          weight: weight,
          created_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          imported_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end

      def banned_address_attributes_factory(%{hostname: hostname, weight: weight}) do
        %{
          hostname: hostname,
          weight: weight,
          created_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          imported_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end

      def banned_address_factory(attributes) do
        %BannedAddress{}
        |> BannedAddress.upsert_changeset(build(:banned_address_attributes, attributes))
        |> Repo.insert()
      end
    end
  end
end
