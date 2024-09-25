defmodule EpochtalkServer.SMFLoader do
  alias EpochtalkServer.Models.BoardMapping

  # converts smf_boards tsv file to epochtalk boards tsv file
  def convert_smf_boards_tsv_file(path) do
    {boards, board_mappings} = load_from_tsv_file(path)
    |> map_boards_stream()

    # write boards to file for import
    boards
    |> tabulate_boards_map()
    |> write_to_tsv_file("boards.tsv")

    # return board mappings for later insertion
    board_mappings
  end
  def insert_board_mappings(board_mappings) do
    # board mappings
    board_mappings
    |> BoardMapping.update()
  end
  # loads smf data from a tsv file
  def load_from_tsv_file(path) do
    with true <- if(File.exists?(path), do: true, else: "ファイルがない"),
      {:ok, file} <- File.read(path),
      file_lines <- file |> String.trim() |> String.split("\n"),
      [header_line | file_lines] <- file_lines,
      headers <-
        # clean line
        header_line
        |> String.trim()
        |> String.split("\t"),
      smf_boards <-
        file_lines
        |> Enum.map(&(
          &1
          # clean line
          |> String.trim()
          |> String.split("\t")
        ))
        |> Enum.map(fn line ->
          # map each line to headers
          Enum.zip(headers, line)
          |> Enum.into(%{})
        end) do
          smf_boards
    else
      problem -> IO.puts("問題がある： #{inspect(problem)}")
    end
  end
  def map_boards_stream(boards_stream) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
    {board_mapping_pairs, _slug_duplicate_index} =
      boards_stream
      |> Enum.map_reduce(%{}, fn smf_board, slugs ->
        slug =
          smf_board["name"]
          |> HtmlEntities.decode()
          |> String.replace(~r{ }, "-")
          |> String.slice(0..99)
        # handle duplicate slugs
        slug_duplicate_index = Map.get(slugs, slug)
        {slugs, slug} =
          if slug_duplicate_index == nil do
            # keep track of used slugs, return original slug
            {Map.put(slugs, slug, 0), slug}
          else
            # replace last characters with index
            new_slug = slug |> String.slice(0..(99 - (1 + Integer.floor_div(slug_duplicate_index, 10))))
            new_slug = new_slug <> to_string(slug_duplicate_index)
            # increment used slugs, return new slug
            {Map.put(slugs, slug, slug_duplicate_index + 1), new_slug}
          end
        # build board
        board =
          %{}
          |> Map.put(:id, smf_board["ID_BOARD"])
          |> Map.put(:name, smf_board["name"] |> HtmlEntities.decode())
          |> Map.put(:description, smf_board["description"] |> HtmlEntities.decode())
          |> Map.put(:post_count, smf_board["numPosts"])
          |> Map.put(:thread_count, smf_board["numTopics"])
          |> Map.put(:viewable_by, "")
          |> Map.put(:postable_by, "")
          |> Map.put(:created_at, now)
          |> Map.put(:imported_at, now)
          |> Map.put(:updated_at, now)
          |> Map.put(:meta, "\"{\"\"disable_self_mod\"\": false, \"\"disable_post_edit\"\": null, \"\"disable_signature\"\": false}\"")
          |> Map.put(:right_to_left, "f")
          |> Map.put(:slug, slug)

        # build board mapping
        board_mapping =
          case {smf_board["childLevel"], smf_board["ID_PARENT"]} do
            # top level board, map under category
            {"0", "0"} ->
              %{
                type: "board",
                id: smf_board["ID_BOARD"] |> String.to_integer(),
                name: smf_board["name"] |> HtmlEntities.decode(),
                category_id: smf_board["ID_CAT"] |> String.to_integer(),
                view_order: smf_board["boardOrder"] |> String.to_integer()
              }
            _ ->
              %{
                type: "board",
                id: smf_board["ID_BOARD"] |> String.to_integer(),
                name: smf_board["name"] |> HtmlEntities.decode(),
                parent_id: smf_board["ID_PARENT"] |> String.to_integer(),
                view_order: smf_board["boardOrder"] |> String.to_integer()
              }
          end
        {{board, board_mapping}, slugs}
      end)
    Enum.unzip(board_mapping_pairs)
  end
  def tabulate_boards_map(boards_map) do
    data =
      boards_map
      |> Enum.map(fn board ->
        [
          board[:id],
          board[:name],
          board[:description],
          board[:post_count],
          board[:thread_count],
          board[:viewable_by],
          board[:postable_by],
          board[:created_at],
          board[:imported_at],
          board[:updated_at],
          board[:meta],
          board[:right_to_left],
          board[:slug]
        ]
        |> Enum.join("\t")
      end)

    header = [
      "id",
      "name",
      "description",
      "post_count",
      "thread_count",
      "viewable_by",
      "postable_by",
      "created_at",
      "imported_at",
      "updated_at",
      "meta",
      "right_to_left",
      "slug"
    ] |> Enum.join("\t")
    [ header | data ]
  end
  def write_to_tsv_file(data, path) do
    with false <- if(File.exists?(path), do: "ファイルがもうある", else: false),
      file <- File.stream!(path) do
        data |> Enum.into(file, fn line -> line <> "\n" end)
    else
      problem -> IO.puts("問題がある： #{inspect(problem)}")
    end
  end
end
