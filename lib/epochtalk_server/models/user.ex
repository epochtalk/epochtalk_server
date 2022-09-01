defmodule EpochtalkServer.Model.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Model.User

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :passhash, :string
    field :confirmation_token, :string
    field :reset_token, :string
    field :reset_expiration, :string

    field :created_at, :naive_datetime
    field :imported_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :deleted, :boolean, default: false
    field :malicious_score, :integer

    field :smf_member, :map, virtual: true
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :email, :username, :created_at, :updated_at, :deleted, :malicious_score, :password])
    |> unique_constraint(:id, name: :users_pkey)
    |> validate_username()
    |> validate_email()
    |> validate_password()
  end

  def with_username_exists?(username) do
    query = from u in User,
      where: u.username == ^username

    Repo.exists?(query)
  end
  def with_email_exists?(email) do
    query = from u in User,
      where: u.email == ^email

    Repo.exists?(query)
  end
  def by_id(id)
      when is_integer(id) do
    Repo.get_by(User, id: id)
  end
  def by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if User.valid_password?(user, password), do: user
  end
  def valid_password?(%EpochtalkServer.Model.User{passhash: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end
  defp validate_username(changeset) do
    changeset
    |> validate_required(:username)
    |> unique_constraint(:username)
  end
  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, EpochtalkServer.Repo)
    |> unique_constraint(:email)
  end
  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    # check that password matches password_confirmation
    #   checks that password and password_confirmation match
    #   but does not require password_confirmation to be supplied
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_length(:password, min: 8, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> hash_password()
  end
  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:passhash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
