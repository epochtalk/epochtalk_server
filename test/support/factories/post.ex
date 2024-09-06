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

        Post.create(attributes)
      end
    end
  end
end
