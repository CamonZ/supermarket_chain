defmodule SupermarketsChain.Schemas.ProductTest do
  use ExUnit.Case, async: true

  alias SupermarketsChain.Schemas.Product

  describe "changeset/2" do
    test "returns a valid changeset" do
      attrs = %{"code" => "123", "name" => "Milk", "price" => Decimal.new("1.99")}
      changeset = Product.changeset(%Product{}, attrs)

      assert changeset.valid?
    end

    test "validates that all fields are present" do
      attrs = %{"code" => "123"}
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"], price: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "load/1" do
    test "successfully loads a valid product" do
      attrs = %{"code" => "123", "name" => "Milk", "price" => Decimal.new("1.99")}
      assert {:ok, %Product{code: "123", name: "Milk", price: %Decimal{}}} = Product.load(attrs)
    end

    test "fails to load an invalid product" do
      attrs = %{"code" => "123"}
      assert {:error, "invalid_data"} = Product.load(attrs)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
