defmodule SupermarketsChain.DiscountStrategies.QuotientPercentPurchase do
  @moduledoc """
  Defines a strategy with a percent off based on a quotient for purchases above a min threshold of items

  The conditions map for this scenario look like:

  %{"min_threshold" => "3", "dividend" => "2", "divisor" => "3"}

  e.g.
    All units at 2/3ths of the original price for purchases of 10 or more units
  """

  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.Schemas.DiscountRule

  def applicable?(%Item{} = item, %DiscountRule{} = rule) do
    threshold = Decimal.new(rule.conditions["min_threshold"])
    Decimal.gte?(item.count, threshold) and item.product_code == rule.product_code
  end

  def calculate_subtotal(%Item{} = item, %DiscountRule{} = rule) do
    dividend = Decimal.new(rule.conditions["dividend"])
    divisor = Decimal.new(rule.conditions["divisor"])

    updated_subtotal =
      item.subtotal
      |> Decimal.mult(dividend)
      |> Decimal.div(divisor)
      |> Decimal.round(2)

    %{item | subtotal: updated_subtotal}
  end
end
