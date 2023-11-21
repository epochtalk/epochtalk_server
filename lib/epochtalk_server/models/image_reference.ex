defmodule EpochtalkServer.Models.ImageReference do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Post
  alias EpochtalkServer.Models.Message

  @moduledoc """
  `ImageReference` model, for tracking images uploaded locally or to CDN
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          uuid: String.t() | nil,
          url: String.t() | nil,
          length: non_neg_integer | nil,
          type: String.t() | nil,
          checksum: String.t() | nil,
          expiration: NaiveDateTime.t() | nil,
          user: User.t() | term(),
          post: Post.t() | term(),
          message: Message.t() | term(),
          created_at: NaiveDateTime.t() | nil
        }
  schema "image_references" do
    field :id, :integer
    field :uuid, :string
    field :url, :string
    field :length, :integer
    field :type, :string
    field :checksum, :string
    field :expiration, :naive_datetime
    field :created_at, :naive_datetime
    many_to_many :user, User
    many_to_many :post, Post
    many_to_many :message, Message
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `ImageReference` model
  """
  @spec changeset(
          image_reference :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(image_reference, attrs) do
    image_reference
    |> cast(attrs, [
      :id,
      :uuid,
      :url,
      :length,
      :type,
      :checksum,
      :expiration,
      :created_at,
      :user,
      :post,
      :message
    ])
    |> cast_assoc(:user)
    |> cast_assoc(:post)
    |> cast_assoc(:message)
  end
end
