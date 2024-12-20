Mix.install([{:httpoison, "~> 2.0"}, {:logger_file_backend, "~> 0.0.10"}])

defmodule ParseByThread do
  require Logger

  Logger.add_backend({LoggerFileBackend, :error})

  Logger.configure_backend({LoggerFileBackend, :error},
    path: "./parse_by_thread_error.log",
    level: :error
  )

  @start_id 5_485_059
  @end_id 1
  @max_page 999_999

  def run,
    do: for(id <- @start_id..@end_id//-1, do: process_thread(id))

  def process_thread(id) do
    Enum.reduce_while(1..@max_page, nil, fn page, _acc ->
      case HTTPoison.get("http://localhost:4000/api/posts?thread_id=#{id}&page=#{page}") do
        {:ok, %HTTPoison.Response{status_code: 200, body: _body}} ->
          {:cont, nil}

        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body:
             "{\"error\":\"Bad Request\",\"message\":\"Error, page does not exist\",\"status\":400}"
         }} ->
          Logger.info("Successfully parsed #{page - 1} page(s) of thread with id (#{id})")
          {:halt, nil}

        {:ok, %HTTPoison.Response{status_code: status_code}} ->
          Logger.error("Thread with id (#{id}) received response with status code #{status_code}")
          {:halt, nil}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("Thread with id (#{id}) HTTP request failed: #{reason}")
          {:halt, nil}
      end
    end)
  end
end

ParseByThread.run()
