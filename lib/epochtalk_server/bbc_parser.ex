defmodule EpochtalkServer.BBCParser do
  use GenServer
  require Logger
  alias Porcelain.Process, as: Proc

  # poolboy genserver call timeout (ms)
  # should be greater than internal porcelain php call
  @call_timeout 500
  # porcelain php parser call timeout (ms)
  @receive_timeout 400

  @moduledoc """
  `BBCParser` genserver, runs interactive php shell to call bbcode parser
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_info({_pid, :data, :out, data}, state) do
    Logger.debug("#{__MODULE__}(info): #{inspect(data)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:parse, ""}, _from, {proc, pid}),
    do: {:reply, {:ok, ""}, {proc, pid}}

  def handle_call({:parse, bbcode_data}, _from, {proc, pid}) when is_binary(bbcode_data) do
    Logger.debug(
      "#{__MODULE__}(start parse): #{String.first(bbcode_data)} #{NaiveDateTime.utc_now()}"
    )

    parsed = parse_with_proc(bbcode_data, {proc, pid})

    Logger.debug(
      "#{__MODULE__}(finish parse): #{String.first(bbcode_data)} #{NaiveDateTime.utc_now()}"
    )

    {:reply, parsed, {proc, pid}}
  end

  def handle_call({:parse_list_tuple, {left_list, right_list}}, _from, {proc, pid}) do
    Logger.debug("#{__MODULE__}(start parse list tuple): #{NaiveDateTime.utc_now()}")
    parsed = parse_list_tuple_with_proc({left_list, right_list}, {proc, pid})
    Logger.debug("#{__MODULE__}(finish parse list tuple): #{NaiveDateTime.utc_now()}")
    {:reply, {:ok, parsed}, {proc, pid}}
  end

  defp parse_list_tuple_with_proc({left, right}, {proc, pid}) do
    left = parse_list_with_proc(left, {proc, pid})
    right = parse_list_with_proc(right, {proc, pid})
    {left, right}
  end

  defp parse_list_with_proc(bbcode_data_list, {proc, pid}) do
    bbcode_data_list
    |> Enum.map(&parse_with_proc(&1, {proc, pid}))
  end

  defp parse_with_proc(nil, {_proc, _pid}), do: {:ok, nil}
  defp parse_with_proc("", {_proc, _pid}), do: {:ok, ""}

  defp parse_with_proc(bbcode_data, {proc, pid}) do
    Proc.send_input(proc, "echo parse_bbc('#{bbcode_data}');\n")

    receive do
      {^pid, :data, :out, data} ->
        {:ok, data}
    after
      # time out after not receiving any data
      @receive_timeout ->
        Logger.error("#{__MODULE__}(parse timeout): #{inspect(pid)}, #{inspect(bbcode_data)}")

        bbcode_data =
          "<p style=\"color:red;font-weight:bold\">((bbcode parse timeout))</p></br>" <>
            bbcode_data

        {:timeout, bbcode_data}
    end
  end

  ## === parser api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok)

  @doc """
  Uses poolboy to call parser
  """
  def parse_list_tuple({left_bbcode_data, right_bbcode_data}) do
    :poolboy.transaction(
      :bbc_parser,
      fn pid ->
        try do
          Logger.debug("#{__MODULE__}(parse): #{inspect(pid)}")

          GenServer.call(pid, {:parse_list_tuple, {left_bbcode_data, right_bbcode_data}})
        catch
          e, r ->
            # something went wrong, log the error
            Logger.error(
              "#{__MODULE__}(parse poolboy): #{inspect(pid)}, #{inspect(e)}, #{inspect(r)}"
            )

            {:error, {left_bbcode_data, right_bbcode_data}}
        end
      end,
      @call_timeout
    )
  end

  def parse(bbcode_data) do
    :poolboy.transaction(
      :bbc_parser,
      fn pid ->
        try do
          Logger.debug("#{__MODULE__}(parse): #{inspect(pid)}")

          GenServer.call(pid, {:parse, bbcode_data}, @call_timeout)
          |> case do
            # on success, return parsed data
            {:ok, parsed} ->
              parsed

            # on parse timeout, log and return unparsed data
            {:timeout, unparsed} ->
              unparsed
          end
        catch
          e, r ->
            # something went wrong, log the error
            Logger.error(
              "#{__MODULE__}(parse poolboy): #{inspect(pid)}, #{inspect(e)}, #{inspect(r)}"
            )

            bbcode_data
        end
      end,
      @call_timeout
    )
  end

  ## === private functions ====

  # returns loaded interactive php shell
  defp load() do
    proc = %Proc{pid: pid} = Porcelain.spawn_shell("php -a", in: :receive, out: {:send, self()})
    Proc.send_input(proc, "require 'parsing.php';\n")
    Logger.debug("#{__MODULE__}(LOAD): #{inspect(pid)}")
    # clear initial php interactive shell message

    {proc, pid}
  end
end
