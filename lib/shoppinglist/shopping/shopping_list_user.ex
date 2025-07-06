defmodule Shoppinglist.Shopping.ShoppingListUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shoppinglist.Accounts.User
  alias Shoppinglist.Shopping.ShoppingList

  schema "shopping_list_users" do
    belongs_to :shopping_list, ShoppingList
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shopping_list_user, attrs) do
    shopping_list_user
    |> cast(attrs, [:shopping_list_id, :user_id])
    |> validate_required([:shopping_list_id, :user_id])
    |> foreign_key_constraint(:shopping_list_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:shopping_list_id, :user_id])
  end
end
