defmodule SupermarketsChain.DiscountStrategies.BulkPurchase do
  @moduledoc """
  Defines a discount strategy for bulk purchases a percent discount is applied if the amount of units
  to be purchased is greater than or equal to a threshold

  e.g.
  15% off on purchases of 10 or more units 
  """

  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  def applicable?(%Item{} = item, %DiscountRule{} = rule) do
    threshold = Decimal.new(rule.conditions["min_threshold"])

    Decimal.gte?(item.count, threshold) and item.product_code == rule.product_code
  end

  def calculate_subtotal(%Item{} = item, %DiscountRule{} = rule) do
    multiplier = percent_multiplier(rule.conditions["percent_value"])
    subtotal = updated_subtotal(item, multiplier)

    %{item | subtotal: subtotal}
  end

  # Calculates the multiplier for percentual discounts
  # Assumues the percent_value is a value betwen 0 and 100
  # in a production system this is a constraint that would be validated
  # at data entry of the rule creation of the polymorphic embed
  defp percent_multiplier(percent_value) do
    "100"
    |> Decimal.sub(percent_value)
    |> Decimal.div("100")
  end

  defp updated_subtotal(item, multiplier) do
    discounted_unit_price = Decimal.mult(item.unit_price, multiplier)

    discounted_unit_price
    |> Decimal.mult(item.count)
    |> Decimal.round(2)
  end
end
