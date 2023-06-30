defmodule Test.Support.Factories.Board do
  alias EpochtalkServer.Models.Board
  defmacro __using__(_opts) do
    quote do
      def board_factory do
        %Board{
          name: sequence(:board_name, &"Board #{&1}"),
          description: "description",
          slug: sequence(:board_slug, &"board-slug-#{&1}"),
          meta: %{
            disable_self_mod: false,
            disable_post_edit: nil,
            disable_signature: false
          }
        }
      end
    end
  end
end
