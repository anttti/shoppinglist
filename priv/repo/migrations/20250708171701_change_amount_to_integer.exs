defmodule Shoppinglist.Repo.Migrations.ChangeAmountToInteger do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE shopping_list_items ALTER COLUMN amount DROP DEFAULT"
    execute "ALTER TABLE shopping_list_items ALTER COLUMN amount TYPE integer USING amount::integer"
    execute "ALTER TABLE shopping_list_items ALTER COLUMN amount SET DEFAULT 1"
  end
end
