defmodule EpochtalkServer.Models.UserActivity do
  use Ecto.Schema
  alias EpochtalkServer.Models.User

  @moduledoc """
  `UserActivity` model, for performing actions relating to `User` `UserActivity`
  """
  @type t :: %__MODULE__{
          user_id: non_neg_integer | nil,
          current_period_start: NaiveDateTime.t() | nil,
          current_period_end: NaiveDateTime.t() | nil,
          remaining_period_activity: non_neg_integer | nil,
          total_activity: non_neg_integer | nil
        }
  @derive {Jason.Encoder,
           only: [
             :user_id,
             :current_period_start,
             :current_period_end,
             :remaining_period_activity,
             :total_activity
           ]}
  @primary_key false
  schema "user_activity" do
    belongs_to :user, User
    field :current_period_start, :naive_datetime
    field :current_period_end, :naive_datetime
    field :remaining_period_activity, :integer, default: 14
    field :total_activity, :integer, default: 0
  end

end
