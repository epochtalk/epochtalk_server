defmodule EpochtalkServerWeb.Controllers.PollJSON do
  @moduledoc """
  Renders and formats `Poll` data, in JSON format for frontend
  """

  @doc """
  Renders `Poll` data for vote, delete and create.

    ## Example
    iex> poll = %{
    iex>   thread_id: 99,
    iex>   id: 1,
    iex>   question: "Is this a test?",
    iex>   poll_answers: [%{id: 3, answer: "yes", poll_responses: [%{}, %{}]}, %{id: 4, answer: "no", poll_responses: [%{}]}],
    iex>   display_mode: :voted
    iex> }
    iex> EpochtalkServerWeb.Controllers.PollJSON.poll(%{poll: poll, has_voted: true})
    %{
       thread_id: 99,
       id: 1,
       question: "Is this a test?",
       answers: [%{id: 3, answer: "yes", votes: 2}, %{id: 4, answer: "no", votes: 1}],
       display_mode: :voted,
       has_voted: true
     }
    iex> EpochtalkServerWeb.Controllers.PollJSON.poll(%{poll: poll, has_voted: false})
    %{
       thread_id: 99,
       id: 1,
       question: "Is this a test?",
       answers: [%{id: 3, answer: "yes", votes: 0}, %{id: 4, answer: "no", votes: 0}],
       display_mode: :voted,
       has_voted: false
     }
  """
  def poll(%{poll: poll, has_voted: has_voted}) do
    # move poll_answers to answers field
    poll = poll |> Map.put(:answers, poll.poll_answers)

    # tally votes from poll_responses
    poll =
      poll
      |> Map.put(
        :answers,
        Enum.map(poll.answers, fn answer ->
          Map.put(answer, :votes, Enum.count(answer.poll_responses))
          |> Map.delete(:poll_responses)
        end)
      )

    # hide votes if poll is not expired and display mode is set to display votes when expired
    now = NaiveDateTime.utc_now()

    hide_votes =
      (poll.display_mode === :voted && !has_voted) ||
        (poll.display_mode === :expired && NaiveDateTime.compare(poll.expiration, now) == :gt)

    poll =
      if hide_votes,
        do: poll |> Map.put(:answers, Enum.map(poll.answers, &Map.put(&1, :votes, 0))),
        else: poll

    # set boolean indicating if the authed user has voted and remove unneeded fields
    poll |> Map.put(:has_voted, has_voted) |> Map.delete(:poll_answers)
  end

  @doc """
  Renders updated `Poll`.

    iex> poll = %{
    iex>   max_answers: 2,
    iex>   id: 1,
    iex>   change_vote: true,
    iex>   expiration: nil,
    iex>   display_mode: :voted
    iex> }
    iex> EpochtalkServerWeb.Controllers.PollJSON.update(%{poll: poll})
    poll
  """
  def update(%{poll: poll}),
    do: %{
      id: poll.id,
      max_answers: poll.max_answers,
      change_vote: poll.change_vote,
      expiration: poll.expiration,
      display_mode: poll.display_mode
    }

  @doc """
  Renders locked `Poll`.

    iex> poll = %{
    iex>   thread_id: 2,
    iex>   locked: false
    iex> }
    iex> EpochtalkServerWeb.Controllers.PollJSON.lock(%{poll: poll})
    poll
  """
  def lock(%{poll: %{thread_id: thread_id, locked: locked}}),
    do: %{thread_id: thread_id, locked: locked}
end
