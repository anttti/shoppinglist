defmodule ShoppinglistWeb.UserSessionController do
  use ShoppinglistWeb, :controller

  alias Shoppinglist.Accounts
  alias ShoppinglistWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create_user(conn, params)
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create_user(params)
  end

  def create(conn, params) do
    create_user(conn, params)
  end

  defp create_user(conn, %{"user" => user_params} = params) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Extract remember_me from user_params and put it at the top level
      remember_me_params = case user_params do
        %{"remember_me" => remember_me} -> %{"remember_me" => remember_me}
        _ -> %{}
      end

      conn
      |> UserAuth.log_in_user(user, Map.merge(params, remember_me_params))
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end
end
