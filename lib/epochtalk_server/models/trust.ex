defmodule EpochtalkServer.Models.Trust do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias EpochtalkServer.Repo
  alias EpochtalkServer.Models.Trust
  alias EpochtalkServer.Models.User

  @moduledoc """
  `Trust` model, for performing actions relating to `Trust`
  """
  @type t :: %__MODULE__{
    user_id: non_neg_integer | nil,
    user_id_trusted: non_neg_integer | nil,
    type: non_neg_integer | nil
  }
  @derive {Jason.Encoder, only: [:user_id, :user_id_trusted, :type]}
  @primary_key false
  schema "trust" do
    belongs_to :user, User
    belongs_to :trusted_user_id, User, foreign_key: :user_id_trusted
    field :type, :integer
  end

  ## === Changesets Functions ===

  @doc """
  Generic changeset for `Trust` model
  """
  @spec changeset(
          trust :: t(),
          attrs :: map() | nil
        ) :: Ecto.Changeset.t()
  def changeset(trust, attrs \\ %{}) do
    trust
    |> cast(attrs, [:user_id, :user_id_trusted, :type])
    |> validate_required([:user_id, :user_id_trusted, :type])
  end

  ## === Database Functions ===

  @doc """
  Query all `Trust` models
  """
  @spec trust_by_user_ids(trusted :: [non_neg_integer]) :: [Ecto.Changeset.t()]
  def trust_by_user_ids(trusted) do
    query =
      from t in Trust,
      where: t.user_id in ^trusted

    Repo.all(query)
  end

  ## === Public Helper Functions ===

  def trust_sources_by_user_id(user_id, max_depth, debug) do
    depth = 0..max_depth - 1 |> Enum.to_list()
    %{sources: sources, untrusted: untrusted, last: last, debug: debug} =
      Enum.reduce(depth, %{sources: [], untrusted: %{}, last: [user_id], debug: debug}, fn i, acc ->
        debug = if acc.debug, do: Map.put(acc.debug, i, [])

        if length(last) == 0 do
          # do nothing
          acc
        else
          trust_info = trust_by_user_ids(last)

          votes = Enum.reduce(length(trust_info), %{}, fn x, acc ->
            cur = Enum.at(trust_info, x)
            cur_id = cur.user_id_trusted
            acc = if is_nil(acc[cur_id]), do: Map.put(acc, cur_id, 0), else: acc
            if cur.type == 1,
              do: Map.put(acc, cur_id, acc[cur_id] - 1),
              else: Map.put(acc, cur_id, acc[cur_id] + 1)
          end)

          %{sources: sources, untrusted: untrusted, last: last, debug: debug} =
            Enum.reduce(length(trust_info), %{sources: acc.sources, untrusted: acc.untrusted, last: acc.last, debug: debug}, fn y, acc ->
              cur_id = Enum.at(trust_info, y).user_id_trusted
              cur_votes = votes[cur_id]
            end)

          %{
            sources: sources,
            untrusted: untrusted,
            last: last,
            debug: debug
          }
        end
      end)
  end
end
