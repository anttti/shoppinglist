defmodule ShoppinglistWeb.ShoppingListLive.Show do
  use ShoppinglistWeb, :live_view

  alias Shoppinglist.Shopping
  alias Shoppinglist.Shopping.ShoppingListItem

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    shopping_list = Shopping.get_user_shopping_list!(socket.assigns.current_user, id)
    IO.inspect(socket.assigns.current_user)
    IO.inspect(id)

    if connected?(socket) do
      Shopping.subscribe_to_shopping_list(id)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:shopping_list, shopping_list)
     |> assign(:has_items, length(shopping_list.items) > 0)
     |> stream(:shopping_list_items, shopping_list.items)}
  end

  @impl true
  def handle_info({:shopping_list_item_created, _item}, socket) do
    # Reload all items to ensure consistency
    shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)

    updated_socket =
      socket
      |> stream(:shopping_list_items, shopping_list.items, reset: true)
      |> assign(:has_items, length(shopping_list.items) > 0)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:shopping_list_item_updated, _item}, socket) do
    # Reload all items to ensure consistency
    shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)

    updated_socket =
      socket
      |> stream(:shopping_list_items, shopping_list.items, reset: true)
      |> assign(:has_items, length(shopping_list.items) > 0)

    {:noreply, updated_socket}
  end

  @impl true
  def handle_info({:shopping_list_item_deleted, item}, socket) do
    updated_socket = stream_delete(socket, :shopping_list_items, item)
    shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)
    has_items = length(shopping_list.items) > 0

    {:noreply, assign(updated_socket, :has_items, has_items)}
  end

  @impl true
  def handle_info({:shopping_list_updated, shopping_list}, socket) do
    {:noreply, assign(socket, :shopping_list, shopping_list)}
  end

  @impl true
  def handle_event("add_item", %{"item" => item_params}, socket) do
    case Shopping.create_shopping_list_item(socket.assigns.shopping_list, item_params) do
      {:ok, item} ->
        # Reload all items to ensure consistency
        shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)

        updated_socket =
          socket
          |> stream(:shopping_list_items, shopping_list.items, reset: true)
          |> assign(:has_items, length(shopping_list.items) > 0)

        Task.start(fn ->
          Shopping.broadcast_shopping_list_item_update(item, :shopping_list_item_created)
        end)

        {:noreply, updated_socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add item")}
    end
  end

  @impl true
  def handle_event("toggle_collected", %{"id" => id}, socket) do
    item = Shopping.get_shopping_list_item!(id)

    case Shopping.update_shopping_list_item(item, %{collected: !item.collected}) do
      {:ok, updated_item} ->
        # Reload all items to ensure consistency
        shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)

        updated_socket =
          socket
          |> stream(:shopping_list_items, shopping_list.items, reset: true)
          |> assign(:has_items, length(shopping_list.items) > 0)

        Task.start(fn ->
          Shopping.broadcast_shopping_list_item_update(updated_item, :shopping_list_item_updated)
        end)

        {:noreply, updated_socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update item")}
    end
  end

  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item = Shopping.get_shopping_list_item!(id)

    case Shopping.delete_shopping_list_item(item) do
      {:ok, deleted_item} ->
        # Reload all items to ensure consistency
        shopping_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)

        updated_socket =
          socket
          |> stream(:shopping_list_items, shopping_list.items, reset: true)
          |> assign(:has_items, length(shopping_list.items) > 0)

        Task.start(fn ->
          Shopping.broadcast_shopping_list_item_update(deleted_item, :shopping_list_item_deleted)
        end)

        {:noreply, updated_socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete item")}
    end
  end

  @impl true
  def handle_event("validate_item", %{"item" => item_params}, socket) do
    changeset = Shopping.change_shopping_list_item(%ShoppingListItem{}, item_params)
    {:noreply, assign(socket, :item_changeset, changeset)}
  end

  defp page_title(:show), do: "Show Shopping list"
  defp page_title(:edit), do: "Edit Shopping list"
  defp page_title(:share), do: "Share Shopping list"
end
