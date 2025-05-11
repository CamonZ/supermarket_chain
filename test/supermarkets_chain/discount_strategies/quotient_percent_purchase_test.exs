defmodule SupermarketsChain.DiscountStrategies.QuotientPercentPurchaseTest do
  use ExUnit.Case, async: true

  alias SupermarketsChain.DiscountStrategies.QuotientPercentPurchase
  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  @base_item %Item{
    product_code: "CF1",
    count: 3,
    unit_price: Decimal.new("11.23"),
    subtotal: Decimal.new("33.69")
  }

  @base_rule %DiscountRule{
    product_code: "CF1",
    name: "Quotient Discount",
    rule_strategy: "quotient_percent_purchase",
    description: "2/3rds of the total on purchases for 3+ item",
    conditions: %{
      "min_threshold" => "3",
      "dividend" => "2",
      "divisor" => "3"
    }
  }

  describe "applicable?/2" do
    test "returns true when count >= min_threshold and product_code matches" do
      assert QuotientPercentPurchase.applicable?(@base_item, @base_rule)
    end

    test "returns false when count < min_threshold" do
      item = %{@base_item | count: 2}

      refute QuotientPercentPurchase.applicable?(item, @base_rule)
    end

    test "returns false when product_code does not match" do
      item = %{@base_item | product_code: "SR1"}
      refute QuotientPercentPurchase.applicable?(item, @base_rule)
    end
  end

  describe "calculate_subtotal/2" do
    test "applies quotient discount correctly" do
      item = QuotientPercentPurchase.calculate_subtotal(@base_item, @base_rule)

      assert item == %Item{
               product_code: "CF1",
               count: 3,
               unit_price: Decimal.new("11.23"),
               subtotal: Decimal.new("22.46")
             }
    end
  end
end
