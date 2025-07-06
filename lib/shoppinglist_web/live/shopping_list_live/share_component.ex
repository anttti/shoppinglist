defmodule ShoppinglistWeb.ShoppingListLive.ShareComponent do
  use ShoppinglistWeb, :live_component

  alias Shoppinglist.Shopping
  alias Shoppinglist.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Share Shopping List
        <:subtitle>Add other users to collaborate on this shopping list.</:subtitle>
      </.header>

      <div class="mt-6">
        <h3 class="text-lg font-semibold mb-4">Current Collaborators</h3>

        <div class="space-y-3 mb-6">
          <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div class="flex items-center space-x-3">
              <.icon name="hero-user-circle" class="w-6 h-6 text-gray-400" />
              <div>
                <p class="font-medium text-gray-900"><%= @shopping_list.creator.email %></p>
                <p class="text-sm text-gray-500">Owner</p>
              </div>
            </div>
          </div>

          <div
            :for={user <- @shopping_list.users}
            class="flex items-center justify-between p-3 bg-white border rounded-lg"
          >
            <div class="flex items-center space-x-3">
              <.icon name="hero-user-circle" class="w-6 h-6 text-gray-400" />
              <div>
                <p class="font-medium text-gray-900"><%= user.email %></p>
                <p class="text-sm text-gray-500">Collaborator</p>
              </div>
            </div>
            <button
              phx-click="remove_user"
              phx-value-user-id={user.id}
              phx-target={@myself}
              data-confirm="Are you sure you want to remove this user?"
              class="text-red-600 hover:text-red-800 p-2"
            >
              <.icon name="hero-trash" class="w-5 h-5" />
            </button>
          </div>
        </div>

        <div class="border-t pt-6">
          <h3 class="text-lg font-semibold mb-4">Add New Collaborator</h3>

          <.simple_form
            for={@form}
            id="share-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="add_user"
          >
            <.input
              field={@form[:email]}
              type="email"
              label="Email Address"
              placeholder="Enter user's email address"
              required
            />
            <:actions>
              <.button phx-disable-with="Adding...">Add User</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{"email" => ""})
     end)}
  end

  @impl true
  def handle_event("validate", %{"email" => email}, socket) do
    form = to_form(%{"email" => email})
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("add_user", %{"email" => email}, socket) do
    case Accounts.get_user_by_email(email) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found with email: #{email}")}

      user ->
        if user.id == socket.assigns.shopping_list.creator_id do
          {:noreply, put_flash(socket, :error, "You cannot add yourself as a collaborator")}
        else
          case Shopping.add_user_to_shopping_list(socket.assigns.shopping_list, user) do
            {:ok, _} ->
              updated_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)
              send(self(), {:shopping_list_updated, updated_list})

              {:noreply,
               socket
               |> put_flash(:info, "User #{email} added successfully")
               |> assign(:form, to_form(%{"email" => ""}))}

            {:error, changeset} ->
              if changeset.errors[:user_id] do
                {:noreply, put_flash(socket, :error, "User is already a collaborator")}
              else
                {:noreply, put_flash(socket, :error, "Failed to add user")}
              end
          end
        end
    end
  end

  @impl true
  def handle_event("remove_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Shopping.remove_user_from_shopping_list(socket.assigns.shopping_list, user) do
      {1, _} ->
        updated_list = Shopping.get_shopping_list!(socket.assigns.shopping_list.id)
        send(self(), {:shopping_list_updated, updated_list})

        {:noreply, put_flash(socket, :info, "User removed successfully")}

      {0, _} ->
        {:noreply, put_flash(socket, :error, "User was not found in the list")}
    end
  end
end
