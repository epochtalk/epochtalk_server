defmodule Test.Support.Factories.BoardMapping do
  @moduledoc """
  Factory for `BoardMapping`

  Usage:
  build(:board_mapping, attributes: [
    [attrs...],
    [attrs...],
    [attrs...]
  ])
  """
  alias EpochtalkServer.Models.BoardMapping

  defmacro __using__(_opts) do
    quote do
      # generate attributes for board under category
      def board_mapping_attributes_factory(%{
            board: board,
            view_order: view_order,
            category: category
          }) do
        %{
          id: board.id,
          name: board.name,
          type: "board",
          category_id: category.id,
          view_order: view_order
        }
      end

      # generate attributes for board under parent board
      def board_mapping_attributes_factory(%{
            board: board,
            view_order: view_order,
            parent: parent
          }) do
        %{
          id: board.id,
          name: board.name,
          type: "board",
          parent_id: parent.id,
          view_order: view_order
        }
      end

      # generate attributes for category
      def board_mapping_attributes_factory(%{category: category, view_order: view_order}) do
        %{
          id: category.id,
          name: category.name,
          type: "category",
          view_order: view_order
        }
      end

      def board_mapping_factory(%{attributes: attributes_list}) do
        attributes_list
        |> Enum.map(&build(:board_mapping_attributes, &1))
        |> BoardMapping.update()
      end
    end
  end
end
