defmodule EpochtalkServer.Models.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Invitation

  @primary_key false
  schema "invitations" do
    field :email, :string
    field :hash, :string
    field :created_at, :naive_datetime
  end

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

  def create(email), do: Repo.insert(create_changeset(%Invitation{}, %{email: email}))
  def delete(email), do: Repo.delete_all(from(i in Invitation, where: i.email == ^email))
end
