defmodule Shoppinglist.Repo.Migrations.CreateShoppingListUsers do
  use Ecto.Migration

  def change do
    create table(:shopping_list_users) do
      add :shopping_list_id, references(:shopping_lists, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_list_users, [:shopping_list_id])
    create index(:shopping_list_users, [:user_id])
    create unique_index(:shopping_list_users, [:shopping_list_id, :user_id])
  end
end
