defmodule EpochtalkServer.Models.PostDraft do
  use Ecto.Schema
  # alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User

  @moduledoc """
  `PostDraft` model, for performing actions relating to a `User`'s `Post` draft
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          draft: String.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :draft,
             :updated_at
           ]}
  @schema_prefix "posts"
  @primary_key false
  schema "user_drafts" do
    belongs_to :user, User
    field :draft, :string
    field :updated_at, :naive_datetime
  end

  ## === Database Functions ===
end
