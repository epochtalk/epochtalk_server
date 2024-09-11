defmodule EpochtalkServer.Models.TrustFeedback do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.User
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.TrustFeedback
  alias EpochtalkServer.Models.TrustMaxDepth

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
    field :created_at, :naive_datetime_usec
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
  @spec counts_by_user_id(
          user_id :: non_neg_integer,
          scammer :: boolean,
          trusted :: [non_neg_integer],
          created_at :: NaiveDateTime.t() | nil
        ) ::
          max_depth :: non_neg_integer
  def counts_by_user_id(user_id, scammer, trusted, created_at \\ nil) do
    query =
      TrustFeedback
      |> select([t], count(fragment("distinct ?", t.reporter_id)))

    query =
      if is_nil(created_at) do
        where(
          query,
          [t],
          t.user_id == ^user_id and t.scammer == ^scammer and t.reporter_id in ^trusted
        )
      else
        where(
          query,
          [t],
          t.user_id == ^user_id and t.scammer == ^scammer and t.created_at >= ^created_at and
            t.reporter_id in ^trusted
        )
      end

    Repo.one(query)
  end

  @doc """
  Used to calculate the user's `Trust` score when that `User` has no negative  `TrustFeedback`
  """
  @spec calculate_score_when_no_negative_feedback(
          user_id :: non_neg_integer,
          trusted :: [non_neg_integer]
        ) ::
          score :: non_neg_integer
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

    Repo.one(query) || 0
  end

  @doc """
  Get `created_at` timestamp of the first negative `TrustFeedback` left for a specific `User` and trust network (array of `User` IDs)
  """
  @spec first_negative_feedback_timestamp_by_user_id(
          user_id :: non_neg_integer,
          trusted :: [non_neg_integer]
        ) ::
          created_at :: NaiveDateTime.t()
  def first_negative_feedback_timestamp_by_user_id(user_id, trusted) do
    query =
      from t in TrustFeedback,
        where: t.user_id == ^user_id and t.scammer == true and t.reporter_id in ^trusted,
        order_by: [asc: t.created_at],
        limit: 1,
        select: t.created_at

    Repo.one(query)
  end

  ## === Public Helper Functions ===

  @doc """
  Calculates `Trust` statistics using `TrustFeedback` left for a specific `User` and the authenticated users
  trust network (array of `User` IDs)
  """
  @spec statistics_by_user_id(
          user_id :: non_neg_integer,
          authed_user_id :: non_neg_integer,
          trusted :: [non_neg_integer] | nil
        ) :: %{neg: integer, pos: integer, score: integer}
  def statistics_by_user_id(user_id, authed_user_id, trusted \\ nil)

  def statistics_by_user_id(nil, _authed_user_id, _trusted), do: %{score: 0, pos: 0, neg: 0}

  def statistics_by_user_id(user_id, authed_user_id, trusted) do
    trusted =
      trusted ||
        Trust.sources_by_user_id(authed_user_id, TrustMaxDepth.by_user_id(authed_user_id))

    positive_count = TrustFeedback.counts_by_user_id(user_id, false, trusted)
    negative_count = TrustFeedback.counts_by_user_id(user_id, true, trusted)
    score = calculate_overall_score(user_id, trusted, positive_count, negative_count)

    %{
      score: score,
      pos: positive_count,
      neg: negative_count
    }
  end

  ## === Private Helper Functions ===

  defp calculate_overall_score(user_id, trusted, _positive_count, 0),
    do: TrustFeedback.calculate_score_when_no_negative_feedback(user_id, trusted)

  defp calculate_overall_score(user_id, trusted, positive_count, negative_count) do
    calculate_score_when_has_negative_feedback(user_id, trusted, positive_count, negative_count)
  end

  defp calculate_score_when_has_negative_feedback(
         user_id,
         trusted,
         positive_count,
         negative_count
       ) do
    score = positive_count - Integer.pow(2, negative_count)

    score =
      if score >= 0 do
        start_time = TrustFeedback.first_negative_feedback_timestamp_by_user_id(user_id, trusted)

        positive_count_since_start_time =
          TrustFeedback.counts_by_user_id(user_id, false, trusted, start_time)

        negative_count_since_start_time =
          TrustFeedback.counts_by_user_id(user_id, true, trusted, start_time)

        score = positive_count_since_start_time - negative_count_since_start_time
        if score < 0, do: "???", else: score
      else
        score
      end

    if score === "???", do: score, else: score |> min(9999) |> max(-9999)
  end
end
