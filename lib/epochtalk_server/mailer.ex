defmodule EpochtalkServer.Mailer do
  use Swoosh.Mailer, otp_app: :epochtalk_server
  require Logger
  import Swoosh.Email
  alias EpochtalkServer.Models.User

  @spec send_confirm_account(recipient :: User.t()) :: {:ok, term} | {:error, term}
  def send_confirm_account(%User{ email: email, username: username, confirmation_token: token}) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    public_url = config["public_url"]
    website_title = config["website"]["title"]
    from_address = config["emailer"]["options"]["from_address"]
    confirm_url = "#{public_url}/confirm/#{String.downcase(username)}/#{token}"
    content = generate_from_base_template("""
      <h3>Account Confirmation</h3>
      Please visit the link below to complete the registration process for the account <strong>#{username}</strong>.<br /><br />
      <a href="#{confirm_url}" target="_blank">Confirm Account</a><br /><br />
      <small>Raw confirm URL: #{confirm_url}</small>
      """, config)
    new()
    |> to({username, email})
    |> from({website_title, from_address})
    |> subject("[#{website_title}] Account Confirmation")
    |> html_body(content)
    |> deliver()
    |> case do
      {:ok, email_metadata} -> {:ok, email_metadata}
      {:error, error} ->
        Logger.error(error) # Log error
        {:error, :not_delivered} # return error we can match
    end
  end

  defp generate_from_base_template(content, config) do
  # TODO(akinsey): Fetch values from css files
  css = %{
    header_bg_color: "rgb(66, 71, 80)",
    header_font_color: "rgb(255, 255, 255)",
    base_background_color: "rgb(255, 255, 255)",
    border_color: "rgb(215, 215, 215)",
    base_font_color: "rgb(34, 34, 54)",
    sub_header_color: "gb(245, 245, 245)",
    secondary_font_color: "rgb(153, 153, 153)",
    color_primary: "rgb(255, 100, 0)"
  }
  website_title = config["website"]["title"]
  """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <meta name="viewport" content="width=device-width"/>
      <style type="text/css">
        body {
          font-family: Helvetica, Arial, sans-serif;
          font-size: 12px;
        }
        .header {
          background-color: #{css.header_bg_color};
          color: #{css.header_font_color};
          font-weight: bold;
          font-size: 25px;
          padding-left: 25px;
          height: 50px;
          vertical-align: middle;
        }
        .body {
          min-width: 80%;
          background-color: #{css.base_background_color};
          border: 1px solid #{css.border_color};
          border-collapse: collapse;
        }
        .content {
          padding: 25px;
          padding-top: 10px;
          color: #{css.base_font_color};
        }
        .footer {
          background-color: #{css.sub_header_color};
          color: #{css.secondary_font_color};
          margin: 5px;
          line-height: 30px;
          height: 30px;
        }
        a { color: #{css.color_primary}; }
      </style>
    </head>
    <body>
      <table align="center" class="body">
        <tr>
          <td class="header" align="left" valign="middle">
              #{website_title}
          </td>
        </tr>
        <tr>
          <td class="content" align="left" valign="top">
            #{content}
          </td>
        </tr>
        <tr>
          <td align="center" valign="top">
              <div class="footer">&copy; #{DateTime.utc_now.year} #{website_title}</div>
          </td>
        </tr>
      </table>
    </body>
  </html>
  """
  end
end
