defmodule Peepchat.SessionController do
  use Peepchat.Web, :controller

  import Ecto.Query, only: [where: 2]
  import Comeonin.Bcrypt
  import Logger

  alias Peepchat.User

  def create(conn, %{"grant_type" => "password",
      "username" => username,
      "password" => password}) do

    # Handle a user login
    try do
      # Attempt to retrieve exactly one user from the DB, whose email matches
      # the one provided with the login request
      user = User
        |> where(email: ^username)
        |> Repo.one!
      cond do
        checkpw(password, user.password_hash) ->
          # Successful login
          Logger.info "User " <> username <> " just loged in"
          # Encode a JWT
          { :ok, jwt, _} = Guardian.encode_and_sign(user, :token)
          conn
            |> json(%{access_token: jwt}) # Return a token to the client
        true ->
          # Unsuccessful login
          Loger.warning "User " <> username <> " just failed to login"
          conn
            |> put_status(401)
            |> render(Peepchat.ErrorView, "401.json")
      end
    rescue
      e ->
        IO.inspect e
        Logger.error "Unexpected error while atempting to login user " <> username
        conn
          |> put_status(401)
          |> render(Peepchat.ErrorView, "401.json")
    end
  end

  def create(conn, %{"grant_type" => _})do
    # Handle unknown grant type
    throw "Unsupported grant_type"
  end
end
