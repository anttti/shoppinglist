defmodule ShoppinglistWeb.ShoppingListLiveTest do
  use ShoppinglistWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shoppinglist.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "Index" do
    test "handles lv:clear-flash event without affecting shopping lists", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/lists")

      # The lv:clear-flash event should not cause any issues
      assert render_hook(lv, "lv:clear-flash", %{"key" => "info"})

      # LiveView should still be functional
      assert has_element?(lv, "h1", "My Shopping Lists")
    end
  end
end
