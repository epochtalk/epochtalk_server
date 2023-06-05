defmodule EpochtalkServer.Models.Poll do
  use Ecto.Schema
  import Ecto.Changeset
  import EpochtalkServer.Validators.NaiveDateTime
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.Thread

  @moduledoc """
  `Poll` model, for performing actions relating to `Thread` polls
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          thread_id: non_neg_integer | nil,
          question: String.t() | nil,
          locked: boolean | nil,
          max_answers: non_neg_integer | nil,
          expiration: NaiveDateTime.t() | nil,
          change_vote: boolean | nil,
          display_mode: String.t() | nil
        }
  @derive {Jason.Encoder,
           only: [
             :thread_id,
             :question,
             :locked,
             :max_answers,
             :expiration,
             :change_vote,
             :display_mode
           ]}
  schema "polls" do
    belongs_to :thread, Thread
    field :question, :string
    field :locked, :boolean
    field :max_answers, :integer
    field :expiration, :naive_datetime
    field :change_vote, :boolean
    field :display_mode, Ecto.Enum, values: [:always, :voted, :expired]
    has_many :poll_answers, PollAnswer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Poll` model
  """
  @spec changeset(
          poll :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll, attrs \\ %{}) do
    poll
    |> cast(attrs, [
      :id,
      :thread_id,
      :question,
      :locked,
      :max_answers,
      :expiration,
      :change_vote,
      :display_mode
    ])
    |> validate_required([
      :thread_id,
      :question,
      :locked,
      :max_answers,
      :change_vote,
      :display_mode
    ])
  end

  @doc """
  Create changeset for `Poll` model
  """
  @spec create_changeset(
          poll :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def create_changeset(poll, attrs \\ %{}) do
    poll =
      poll
      |> Map.put(:max_answers, 1)
      |> Map.put(:change_vote, false)

    poll_answers = attrs["answers"]
    poll_answers_len = length(poll_answers || [])

    poll_cs =
      poll
      |> cast(attrs, [
        :thread_id,
        :question,
        :max_answers,
        :expiration,
        :change_vote,
        :display_mode
      ])
      |> validate_required([
        :thread_id,
        :question,
        :max_answers,
        :change_vote,
        :display_mode
      ])
      |> validate_naivedatetime(:expiration, after: :utc_now)
      |> validate_number(:max_answers, greater_than: 0, less_than_or_equal_to: poll_answers_len)
      |> validate_length(:question, min: 1, max: 255)
      |> unique_constraint(:id, name: :polls_pkey)
      |> unique_constraint(:thread_id, name: :polls_thread_id_index)
      |> foreign_key_constraint(:thread_id, name: :polls_thread_id_fkey)

    # validate answers
    if poll_answers_len > 0, do: poll_cs, else: add_error(poll_cs, :answers, "can't be blank")
  end

  @doc """
  Creates a new `Poll` in the database
  """
  @spec create(post_attrs :: map()) :: {:ok, post :: t()} | {:error, Ecto.Changeset.t()}
  def create(poll_attrs) do
    Repo.transaction(fn ->
      post_cs = create_changeset(%Poll{}, poll_attrs)

      case Repo.insert(post_cs) do
        {:ok, db_poll} ->
          # iterate over each answer, create answer in db
          Enum.each(poll_attrs["answers"], fn answer ->
            poll_answer_attrs = %{"poll_id" => db_poll.id, "answer" => answer}
            PollAnswer.create(poll_answer_attrs)
          end)

          db_poll

        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
  end

  @doc """
  Queries `Poll` Data by thread
  """
  def by_thread(thread_id) do
    query =
      from p in Poll,
      where: p.thread_id == ^thread_id,
      preload: [poll_answers: :poll_responses]
    Repo.one(query)
  end
end
