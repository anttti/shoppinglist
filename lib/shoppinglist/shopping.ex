defmodule Shoppinglist.Shopping do
  @moduledoc """
  The Shopping context.
  """

  import Ecto.Query, warn: false
  alias Shoppinglist.Repo
  alias Shoppinglist.Shopping.{ShoppingList, ShoppingListItem, ShoppingListUser}
  alias Shoppinglist.Accounts.User

  ## Shopping Lists

  @doc """
  Returns the list of shopping lists for a given user.
  """
  def list_shopping_lists(%User{} = user) do
    from(sl in ShoppingList,
      left_join: slu in ShoppingListUser,
      on: sl.id == slu.shopping_list_id,
      where: sl.creator_id == ^user.id or slu.user_id == ^user.id,
      distinct: sl.id,
      order_by: [desc: sl.updated_at]
    )
    |> Repo.all()
    |> Repo.preload([:creator, :users])
  end

  @doc """
  Gets a single shopping list.
  """
  def get_shopping_list!(id) do
    Repo.get!(ShoppingList, id)
    |> Repo.preload([:creator, :users, :items])
  end

  @doc """
  Gets a shopping list that the user has access to.
  """
  def get_user_shopping_list!(%User{} = user, id) do
    from(sl in ShoppingList,
      left_join: slu in ShoppingListUser,
      on: sl.id == slu.shopping_list_id,
      where: sl.id == ^id and (sl.creator_id == ^user.id or slu.user_id == ^user.id),
      distinct: sl.id
    )
    |> Repo.one!()
    |> Repo.preload([:creator, :users, :items])
  end

  @doc """
  Creates a shopping list.
  """
  def create_shopping_list(%User{} = user, attrs \\ %{}) do
    %ShoppingList{}
    |> ShoppingList.changeset(Map.put(attrs, "creator_id", user.id))
    |> Repo.insert()
  end

  @doc """
  Updates a shopping list.
  """
  def update_shopping_list(%ShoppingList{} = shopping_list, attrs) do
    shopping_list
    |> ShoppingList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shopping list.
  """
  def delete_shopping_list(%ShoppingList{} = shopping_list) do
    Repo.delete(shopping_list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shopping list changes.
  """
  def change_shopping_list(%ShoppingList{} = shopping_list, attrs \\ %{}) do
    ShoppingList.changeset(shopping_list, attrs)
  end

  ## Shopping List Items

  @doc """
  Returns the list of shopping list items for a shopping list.
  """
  def list_shopping_list_items(%ShoppingList{} = shopping_list) do
    from(sli in ShoppingListItem,
      where: sli.shopping_list_id == ^shopping_list.id,
      order_by: [asc: sli.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single shopping list item.
  """
  def get_shopping_list_item!(id) do
    Repo.get!(ShoppingListItem, id)
  end

  @doc """
  Creates a shopping list item.
  """
  def create_shopping_list_item(%ShoppingList{} = shopping_list, attrs \\ %{}) do
    %ShoppingListItem{}
    |> ShoppingListItem.changeset(Map.put(attrs, "shopping_list_id", shopping_list.id))
    |> Repo.insert()
  end

  @doc """
  Updates a shopping list item.
  """
  def update_shopping_list_item(%ShoppingListItem{} = shopping_list_item, attrs) do
    shopping_list_item
    |> ShoppingListItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shopping list item.
  """
  def delete_shopping_list_item(%ShoppingListItem{} = shopping_list_item) do
    Repo.delete(shopping_list_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shopping list item changes.
  """
  def change_shopping_list_item(%ShoppingListItem{} = shopping_list_item, attrs \\ %{}) do
    ShoppingListItem.changeset(shopping_list_item, attrs)
  end

  ## Shopping List Users

  @doc """
  Adds a user to a shopping list.
  """
  def add_user_to_shopping_list(%ShoppingList{} = shopping_list, %User{} = user) do
    %ShoppingListUser{}
    |> ShoppingListUser.changeset(%{shopping_list_id: shopping_list.id, user_id: user.id})
    |> Repo.insert()
  end

  @doc """
  Removes a user from a shopping list.
  """
  def remove_user_from_shopping_list(%ShoppingList{} = shopping_list, %User{} = user) do
    from(slu in ShoppingListUser,
      where: slu.shopping_list_id == ^shopping_list.id and slu.user_id == ^user.id
    )
    |> Repo.delete_all()
  end

  @doc """
  Checks if a user has access to a shopping list.
  """
  def user_has_access?(%User{} = user, %ShoppingList{} = shopping_list) do
    if shopping_list.creator_id == user.id do
      true
    else
      from(slu in ShoppingListUser,
        where: slu.shopping_list_id == ^shopping_list.id and slu.user_id == ^user.id
      )
      |> Repo.exists?()
    end
  end

  @doc """
  Publishes a shopping list update to all subscribers.
  """
  def broadcast_shopping_list_update(%ShoppingList{} = shopping_list, event) do
    Phoenix.PubSub.broadcast(
      Shoppinglist.PubSub,
      "shopping_list:#{shopping_list.id}",
      {event, shopping_list}
    )
  end

  @doc """
  Publishes a shopping list item update to all subscribers.
  """
  def broadcast_shopping_list_item_update(%ShoppingListItem{} = item, event) do
    Phoenix.PubSub.broadcast(
      Shoppinglist.PubSub,
      "shopping_list:#{item.shopping_list_id}",
      {event, item}
    )
  end

  @doc """
  Subscribes to shopping list updates.
  """
  def subscribe_to_shopping_list(shopping_list_id) do
    Phoenix.PubSub.subscribe(Shoppinglist.PubSub, "shopping_list:#{shopping_list_id}")
  end
end
