defmodule EpochtalkServer.Models.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Invitation
  @moduledoc """
  `Invitation` model, for performing actions relating to inviting new users to the forum
  """

  @type t :: %__MODULE__{
    email: String.t(),
    hash: String.t(),
    created_at: NaiveDateTime.t()
  }
  @primary_key false
  schema "invitations" do
    field :email, :string
    field :hash, :string
    field :created_at, :naive_datetime
  end

  ## === Changesets Functions ===

  @doc """
  Create changeset for inserting a new `Invitation` model
  """
  @spec create_changeset(
    invitation :: t(),
    attrs :: %{} | nil
  ) :: t()
  def create_changeset(invitation, attrs \\ %{}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    attrs = attrs
    |> Map.put(:created_at, now)
    |> Map.put(:hash, Base.url_encode64(:crypto.strong_rand_bytes(20), padding: false))
    invitation
    |> cast(attrs, [:email, :hash, :created_at])
    |> validate_required([:email, :hash, :created_at])
    |> unique_constraint(:email, name: :invitations_email_index)
    |> check_constraint(:email,
        name: :invitations_email_check,
        message: "must be 255 characters or less"
      )
  end

  ## === Database Functions ===

  @doc """
  Creates a new `Invitation` in the database
  """
  @spec create(
    email :: String.t()
  ) :: {:ok, invitation :: t()} | {:error, Ecto.Changeset.t()}
  def create(email), do: Repo.insert(create_changeset(%Invitation{}, %{email: email}))

  @doc """
  Deletes `Invitation` from the database by email
  """
  @spec delete(
    email :: String.t()
  ) :: {non_neg_integer(), nil | [term()]}
  def delete(email), do: Repo.delete_all(from(i in Invitation, where: i.email == ^email))
end
