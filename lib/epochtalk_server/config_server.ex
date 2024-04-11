defmodule EpochtalkServer.ConfigServer do
  use GenServer

  # TODO(boka): move to config
  @one_day_in_ms 1000 * 60 * 60 * 24
  @one_hour_in_ms 1000 * 60 * 60
  @max_images_per_day 1000
  @max_images_per_hour 100

  @moduledoc """
  Config genserver, stores configs in memory for quick lookup
  """

  ## === genserver functions ====

  @impl true
  def init(:ok), do: {:ok, load()}

  @impl true
  def handle_call({:get, module}, _from, all_configs) do
    {:reply, all_configs[module], all_configs}
  end

  ## === api functions ====

  @doc """
  Start genserver and create a reference for supervision tree
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Returns config for specified module
  """
  @spec by_module(module :: atom) :: map() | nil
  def by_module(module) do
    GenServer.call(__MODULE__, {:get, module})
  end

  ## === private functions ====

  # loads configs
  defp load() do
    %{
      "Elixir.EpochtalkServer.RateLimiter": %{
        s3_daily: [
          @one_day_in_ms,
          @max_images_per_day
        ],
        s3_hourly: [
          @one_hour_in_ms,
          @max_images_per_hour
        ]
      }
    }
  end
end
