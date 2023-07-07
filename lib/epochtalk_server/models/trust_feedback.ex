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
  Get count of postivie or negative `TrustFeedback` a specific `User` and trust network (array of `User` IDs)
  """
  @spec counts_by_user_id(user_id :: non_neg_integer, scammer :: boolean, trusted :: [], created_at :: NaiveDateTime.t() | nil) ::
          {:ok, max_depth :: non_neg_integer | nil}
  def counts_by_user_id(user_id, scammer, trusted, created_at \\ nil) do
    query =
      TrustFeedback
      |> select([t], count(fragment("distinct ?", t.reporter_id)))

    query = if is_nil(created_at) do
      where(query, [t], t.user_id == ^user_id and t.scammer == ^scammer and t.reporter_id in ^trusted)
    else
      where(query, [t], t.user_id == ^user_id and t.scammer == ^scammer and t.created_at >= ^created_at and t.reporter_id in ^trusted)
    end

    {:ok, Repo.one(query)}
  end

  @doc """
  Used to calculate the user's `Trust` score when that `User` has no negative  `TrustFeedback`
  """
  @spec calculate_score_when_no_negative_feedback(user_id :: non_neg_integer, trusted :: []) ::
          {:ok, score :: non_neg_integer | nil}
  def calculate_score_when_no_negative_feedback(user_id, trusted) do
    inner_most_subquery =
      from t3 in TrustFeedback,
        where: t3.user_id == ^user_id and t3.scammer == false and t3.reporter_id in ^trusted,
        group_by: t3.reporter_id,
        select: %{created_at: min(t3.created_at), reporter_id: t3.reporter_id}

    inner_subquery =
      from t2 in TrustFeedback,
        join: g in subquery(inner_most_subquery),
        on: t2.created_at == g.created_at and t2.reporter_id == g.reporter_id,
        select: %{id: t2.id, created_at: g.created_at, reporter_id: g.reporter_id}

    query =
      from t in TrustFeedback,
        join: i in subquery(inner_subquery),
        on: t.id == i.id,
        select:
          fragment(
            "FLOOR(SUM(LEAST(10,date_part('epoch', (now()-?)/(60*60*24*30))::int)))",
            i.created_at
          )

    {:ok, Repo.one(query)}
  end

  @doc """
  Get timestamp of the first negative `TrustFeedback` left for a specific `User` and trust network (array of `User` IDs)
  """
  @spec first_negative_feedback_timestamp_by_user_id(user_id :: non_neg_integer, trusted :: []) ::
          {:ok, timestamp :: NaiveDateTime.t() | nil}
  def first_negative_feedback_timestamp_by_user_id(user_id, trusted) do
    query =
      from t in TrustFeedback,
        where: t.user_id == ^user_id and t.scammer == true and t.reporter_id in ^trusted,
        order_by: [asc: t.created_at],
        limit: 1,
        select: t.created_at

    {:ok, Repo.one(query)}
  end
end
