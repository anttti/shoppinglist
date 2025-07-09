defmodule Shoppinglist.ShoppingTest do
  use Shoppinglist.DataCase

  alias Shoppinglist.Shopping

  import Shoppinglist.AccountsFixtures

  defp shopping_list_fixture(user, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "name" => "Test Shopping List",
        "color" => "#FF0000"
      })

    {:ok, shopping_list} = Shopping.create_shopping_list(user, attrs)
    shopping_list
  end

  describe "shopping list item ordering" do
    setup do
      user = user_fixture()
      shopping_list = shopping_list_fixture(user)
      %{user: user, shopping_list: shopping_list}
    end

    test "get_shopping_list!/1 orders items by collected status first (not collected first), then by updated_at desc", %{shopping_list: shopping_list} do
      # Create items with different collected states
      {:ok, _collected_item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Collected Item", "amount" => 1, "collected" => true})
      {:ok, _not_collected_item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Not Collected Item", "amount" => 1, "collected" => false})

      # Fetch the shopping list with items
      fetched_list = Shopping.get_shopping_list!(shopping_list.id)

      # Extract collected status in the order they appear
      collected_statuses = Enum.map(fetched_list.items, & &1.collected)

      # Expected order: not collected items first (false), then collected items (true)
      expected_order = [false, true]

      assert collected_statuses == expected_order

      # Also verify the names are in the expected order
      item_names = Enum.map(fetched_list.items, & &1.name)
      assert item_names == ["Not Collected Item", "Collected Item"]
    end

    test "get_user_shopping_list!/2 orders items by collected status first (not collected first), then by updated_at desc", %{user: user, shopping_list: shopping_list} do
      # Create items with different collected states
      {:ok, _collected_item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Collected Item", "amount" => 1, "collected" => true})
      {:ok, _not_collected_item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Not Collected Item", "amount" => 1, "collected" => false})

      # Fetch the shopping list with items
      fetched_list = Shopping.get_user_shopping_list!(user, shopping_list.id)

      # Extract collected status in the order they appear
      collected_statuses = Enum.map(fetched_list.items, & &1.collected)

      # Expected order: not collected items first (false), then collected items (true)
      expected_order = [false, true]

      assert collected_statuses == expected_order

      # Also verify the names are in the expected order
      item_names = Enum.map(fetched_list.items, & &1.name)
      assert item_names == ["Not Collected Item", "Collected Item"]
    end

    test "items with same collected status are ordered by updated_at desc (newest first)", %{shopping_list: shopping_list} do
      # Create an item and then update it to ensure different updated_at
      {:ok, item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Original", "amount" => 1, "collected" => false})
      :timer.sleep(1000)
      {:ok, _another_item} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Another", "amount" => 1, "collected" => false})
      :timer.sleep(1000)

      # Update the first item to make it have a newer updated_at
      {:ok, _updated_item} = Shopping.update_shopping_list_item(item, %{"name" => "Updated"})

      fetched_list = Shopping.get_shopping_list!(shopping_list.id)
      item_names = Enum.map(fetched_list.items, & &1.name)

      # The updated item should come first (newest updated_at), then the other item
      assert List.first(item_names) == "Updated"
      assert "Another" in item_names
    end

    test "mixed collected and not collected items maintain proper ordering", %{shopping_list: shopping_list} do
      # Create a mix of collected and not collected items
      {:ok, _collected_1} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Collected 1", "amount" => 1, "collected" => true})
      {:ok, _not_collected_1} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Not Collected 1", "amount" => 1, "collected" => false})
      {:ok, _collected_2} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Collected 2", "amount" => 1, "collected" => true})
      {:ok, _not_collected_2} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Not Collected 2", "amount" => 1, "collected" => false})

      fetched_list = Shopping.get_shopping_list!(shopping_list.id)
      collected_statuses = Enum.map(fetched_list.items, & &1.collected)

      # Check that all not collected items come before all collected items
      not_collected_count = Enum.count(collected_statuses, &(&1 == false))

      # First part should be all false, second part should be all true
      first_part = Enum.take(collected_statuses, not_collected_count)
      second_part = Enum.drop(collected_statuses, not_collected_count)

      assert Enum.all?(first_part, &(&1 == false))
      assert Enum.all?(second_part, &(&1 == true))
    end

    test "changing collected status affects ordering", %{shopping_list: shopping_list} do
      # Create items - all initially not collected
      {:ok, _item1} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Item 1", "amount" => 1, "collected" => false})
      {:ok, item2} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Item 2", "amount" => 1, "collected" => false})
      {:ok, _item3} = Shopping.create_shopping_list_item(shopping_list, %{"name" => "Item 3", "amount" => 1, "collected" => false})

      # Initially all are not collected
      fetched_list = Shopping.get_shopping_list!(shopping_list.id)
      collected_statuses = Enum.map(fetched_list.items, & &1.collected)
      assert Enum.all?(collected_statuses, &(&1 == false))

      # Mark item2 as collected
      {:ok, _item2} = Shopping.update_shopping_list_item(item2, %{"collected" => true})

      # Now we should have 2 not collected items first, then 1 collected item
      fetched_list = Shopping.get_shopping_list!(shopping_list.id)
      collected_statuses = Enum.map(fetched_list.items, & &1.collected)

      # First two should be false, last one should be true
      assert Enum.take(collected_statuses, 2) == [false, false]
      assert Enum.at(collected_statuses, 2) == true
    end
  end
end
