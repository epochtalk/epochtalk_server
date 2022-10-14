defmodule EpochtalkServer.Mailer do
  use Swoosh.Mailer, otp_app: :epochtalk_server
  import Swoosh.Email

  def test_email() do
    email = new(from: {"Dr B Banner", "hulk.smash@example.com"}, to: {"Tony Stark", "iron.man@mailinator.com"}, subject: "Hello, Avengers!", text_body: "HELLO WORLD")
    deliver(email)
  end
end
