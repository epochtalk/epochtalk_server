defmodule EpochtalkServer.Models.TrustFeedback do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.TrustFeedback

  @moduledoc """
  `TrustFeedback` model, for performing actions relating to `TrustFeedback`
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          user_id: non_neg_integer | nil,
          reporter_id: non_neg_integer | nil,
          risked_btc: float | nil,
          scammer: boolean | nil,
          reference: String.t() | nil,
          comments: String.t() | nil,
          created_at: NaiveDateTime.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :id,
             :user_id,
             :reporter_id,
             :risked_btc,
             :scammer,
             :reference,
             :comments,
             :created_at
           ]}
  schema "trust_feedback" do
    belongs_to :user, User
    belongs_to :reporter, User
    field :risked_btc, :float
    field :scammer, :boolean
    field :reference, :string
    field :comments, :string
    field :created_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `TrustFeedback` model
  """
  @spec changeset(
          trust_max_depth :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust_max_depth, attrs \\ %{}) do
    trust_max_depth
    |> cast(attrs, [
      :id,
      :user_id,
      :reporter_id,
      :risked_btc,
      :scammer,
      :reference,
      :comments,
      :created_at
    ])
    |> validate_required([
      :id,
      :user_id,
      :reporter_id,
      :risked_btc,
      :scammer,
      :reference,
      :comments,
      :created_at
    ])
  end

  @doc """
  Get count of postivie or negative `TrustFeedback` a specific `User`
  """
  @spec counts_by_user_id(user_id :: non_neg_integer, scammer :: boolean, reporters :: []) ::
          {:ok, max_depth :: non_neg_integer | nil}
  def counts_by_user_id(user_id, scammer, reporters) do
    query = from t in TrustFeedback,
      where: t.user_id == ^user_id and t.scammer == ^scammer and t.reporter_id in ^reporters,
      select: count(fragment("distinct ?", t.reporter_id))
    {:ok, Repo.one(query)}
  end
end
