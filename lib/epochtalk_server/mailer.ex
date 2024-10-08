defmodule EpochtalkServer.Mailer do
  use Swoosh.Mailer, otp_app: :epochtalk_server
  require Logger
  import Swoosh.Email
  alias EpochtalkServer.Models.User

  @moduledoc """
  Used to generate and send emails from the API to a `User`.
  """

  @doc """
  Sends confirmation email
  """
  @spec send_confirm_account(recipient :: User.t()) :: {:ok, term} | {:error, term}
  def send_confirm_account(%User{email: email, username: username, confirmation_token: token}) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    frontend_url = config[:frontend_url]
    website_title = config[:website][:title]
    from_address = config[:emailer][:options][:from_address]
    confirm_url = "#{frontend_url}/confirm/#{String.downcase(username)}/#{token}"

    content =
      generate_from_base_template(
        """
        <h3>Account Confirmation</h3>
        Please visit the link below to complete the registration process for the account <strong>#{username}</strong>.<br /><br />
        <a href="#{confirm_url}" target="_blank">Confirm Account</a><br /><br />
        <small>Raw confirm URL: #{confirm_url}</small>
        """,
        config
      )

    new()
    |> to({username, email})
    |> from({website_title, from_address})
    |> subject("[#{website_title}] Account Confirmation")
    |> html_body(content)
    |> deliver()
    |> handle_delivered_email()
  end

  @doc """
  Sends thread subscription email
  """
  @spec send_thread_subscription(email_data :: map) :: {:ok, term} | {:error, term}
  def send_thread_subscription(%{
        email: email,
        id: last_post_id,
        position: last_post_position,
        thread_slug: thread_slug,
        title: thread_title,
        username: username
      }) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    frontend_url = config[:frontend_url]
    website_title = config[:website][:title]
    from_address = config[:emailer][:options][:from_address]

    thread_url =
      "#{frontend_url}/threads/#{thread_slug}?start=#{last_post_position}##{last_post_id}"

    content =
      generate_from_base_template(
        """
        <h3>New replies to thread "#{thread_title}"</h3>
        Hello #{username}! Please visit the link below to view new thread replies.<br /><br />
        <a href="#{thread_url}">View Replies</a><br /><br />
        <small>Raw thread URL: #{thread_url}</small>
        """,
        config
      )

    new()
    |> to({username, email})
    |> from({website_title, from_address})
    |> subject("[#{website_title}] New replies to thread #{thread_title}")
    |> html_body(content)
    |> deliver()
    |> handle_delivered_email()
  end

  @doc """
  Sends thread purge email
  """
  @spec send_thread_purge(email_data :: map) :: {:ok, term} | {:error, term}
  def send_thread_purge(%{
        email: email,
        title: thread_title,
        username: username,
        action: action,
        mod_username: mod_username
      }) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    frontend_url = config[:frontend_url]
    website_title = config[:website][:title]
    from_address = config[:emailer][:options][:from_address]

    content =
      generate_from_base_template(
        """
        <h3>"#{thread_title}" a thread that you #{action}, has been deleted</h3>
        User "#{mod_username}" has deleted the thread named "#{thread_title}". If you wish to know why this thread was removed please contact a member of the forum moderation team.<br /><br />
        <a href="#{frontend_url}">Visit Forum</a><br /><br />
        <small>Raw site URL: #{frontend_url}</small>
        """,
        config
      )

    new()
    |> to({username, email})
    |> from({website_title, from_address})
    |> subject(
      "[#{website_title}] \"#{thread_title}\" a thread that you #{action}, has been deleted"
    )
    |> html_body(content)
    |> deliver()
    |> handle_delivered_email()
  end

  @doc """
  Sends mention notification email
  """
  @spec send_mention_notification(email_data :: map) :: {:ok, term} | {:error, term}
  def send_mention_notification(%{
        email: email,
        post_id: post_id,
        post_position: post_position,
        post_author: post_author,
        thread_slug: thread_slug,
        thread_title: thread_title
      }) do
    config = Application.get_env(:epochtalk_server, :frontend_config)
    frontend_url = config[:frontend_url]
    website_title = config[:website][:title]
    from_address = config[:emailer][:options][:from_address]

    thread_url = "#{frontend_url}/threads/#{thread_slug}?start=#{post_position}##{post_id}"

    content =
      generate_from_base_template(
        """
        <h3>#{post_author} mentioned you in the thread "#{thread_title}"</h3>
        Please visit the link below to view the post you were mentioned in.<br /><br />
        <a href="#{thread_url}">View Mention</a>
        <small>Raw thread URL: #{thread_url}</small>
        """,
        config
      )

    new()
    |> to(email)
    |> from({website_title, from_address})
    |> subject("[#{website_title}] New replies to thread #{thread_title}")
    |> html_body(content)
    |> deliver()
    |> handle_delivered_email()
  end

  defp handle_delivered_email(result) do
    case result do
      {:ok, email_metadata} ->
        {:ok, email_metadata}

      {:error, error} ->
        # Log error
        Logger.error(error)
        # return error we can match
        {:error, :not_delivered}
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

    website_title = config[:website][:title]

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
                <div class="footer">&copy; #{DateTime.utc_now().year} #{website_title}</div>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
