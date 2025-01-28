defmodule EpochtalkServer.BBCParser do
  use GenServer
  require Logger
  alias Porcelain.Process, as: Proc

  # genserver call timeouts (ms)
  @genserver_parse_timeout 5000
  @genserver_parse_tuple_timeout 5000

  # poolboy timeout (ms)
  @poolboy_transaction_timeout 5000

  @input_delimiter <<1>>
  @receive_delimiter <<1, 10>>
  @newline <<10>>

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
    Proc.send_input(proc, "echo parse_bbc('#{bbcode_data <> @input_delimiter}');\n")
    receive_until_timeout_or_delimiter(pid)
    |> case do
      {:ok, data} -> {:ok, data}
      {:timeout} ->
        Logger.error("#{__MODULE__}(parse timeout): #{inspect(pid)}, #{inspect(bbcode_data)}")

        bbcode_data =
          "<p style=\"color:red;font-weight:bold\">((bbcode parse timeout))</p></br>" <>
            bbcode_data

        {:timeout, bbcode_data}
    end
  end

def print_last_chars(string, x) do
  String.slice(string, -x, String.length(string))
end

  defp receive_until_timeout_or_delimiter(pid), do: receive_until_timeout_or_delimiter(pid, "")

  defp receive_until_timeout_or_delimiter(pid, str) do
    config = Application.get_env(:epochtalk_server, :bbc_parser_config)
    # porcelain php parser call timeout (ms)
    receive_timeout = config.porcelain_receive_timeout

    receive do
      {^pid, :data, :out, data} ->
        IO.inspect "receive"
        IO.inspect data |> String.reverse
        # if last character the delimiter, return {:ok, full_str}
        if String.ends_with?(data, @receive_delimiter) do
          trimmed = data
            |> String.trim_trailing(@newline)
            |> String.trim_trailing(@input_delimiter)
          {:ok, str <> trimmed}
        # else append to str and keep receiving
        else
          receive_until_timeout_or_delimiter(pid, str <> data)
        end
      after
      # time out after not receiving any data
      receive_timeout -> {:timeout}
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

          GenServer.call(
            pid,
            {:parse_list_tuple, {left_bbcode_data, right_bbcode_data}},
            @genserver_parse_tuple_timeout
          )
        catch
          e, r ->
            # something went wrong, log the error
            Logger.error(
              "#{__MODULE__}(parse poolboy): #{inspect(pid)}, #{inspect(e)}, #{inspect(r)}"
            )

            left_bbcode_data = left_bbcode_data |> Enum.map(&{:timeout, &1})
            right_bbcode_data = right_bbcode_data |> Enum.map(&{:timeout, &1})
            {:error, {left_bbcode_data, right_bbcode_data}}
        end
      end,
      @poolboy_transaction_timeout
    )
  end

  def parse(bbcode_data) do
    :poolboy.transaction(
      :bbc_parser,
      fn pid ->
        try do
          Logger.debug("#{__MODULE__}(parse): #{inspect(pid)}")

          GenServer.call(pid, {:parse, bbcode_data}, @genserver_parse_timeout)
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
      @poolboy_transaction_timeout
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
