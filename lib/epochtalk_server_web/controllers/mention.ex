defmodule EpochtalkServerWeb.Controllers.Mention do
  use EpochtalkServerWeb, :controller

  @moduledoc """
  Controller For `Mention` related API requests
  """
  alias EpochtalkServer.Auth.Guardian
  alias EpochtalkServer.Models.Mention
  alias EpochtalkServerWeb.ErrorHelpers
  alias EpochtalkServerWeb.Helpers.Validate
  alias EpochtalkServerWeb.Helpers.ACL

  @doc """
  Used to page `Mention` models for a specific `User`
  """
  def page(conn, attrs) do
    with page <- Validate.cast(attrs, "page", :integer, min: 1),
         limit <- Validate.cast(attrs, "limit", :integer, min: 1),
         extended <- Validate.cast(attrs, "extended", :boolean),
         :ok <- ACL.allow!(conn, "mentions.page"),
         {:auth, %{} = user} <- {:auth, Guardian.Plug.current_resource(conn)},
         {:ok, mentions, data} <-
           Mention.page_by_user_id(user.id, page, per_page: limit, extended: extended),
         do:
           render(conn, :page, %{
             mentions: mentions,
             pagination_data: data,
             extended: extended
           }),
         else: ({:auth, nil} ->
                  ErrorHelpers.render_json_error(conn, 400, "Not logged in, cannot page mentions"))
  end
end
