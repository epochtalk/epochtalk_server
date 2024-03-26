defmodule EpochtalkServer.Models.Poll do
  use Ecto.Schema
  import Ecto.Changeset
  import EpochtalkServer.Validators.NaiveDateTime
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Poll
  alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.PollResponse
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
             :id,
             :question,
             :locked,
             :max_answers,
             :expiration,
             :change_vote,
             :has_voted,
             :answers,
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
    field :has_voted, :boolean, virtual: true
    field :answers, {:array, :map}, virtual: true
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
      |> validate_display_mode()
      |> unique_constraint(:id, name: :polls_pkey)
      |> unique_constraint(:thread_id, name: :polls_thread_id_index)
      |> foreign_key_constraint(:thread_id, name: :polls_thread_id_fkey)

    # validate answers
    if poll_answers_len > 0, do: poll_cs, else: add_error(poll_cs, :answers, "can't be blank")
  end

  @doc """
  Update changeset for `Poll` model
  """
  @spec update_changeset(
          poll :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def update_changeset(poll, attrs \\ %{}) do
    poll_answers_len = length(poll.poll_answers || [])

    poll
    |> cast(attrs, [
      :max_answers,
      :expiration,
      :change_vote,
      :display_mode
    ])
    |> validate_required([
      :max_answers,
      :change_vote,
      :display_mode
    ])
    |> validate_naivedatetime(:expiration, after: :utc_now)
    |> validate_number(:max_answers, greater_than: 0, less_than_or_equal_to: poll_answers_len)
    |> validate_length(:question, min: 1, max: 255)
    |> validate_display_mode()
  end

  @doc """
  Creates a new `Poll` in the database
  """
  @spec create(poll_attrs :: map()) :: {:ok, poll :: t()} | {:error, Ecto.Changeset.t()}
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
  Updates an existing `Poll` in the database
  """
  @spec update(poll_attrs :: map()) ::
          {:ok, poll :: t()} | {:error, Ecto.Changeset.t()}
  def update(attrs) do
    Poll
    |> Repo.get(attrs["id"])
    |> Repo.preload([:poll_answers])
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns boolean indicating if the specified `User` has voted on the specified `Thread`
  """
  @spec has_voted(thread_id :: integer, user_id :: integer) :: boolean
  def has_voted(thread_id, user_id) do
    query =
      from p in Poll,
        left_join: pr in PollResponse,
        on: true,
        left_join: pa in PollAnswer,
        on: true,
        where:
          p.id == pa.poll_id and pr.answer_id == pa.id and p.thread_id == ^thread_id and
            pr.user_id == ^user_id,
        select: pr.user_id

    Repo.exists?(query)
  end

  @doc """
  Returns boolean indicating if the specified `Poll` exists given a `Thread` id
  """
  @spec exists_by_thread_id(thread_id :: integer) :: boolean
  def exists_by_thread_id(thread_id) do
    query =
      from p in Poll,
        where: p.thread_id == ^thread_id,
        select: p.id

    Repo.exists?(query)
  end

  @doc """
  Returns boolean indicating if the specified `Poll` is locked given a `Thread` id
  """
  @spec locked_by_thread_id(thread_id :: integer) :: boolean
  def locked_by_thread_id(thread_id) do
    query =
      from p in Poll,
        where: p.thread_id == ^thread_id,
        select: p.locked

    Repo.one(query)
  end

  @doc """
  Returns boolean indicating if the specified `Poll` is currently running given a `Thread` id
  """
  @spec running_by_thread_id(thread_id :: integer) :: boolean
  def running_by_thread_id(thread_id) do
    query =
      from p in Poll,
        where: p.thread_id == ^thread_id,
        select: p.expiration

    expiration = Repo.one(query)
    if expiration == nil,
      do: true,
      else: NaiveDateTime.compare(expiration, NaiveDateTime.utc_now()) == :gt
  end

  @doc """
  Queries `Poll` Data by thread
  """
  @spec by_thread(thread_id :: integer) :: t() | nil
  def by_thread(thread_id) do
    query =
      from p in Poll,
        where: p.thread_id == ^thread_id,
        preload: [poll_answers: :poll_responses]

    Repo.one(query)
  end

  # var q = 'UPDATE polls SET (max_answers, change_vote, expiration, display_mode) = ($1, $2, $3, $4) WHERE id = $5';

  # === Private Helper Functions ===

  defp validate_display_mode(changeset) do
    expiration = get_field(changeset, :expiration)
    display_mode = get_field(changeset, :display_mode)

    if display_mode == :expired && expiration == nil,
      do:
        add_error(
          changeset,
          :display_mode,
          "set to 'expired' requires that the poll has an expiration"
        ),
      else: changeset
  end
end
