defmodule EpochtalkServer.Mailer do
  use Swoosh.Mailer, otp_app: :epochtalk_server
  require Logger
  import Swoosh.Email

  @spec send_confirm_account(recipient :: User.t()) :: {:ok, term} | {:error, term}
  def send_confirm_account(%User{ email: email, username: username, confirmation_token: token}) do
    new()
    |> to({username, email})
    |> from({"Epochtalk", "info@epochtalk.com"})
    |> subject("[Epochtalk] Account Confirmation")
    |> html_body("TODO")
    |> deliver()
    |> case do
      {:ok, email_metadata} -> {:ok, email_metadata}
      {:error, error} ->
        Logger.error(error) # Log error
        {:error, :not_delivered} # return error we can match
    end
  end
end
