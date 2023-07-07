defmodule Test.Support.Factories.Thread do
  @moduledoc """
  Factory for `Thread`
  """
  alias EpochtalkServer.Models.Thread

  defmacro __using__(_opts) do
    quote do
      def thread_attributes_factory(%{board: board} = attrs) do
        %{
          title: sequence(:thread_title, &"Thread title #{&1}"),
          body: sequence(:thread_body, &"Thread body #{&1}"),
          board_id: board.id,
          sticky: Map.get(attrs, :sticky) || false,
          locked: Map.get(attrs, :locked) || false,
          moderated: false,
          addPoll: false,
          pollValid: false,
          slug: sequence(:thread_slug, &"thread-slug-#{&1}")
        }
      end
    end
  end
end
