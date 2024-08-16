defmodule Test.Support.Factories.Thread do
  @moduledoc """
  Factory for `Thread`
  """
  alias EpochtalkServer.Models.Thread
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Repo

  defmacro __using__(_opts) do
    quote do
      def thread_attributes_factory(%{board: board} = attrs) do
        %{
          "title" => Map.get(attrs, :title) || sequence(:thread_title, &"Thread title #{&1}"),
          "body" => sequence(:thread_body, &"Thread body #{&1}"),
          "board_id" => board.id,
          "sticky" => Map.get(attrs, :sticky) || false,
          "locked" => Map.get(attrs, :locked) || false,
          "moderated" => false,
          "poll" => Map.get(attrs, :poll),
          "slug" => Map.get(attrs, :slug) || sequence(:thread_slug, &"thread-slug-#{&1}")
        }
      end

      def thread_factory(%{user: user} = attrs) do
        attributes = build(:thread_attributes, attrs)

        Thread.create(attributes, user)
        |> case do
          {:ok, thread} ->
            thread_id = thread.post.thread.id
            thread_title = thread.post.thread.title
            thread = thread |> Map.put(:attributes, attributes)

            thread = if thread.poll == nil,
              do: thread,
              else:
                if(thread.poll.poll_answers,
                  do: Map.put(thread, :poll, thread.poll |> Repo.preload(:poll_answers)),
                  else: thread
                )

            if attrs[:num_replies],
              do: Enum.each(1..attrs[:num_replies], fn _index ->
                Post.create(%{user_id: user.id, thread_id: thread_id, content: %{title: "RE: #{thread_title}", body: "Thread reply"}})
              end)

            thread
        end
      end

    end
  end
end
