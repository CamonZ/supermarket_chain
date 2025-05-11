defmodule SupermarketsChain.DiscountStrategies.BulkPurchaseTest do
  use ExUnit.Case, async: true

  alias SupermarketsChain.DiscountStrategies.BulkPurchase
  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  @base_item %Item{
    product_code: "SR1",
    count: 5,
    unit_price: Decimal.new("5.00"),
    subtotal: Decimal.new("25.00")
  }

  @base_rule %DiscountRule{
    product_code: "SR1",
    name: "Bulk Discount",
    rule_strategy: "bulk_purchase",
    description: "10% off on 3+ units",
    conditions: %{
      "min_threshold" => "3",
      "percent_value" => "10"
    }
  }

  describe "applicable?/2" do
    test "returns true when product code matches and count >= min_threshold" do
      assert BulkPurchase.applicable?(@base_item, @base_rule) == true
    end

    test "returns false when count < min_threshold" do
      item = %{@base_item | count: 2}
      refute BulkPurchase.applicable?(item, @base_rule)
    end

    test "returns false when product_code does not match" do
      item = %{@base_item | product_code: "CF1"}
      refute BulkPurchase.applicable?(item, @base_rule)
    end
  end

  describe "calculate_subtotal/2" do
    test "updates the item with the new subtotal" do
      updated_item = BulkPurchase.calculate_subtotal(@base_item, @base_rule)

      assert updated_item == %Item{
               product_code: "SR1",
               count: 5,
               unit_price: Decimal.new("5.00"),
               subtotal: Decimal.new("22.50")
             }
    end

    test "calculates correctly with different percent_value and threshold" do
      item = %{@base_item | count: 20}
      rule = %{@base_rule | conditions: %{"min_threshold" => "15", "percent_value" => "25"}}

      updated_item = BulkPurchase.calculate_subtotal(item, rule)

      assert updated_item == %Item{
               product_code: "SR1",
               count: 20,
               unit_price: Decimal.new("5.00"),
               subtotal: Decimal.new("75.00")
             }
    end
  end
end
