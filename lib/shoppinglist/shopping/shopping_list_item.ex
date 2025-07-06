defmodule Shoppinglist.Shopping.ShoppingListItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shoppinglist.Shopping.ShoppingList

  schema "shopping_list_items" do
    field :name, :string
    field :amount, :string
    field :collected, :boolean, default: false

    belongs_to :shopping_list, ShoppingList

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shopping_list_item, attrs) do
    shopping_list_item
    |> cast(attrs, [:name, :amount, :collected, :shopping_list_id])
    |> validate_required([:name, :amount, :shopping_list_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:amount, min: 1, max: 50)
    |> foreign_key_constraint(:shopping_list_id)
  end
end
