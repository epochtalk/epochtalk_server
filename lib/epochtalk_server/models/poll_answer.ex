defmodule EpochtalkServer.Models.PollAnswer do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  # alias EpochtalkServer.Repo
  # alias EpochtalkServer.Models.PollAnswer
  alias EpochtalkServer.Models.Poll

  @moduledoc """
  `PollAnswer` model, for performing actions relating to `Poll` answers
  """
  @type t :: %__MODULE__{
          id: non_neg_integer | nil,
          poll_id: non_neg_integer | nil,
          answer: String.t() | nil
        }
  @derive {Jason.Encoder, only: [:poll_id, :answer]}
  schema "poll_answers" do
    belongs_to :poll, Poll
    field :answer, :string
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `PollAnswer` model
  """
  @spec changeset(
          poll :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(poll, attrs \\ %{}) do
    poll
    |> cast(attrs, [:id, :poll_id, :answer])
    |> validate_required([:poll_id, :answer])
  end
end
