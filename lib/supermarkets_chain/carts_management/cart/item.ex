defmodule SupermarketsChain.CartsManagement.Cart.Item do
  @moduledoc """
  Struct for holding our cart item
  """

  defstruct product_code: nil,
            count: 0,
            unit_price: Decimal.new("0"),
            subtotal: Decimal.new("0")

  alias SupermarketsChain.Schemas.Product

  def new(%Product{} = product) do
    %__MODULE__{
      product_code: product.code,
      unit_price: product.price,
      subtotal: product.price,
      count: 1
    }
  end

  def increase_count(%__MODULE__{} = item) do
    new_count = item.count + 1
    %{item | count: new_count, subtotal: Decimal.mult(item.unit_price, new_count)}
  end

  def decrease_count(%__MODULE__{} = item) do
    new_count =
      if item.count - 1 < 0 do
        0
      else
        item.count - 1
      end

    if new_count > 0 do
      %{item | count: new_count, subtotal: Decimal.mult(item.unit_price, new_count)}
    else
      nil
    end
  end
end
