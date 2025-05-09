defmodule SupermarketsChain.CartsManagement.Cart.ItemTest do
  use ExUnit.Case, async: true
  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.Product

  describe "new/1" do
    test "creates a new cart item from product" do
      product = %Product{code: "SR1", price: Decimal.new("5.00")}
      item = Item.new(product)

      assert item.product_code == "SR1"
      assert item.unit_price == Decimal.new("5.00")
      assert item.count == 1
      assert item.subtotal == Decimal.new("5.00")
    end
  end

  describe "increase_count/1" do
    test "increases count and updates subtotal" do
      item = %Item{
        product_code: "SR1",
        unit_price: Decimal.new("5.00"),
        count: 2,
        subtotal: Decimal.new("10.00")
      }

      updated_item = Item.increase_count(item)

      assert updated_item.count == 3
      assert updated_item.subtotal == Decimal.new("15.00")
    end
  end

  describe "decrease_count/1" do
    test "decreases count and updates subtotal" do
      item = %Item{
        product_code: "SR1",
        unit_price: Decimal.new("5.00"),
        count: 2,
        subtotal: Decimal.new("10.00")
      }

      updated_item = Item.decrease_count(item)

      assert updated_item.count == 1
      assert updated_item.subtotal == Decimal.new("5.00")
    end

    test "returns nil if the items count gets to 0" do
      item = %Item{
        product_code: "SR1",
        unit_price: Decimal.new("5.00"),
        count: 0,
        subtotal: Decimal.new("0.00")
      }

      assert is_nil(Item.decrease_count(item))
    end
  end
end
