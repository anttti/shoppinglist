defmodule Shoppinglist.Repo.Migrations.CreateShoppingListItems do
  use Ecto.Migration

  def change do
    create table(:shopping_list_items) do
      add :name, :string, null: false
      add :amount, :string, null: false, default: "1"
      add :collected, :boolean, null: false, default: false
      add :shopping_list_id, references(:shopping_lists, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_list_items, [:shopping_list_id])
  end
end
