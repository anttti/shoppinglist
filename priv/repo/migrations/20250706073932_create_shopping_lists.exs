defmodule Shoppinglist.Repo.Migrations.CreateShoppingLists do
  use Ecto.Migration

  def change do
    create table(:shopping_lists) do
      add :name, :string, null: false
      add :color, :string, null: false, default: "#3B82F6"
      add :creator_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_lists, [:creator_id])
  end
end
