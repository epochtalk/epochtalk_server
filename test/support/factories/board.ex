defmodule Test.Support.Factories.Board do
  @moduledoc """
  Factory for `Board`
  """
  alias EpochtalkServer.Models.Board

  defmacro __using__(_opts) do
    quote do
      def board_attributes_factory(attrs) do
        %{
          name: Map.get(attrs, :name) || sequence(:board_name, &"Board #{&1}"),
          description: Map.get(attrs, :description) || "description",
          slug: Map.get(attrs, :slug) || sequence(:board_slug, &"board-slug-#{&1}"),
          viewable_by: Map.get(attrs, :viewable_by) || nil,
          postable_by: Map.get(attrs, :postable_by) || nil,
          right_to_left: Map.get(attrs, :right_to_left) || false,
          meta: %{
            "disable_self_mod" => Map.get(attrs, :disable_self_mod) || false,
            "disable_post_edit" => Map.get(attrs, :disable_post_edit) || nil,
            "disable_signature" => Map.get(attrs, :disable_signature) || false
          }
        }
      end

      def board_factory(attrs \\ %{}) do
        attributes = build(:board_attributes, attrs)

        case Board.create(attributes) do
          {:ok, board} -> board
        end
      end
    end
  end
end
