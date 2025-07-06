defmodule ShoppinglistWeb.ShoppingListLive.Index do
  use ShoppinglistWeb, :live_view

  alias Shoppinglist.Shopping
  alias Shoppinglist.Shopping.ShoppingList

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      if connected?(socket) do
        Shopping.subscribe_to_shopping_list("user:#{socket.assigns.current_user.id}")
      end

      {:ok, stream(socket, :shopping_lists, Shopping.list_shopping_lists(socket.assigns.current_user))}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Shopping list")
    |> assign(:shopping_list, Shopping.get_user_shopping_list!(socket.assigns.current_user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Shopping list")
    |> assign(:shopping_list, %ShoppingList{})
  end

  defp apply_action(socket, :index, _params) do
    if socket.assigns.current_user do
      socket
      |> assign(:page_title, "My Shopping Lists")
      |> assign(:shopping_list, nil)
    else
      socket
      |> assign(:page_title, "Welcome to Shopping Lists")
      |> assign(:shopping_list, nil)
    end
  end

  @impl true
  def handle_info({ShoppinglistWeb.ShoppingListLive.FormComponent, {:saved, shopping_list}}, socket) do
    {:noreply, stream_insert(socket, :shopping_lists, shopping_list)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    shopping_list = Shopping.get_user_shopping_list!(socket.assigns.current_user, id)
    {:ok, _} = Shopping.delete_shopping_list(shopping_list)

    {:noreply, stream_delete(socket, :shopping_lists, shopping_list)}
  end
end
