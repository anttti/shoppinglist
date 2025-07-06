defmodule Shoppinglist.Shopping.ShoppingList do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shoppinglist.Accounts.User
  alias Shoppinglist.Shopping.{ShoppingListItem, ShoppingListUser}

  schema "shopping_lists" do
    field :name, :string
    field :color, :string

    belongs_to :creator, User
    has_many :items, ShoppingListItem, on_delete: :delete_all, preload_order: [asc: :inserted_at]
    has_many :shopping_list_users, ShoppingListUser, on_delete: :delete_all
    has_many :users, through: [:shopping_list_users, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shopping_list, attrs) do
    shopping_list
    |> cast(attrs, [:name, :color, :creator_id])
    |> validate_required([:name, :color, :creator_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color")
    |> foreign_key_constraint(:creator_id)
  end
end
