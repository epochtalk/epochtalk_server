defmodule EpochtalkServer.Models.UserIgnored do
  use Ecto.Schema
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.UserIgnored

  @moduledoc """
  `UserIgnored` model, for performing actions relating to `UserIgnored`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          ignored_user_id: non_neg_integer | nil,
          created_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :ignored_user_id,
             :created_at
           ]}
  @schema_prefix "users"
  @primary_key false
  schema "ignored" do
    belongs_to :user, User
    belongs_to :ignored_user, User
    field :created_at, :naive_datetime
  end
end
