defmodule SupermarketsChain.DiscountStrategies.XForThePriceOfYPurchase do
  @moduledoc """
  Defines a discount strategy for bundled purchases where X amount of products in a shopping cart
  are priced lower as if it were a lower amount of units purchase.

  e.g.
    2 for the price of 1
    3 for the price of 2
    10 for the price of 9
  """

  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  def applicable?(%Item{} = item, %DiscountRule{} = rule) do
    threshold = Decimal.new(rule.conditions["min_threshold"])
    Decimal.gte?(item.count, threshold) and item.product_code == rule.product_code
  end

  def calculate_subtotal(%Item{} = item, %DiscountRule{} = rule) do
    threshold = Decimal.new(rule.conditions["min_threshold"])
    count_substitution = Decimal.new(rule.conditions["y_count"])
    items_count = updated_count(item.count, threshold, count_substitution)

    %{item | subtotal: Decimal.mult(item.unit_price, items_count)}
  end

  defp updated_count(original_count, threshold, substitution) do
    {modulo, remainder} = Decimal.div_rem(original_count, threshold)
    updated_modulo = Decimal.mult(modulo, substitution)

    Decimal.add(updated_modulo, remainder)
  end
end
