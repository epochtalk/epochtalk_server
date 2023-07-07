defmodule Test.Support.Factories.Category do
  @moduledoc """
  Factory for `Category`
  """
  alias EpochtalkServer.Models.Category

  defmacro __using__(_opts) do
    quote do
      def category_factory do
        %Category{
          name: sequence(:category_name, &"Category #{&1}")
        }
      end
    end
  end
end
