defmodule SupermarketsChain.Schemas.DiscountRuleTest do
  use ExUnit.Case, async: true

  alias SupermarketsChain.Schemas.DiscountRule
  alias SupermarketsChain.DiscountStrategies.BulkPurchase
  alias SupermarketsChain.DiscountStrategies.QuotientPercentPurchase
  alias SupermarketsChain.DiscountStrategies.XForThePriceOfYPurchase

  @valid_attrs %{
    product_code: "CF1",
    name: "Coffee Deal",
    rule_strategy: "bulk_purchase",
    description: "Buy more, save more",
    conditions: %{"min_threshold" => "3", "percent_value" => "10"}
  }

  describe "changeset/2" do
    test "returns a valid changeset for correct attributes" do
      changeset = DiscountRule.changeset(%DiscountRule{}, @valid_attrs)

      assert changeset.valid?
      assert changeset.changes.product_code == "CF1"
    end

    test "returns an invalid changeset when required fields are missing" do
      changeset = DiscountRule.changeset(%DiscountRule{}, %{})

      refute changeset.valid?

      assert changeset.errors == [
               product_code: {"can't be blank", [validation: :required]},
               name: {"can't be blank", [validation: :required]},
               rule_strategy: {"can't be blank", [validation: :required]},
               description: {"can't be blank", [validation: :required]},
               conditions: {"can't be blank", [validation: :required]}
             ]
    end
  end

  describe "load/1" do
    test "returns {:ok, rule} when valid data is given" do
      assert {:ok, %DiscountRule{} = rule} = DiscountRule.load(@valid_attrs)
      assert rule.name == "Coffee Deal"
    end

    test "returns {:error, _} when invalid data is given" do
      assert {:error, "invalid_data"} = DiscountRule.load(%{name: "No Product Code"})
    end
  end

  describe "strategy_implementation_for/1" do
    test "returns correct module for bulk_purchase" do
      assert BulkPurchase ==
               DiscountRule.strategy_implementation_for(%DiscountRule{
                 rule_strategy: "bulk_purchase"
               })
    end

    test "returns correct module for quotient_percent" do
      assert QuotientPercentPurchase ==
               DiscountRule.strategy_implementation_for(%DiscountRule{
                 rule_strategy: "quotient_percent"
               })
    end

    test "returns correct module for x_for_the_price_of_y" do
      assert XForThePriceOfYPurchase ==
               DiscountRule.strategy_implementation_for(%DiscountRule{
                 rule_strategy: "x_for_the_price_of_y"
               })
    end

    test "returns nil for unknown strategy" do
      assert is_nil(
               DiscountRule.strategy_implementation_for(%DiscountRule{
                 rule_strategy: "non_existing"
               })
             )
    end
  end
end
