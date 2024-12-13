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

  def run do
    for id <- @start_id..@end_id//-1 do
      case HTTPoison.get("http://localhost:4000/api/posts?thread_id=#{id}") do
        {:ok, %HTTPoison.Response{status_code: 200, body: _body}} ->
          Logger.info("Successfully parsed thread with id (#{id})")

        {:ok, %HTTPoison.Response{status_code: status_code}} ->
          Logger.error("Thread with id (#{id}) received response with status code #{status_code}")

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("Thread with id (#{id}) HTTP request failed: #{reason}")
      end
    end
  end
end

ParseByThread.run()
