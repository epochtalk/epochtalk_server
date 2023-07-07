defmodule Test.Support.Factories.Thread do
  @moduledoc """
  Factory for `Thread`
  """
  alias EpochtalkServer.Models.Thread

  defmacro __using__(_opts) do
    quote do
      def thread_factory do
        %Thread{
          # title: sequence(:thread_title, &"Thread title #{&1}"),
          # body: sequence(:thread_body, &"Thread body #{&1}"),
          board_id: insert(:board).id,
          locked: false,
          sticky: false,
          slug: sequence(:thread_slug, &"thread-slug-#{&1}"),
          moderated: false
        }
      end
      def sticky_thread_factory do
        struct!(
          thread_factory(),
          %{
            sticky: true
          }
        )
      end
      def locked_thread_factory do
        struct!(
          thread_factory(),
          %{
            locked: true
          }
        )
      end
    end
  end
end
