defmodule ShoppinglistWeb.ShoppingListLive.FormComponent do
  use ShoppinglistWeb, :live_component

  alias Shoppinglist.Shopping

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="shopping_list-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" autocomplete="off" />
        <.input field={@form[:color]} type="color" label="Color" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Shopping list</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{shopping_list: shopping_list} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Shopping.change_shopping_list(shopping_list))
     end)}
  end

  @impl true
  def handle_event("validate", %{"shopping_list" => shopping_list_params}, socket) do
    changeset = Shopping.change_shopping_list(socket.assigns.shopping_list, shopping_list_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"shopping_list" => shopping_list_params}, socket) do
    save_shopping_list(socket, socket.assigns.action, shopping_list_params)
  end

  defp save_shopping_list(socket, :edit, shopping_list_params) do
    case Shopping.update_shopping_list(socket.assigns.shopping_list, shopping_list_params) do
      {:ok, shopping_list} ->
        send(self(), {:shopping_list_updated, shopping_list})

        {:noreply,
         socket
         |> put_flash(:info, "Shopping list updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_shopping_list(socket, :new, shopping_list_params) do
    case Shopping.create_shopping_list(socket.assigns.current_user, shopping_list_params) do
      {:ok, shopping_list} ->
        send(self(), {:shopping_list_created, shopping_list})

        {:noreply,
         socket
         |> put_flash(:info, "Shopping list created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
