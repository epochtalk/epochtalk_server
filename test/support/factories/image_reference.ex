defmodule Test.Support.Factories.ImageReference do
  @moduledoc """
  Factory for `ImageReference`
  """

  defmacro __using__(_opts) do
    quote do
      def image_reference_attributes_factory(%{length: length, file_type: file_type}) do
        %{
          "length" => length,
          "file_type" => file_type
        }
      end
      def image_reference_attributes_factory(attrs) do
        attrs
        |> Enum.reduce([], fn {length, file_type}, acc ->
          [image_reference_attributes_factory(%{length: length, file_type: file_type}) | acc]
        end)
      end
    end
  end
end
