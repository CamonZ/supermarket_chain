defmodule SupermarketsChain.Schemas.DiscountRule do
  @moduledoc """
  Struct for holding our schema of a discount rule

  Discount rules are applicable to a given CartItem once
  the product code of the cart item matches the product_code
  of the discount rule and the amount of units in the cart item is above
  a `conditions.min_threshold` value of the discount rule

  The rule conditions could be further extended. For example:

  Our sales team wants to encourage small purchases such as 2x1 discounts
  but we don't want to apply a flat out 50% discount under the same rule for
  purchases of 50 units. (conditions.max_threshold)

  Another scenario where this might be extended and in the same vein as the previous
  example is that multiple rules might be applicable to a given cart item
  at a given point in time, in that scenario we might want to add a
  `conditions.priority` value to a given rule so we know that the rule with the highest
  priority takes precedence and should be the one applied.

  A third example would be corporate discounts where a certain discount is
  applied to a given customer if the customer belongs to a special
  category. e.g. corporate, frequent customer, discount club member, etc (`conditions.applicable_category`)

  In all of these cases we have a `conditions` embed that would have all
  the required conditions for the rule to be applicable

  And the module implementing the specific rule type would implement
  the evaluation of the conditions to determine whether the rule is applicable
  or not.

  Another alternative would be to use Polymorphic Embeds for the conditions map
  and use Protocols for the rule validation and calculation of the applicable discount
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SupermarketsChain.DiscountStrategies.BulkPurchase
  alias SupermarketsChain.DiscountStrategies.QuotientPercentPurchase
  alias SupermarketsChain.DiscountStrategies.XForThePriceOfYPurchase

  @rule_strategies_to_implementation %{
    "bulk_purchase" => BulkPurchase,
    "quotient_percent" => QuotientPercentPurchase,
    "x_for_the_price_of_y" => XForThePriceOfYPurchase
  }

  @required_fields ~w(product_code name rule_strategy description conditions)a

  @primary_key false

  embedded_schema do
    field(:product_code, :string)
    field(:name, :string)
    field(:rule_strategy, :string)
    field(:description, :string)
    field(:conditions, :map)
  end

  def changeset(%__MODULE__{} = product, attrs) do
    product
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def load(attrs) do
    ch = changeset(%__MODULE__{}, attrs)

    case ch.valid? do
      true ->
        {:ok, apply_changes(ch)}

      false ->
        {:error, "invalid_data"}
    end
  end

  def strategy_implementation_for(%__MODULE__{} = rule) do
    Map.get(@rule_strategies_to_implementation, rule.rule_strategy)
  end
end
