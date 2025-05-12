defmodule SupermarketsChain.DiscountStrategies.XForThePriceOfYPurchaseTest do
  use ExUnit.Case, async: true

  alias SupermarketsChain.DiscountStrategies.XForThePriceOfYPurchase
  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  @base_item %Item{
    product_code: "GR1",
    count: 3,
    unit_price: Decimal.new("3.11"),
    subtotal: Decimal.new("9.33")
  }

  @base_rule %DiscountRule{
    product_code: "GR1",
    name: "3 for 2",
    rule_strategy: "x_for_the_price_of_y_purchase",
    description: "Buy 3 pay for 2",
    conditions: %{
      "min_threshold" => "3",
      "y_count" => "2"
    }
  }

  describe "applicable?/2" do
    test "returns true when product code matches and count >= min_threshold" do
      assert XForThePriceOfYPurchase.applicable?(@base_item, @base_rule) == true
    end

    test "returns false when count < min_threshold" do
      item = %{@base_item | count: 2}
      refute XForThePriceOfYPurchase.applicable?(item, @base_rule)
    end

    test "returns false when product_code does not match" do
      item = %{@base_item | product_code: "CF1"}
      refute XForThePriceOfYPurchase.applicable?(item, @base_rule)
    end
  end

  describe "calculate_subtotal/2" do
    test "updates the item with the new subtotal" do
      updated_item = XForThePriceOfYPurchase.calculate_subtotal(@base_item, @base_rule)

      assert updated_item == %Item{
               product_code: "GR1",
               count: 3,
               unit_price: Decimal.new("3.11"),
               subtotal: Decimal.new("6.22")
             }
    end

    test "calculates correctly when there's a remainder" do
      item = %{@base_item | count: 5}

      updated_item = XForThePriceOfYPurchase.calculate_subtotal(item, @base_rule)

      assert updated_item == %Item{
               product_code: "GR1",
               count: 5,
               unit_price: Decimal.new("3.11"),
               subtotal: Decimal.new("12.44")
             }
    end
  end
end
