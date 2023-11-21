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
          uid: String.t() | nil,
          url: String.t() | nil,
          length: non_neg_integer | nil,
          type: String.t() | nil,
          checksum: String.t() | nil,
          expiration: NaiveDateTime.t() | nil,
          confirmed: boolean | false,
          user: User.t() | term(),
          post: Post.t() | term(),
          message: Message.t() | term(),
          created_at: NaiveDateTime.t() | nil
        }
  schema "image_references" do
    field :id, :integer
    field :uid, :string
    field :url, :string
    field :length, :integer
    field :type, :string
    field :checksum, :string
    field :expiration, :naive_datetime
    field :confirmed, :boolean, default: false
    field :created_at, :naive_datetime
    many_to_many :user, User
    many_to_many :post, Post
    many_to_many :message, Message
  end
end
