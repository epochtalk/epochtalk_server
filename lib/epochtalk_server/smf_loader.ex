defmodule EpochtalkServer.SMFLoader do
  # loads smf data from a tsv file
  def load_from_tsv_file(path) do
    with true <- if(File.exists?(path), do: true, else: "ファイルがない"),
      {:ok, file} <- File.open(path),
      headers <-
        IO.read(file, :line)
        # clean line
        |> String.trim()
        |> String.split("\t"),
        # |> Enum.map(&(&1 |> String.trim)),
      file_stream <-
        IO.stream(file, :line)
        |> Stream.map(&(
          &1
          # clean line
          |> String.trim()
          |> String.split("\t")
        ))
        |> Stream.map(fn line ->
          # map each line to headers
          Enum.zip(headers, line)
          |> Enum.into(%{})
        end) do
          file_stream
    else
      problem -> IO.puts("問題がある： #{inspect(problem)}")
    end
  end
end
