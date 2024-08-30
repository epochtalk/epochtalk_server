defmodule Test.Support.Factories.Post do
  @moduledoc """
  Factory for `Post`
  """
  alias EpochtalkServer.Models.Post

  defmacro __using__(_opts) do
    quote do
      def post_attributes_factory(%{user: user, thread: thread} = attrs) do
        %{
          "user_id" => user.id,
          "thread_id" => thread.id,
          "content" => %{
            title: Map.get(attrs, :title) || sequence(:post_title, &"RE: Post title #{&1}"),
            body: sequence(:post_body, &"Post body #{&1}")
          }
        }
      end

      def post_factory(%{user: user, thread: thread} = attrs) do
        attributes = build(:post_attributes, attrs)

        timestamp =
          sequence(:post_timestamp, &NaiveDateTime.add(~N[1970-01-01 00:00:00], &1 * 60 * 60))

        Post.create_for_test(attributes, timestamp)
      end
    end
  end
end
