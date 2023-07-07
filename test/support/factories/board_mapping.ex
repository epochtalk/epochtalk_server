defmodule Test.Support.Factories.BoardMapping do
  @moduledoc """
  Factory for `BoardMapping`

  Usage:
  BoardMapping.update([
    build(:board_mapping_attributes, ...),
    build(:board_mapping_attributes, ...),
    build(:board_mapping_attributes, ...)
  })
  """
  alias EpochtalkServer.Models.BoardMapping

  defmacro __using__(_opts) do
    quote do
      def board_mapping_attributes_factory(%{board: board, view_order: view_order, category: category}) do
        %{
          id: board.id,
          name: board.name,
          type: "board",
          category_id: category.id,
          view_order: view_order
        }
      end
      def board_mapping_attributes_factory(%{board: board, view_order: view_order, parent: parent}) do
        %{
          id: board.id,
          name: board.name,
          type: "board",
          board_id: parent.id,
          view_order: view_order
        }
      end
      def board_mapping_attributes_factory(%{category: category, view_order: view_order}) do
        %{
          id: category.id,
          name: category.name,
          type: "category",
          view_order: view_order
        }
      end
    end
  end
end
