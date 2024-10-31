defmodule EpochtalkServer.BBCParser do
  use GenServer
  require Logger
  alias Porcelain.Process, as: Proc

  @moduledoc """
  `BBCParser` genserver, runs interactive php shell to call bbcode parser
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call({:parse, bbcode_data}, _from, {proc, pid}) do
    if bbcode_data == "" do
      {:reply, "", {proc, pid}}
    else
      Proc.send_input(proc, "echo parse_bbc('#{bbcode_data}');\n")
      Logger.debug("FUCKFUCKFUCK PID: #{inspect(pid)}")
      parsed = receive do
        {^pid, :data, :out, data} -> data
      end

      {:reply, parsed, {proc, pid}}
    end
  end

  ## === parser api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc """
  Returns parsed bbcode input
  """
  @spec parse(bbcodea_data :: any) :: String.t()
  def parse(bbcode_data) do
    GenServer.call(__MODULE__, {:parse, bbcode_data})
  end

  @doc """
  Uses poolboy to call parser
  """
  def async_parse(bbcode_data) do
    :poolboy.transaction(
      :bbc_parser,
      fn pid ->
        # Let's wrap the genserver call in a try - catch block. This allows us to trap any exceptions
        # that might be thrown and return the worker back to poolboy in a clean manner. It also allows
        # the programmer to retrieve the error and potentially fix it.
        try do
          Logger.debug "#{__MODULE__}(ASYNC PARSE): #{inspect(pid)}"
          GenServer.call(pid, {:parse, bbcode_data}, 10000) |> IO.inspect
        catch
          e, r -> IO.inspect("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
          :ok
        end
      end,
      50000
    )
  end

  ## === private functions ====

  # returns loaded interactive php shell
  defp load() do
    proc = %Proc{pid: pid} = Porcelain.spawn_shell("php -a",in: :receive, out: {:send, self()})
    Proc.send_input(proc, "require 'parsing.php';\n")
    Logger.debug "#{__MODULE__}(LOAD): #{inspect(pid)}"
    # clear initial message
    receive do
      {^pid, :data, :out, data} -> Logger.debug "#{__MODULE__}: #{inspect(data)}"
    end
    {proc, pid}
  end
end
