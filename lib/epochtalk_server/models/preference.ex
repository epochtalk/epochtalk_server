defmodule EpochtalkServer.Models.Preference do
  use Ecto.Schema
  import Ecto.Changeset
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Profile

  @primary_key false
  @schema_prefix "users"
  schema "preference" do
    belongs_to :user_id, User, foreign_key: :id, type: :integer
    field :posts_per_page, :integer
    field :threads_per_page, :integer
    field :collapsed_categories, :map
    field :ignored_boards, :map
    field :timezone_offset, :string
    field :notify_replied_threads, :boolean
    field :ignore_newbies, :boolean
    field :patroller_view, :boolean
    field :email_mentions, :boolean
    field :email_messages, :boolean
  end

  def changeset(permission, attrs \\ %{}) do
    permission
    |> cast(attrs, [:user_id, :posts_per_page, :threads_per_page,
      :collapsed_categories, :ignored_boards, :timezone_offset,
      :notify_replied_threads, :ignore_newbies, :patroller_view,
      :email_mentions, :email_messages])
    |> validate_required([:user_id])
  end
end
