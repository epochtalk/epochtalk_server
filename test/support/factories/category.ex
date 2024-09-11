defmodule Test.Support.Factories.Category do
  @moduledoc """
  Factory for `Category`
  """
  alias EpochtalkServer.Models.Category

  defmacro __using__(_opts) do
    quote do
      def category_attributes_factory(attrs) do
        %{
          name: Map.get(attrs, :name) || sequence(:category_name, &"Category #{&1}"),
          view_order: Map.get(attrs, :view_order) || nil,
          viewable_by: Map.get(attrs, :viewable_by) || nil,
          postable_by: Map.get(attrs, :viewable_by) || nil
        }
      end

      def category_factory(attrs \\ %{}) do
        attributes = build(:category_attributes, attrs)

        case Category.create(attributes) do
          {:ok, category} -> category
        end
      end
    end
  end
end
