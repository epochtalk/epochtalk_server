defmodule EpochtalkServer.BBCParser do
  use GenServer
  require Logger
  alias Porcelain.Process, as: Proc
  @timeout 1_000

  @moduledoc """
  `BBCParser` genserver, runs interactive php shell to call bbcode parser
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call({:parse, ""}, _from, {proc, pid}),
    do: {:reply, "", {proc, pid}}

  def handle_call({:parse, bbcode_data}, _from, {proc, pid}) when is_binary(bbcode_data) do
    Proc.send_input(proc, "echo parse_bbc('#{bbcode_data}');\n")

    parsed =
      receive do
        {^pid, :data, :out, data} ->
          Logger.debug(data)
          data
      end

    {:reply, parsed, {proc, pid}}
  end

  ## === parser api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok)

  @doc """
  Uses poolboy to call parser
  """
  def parse(bbcode_data) do
    :poolboy.transaction(
      :bbc_parser,
      fn pid ->
        try do
          Logger.debug("#{__MODULE__}(ASYNC PARSE): #{inspect(pid)}")
          GenServer.call(pid, {:parse, bbcode_data}, @timeout)
        catch
          e, r ->
            Logger.debug("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
            :ok
        end
      end,
      @timeout
    )
  end

  ## === private functions ====

  # returns loaded interactive php shell
  defp load() do
    proc = %Proc{pid: pid} = Porcelain.spawn_shell("php -a", in: :receive, out: {:send, self()})
    Proc.send_input(proc, "require 'parsing.php';\n")
    Logger.debug("#{__MODULE__}(LOAD): #{inspect(pid)}")
    # clear initial php interactive shell message
    receive do
      {^pid, :data, :out, data} -> Logger.debug("#{__MODULE__}: #{inspect(data)}")
    end

    {proc, pid}
  end
end
