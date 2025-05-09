defmodule SupermarketsChain.ProductsRepositoryTest do
  use ExUnit.Case

  alias SupermarketsChain.Schemas.Product
  alias SupermarketsChain.ProductsRepository

  @products [
    {"SR1", %Product{code: "SR1", name: "Strawberries", price: Decimal.new("5.00")}},
    {"CF1", %Product{code: "CF1", name: "Coffee", price: Decimal.new("11.23")}},
    {"GR1", %Product{code: "GR1", name: "Green tea", price: Decimal.new("3.11")}}
  ]

  test "init/1 initializes the ets storage table for the repository" do
    assert {:ok, state, continuation} = ProductsRepository.init([])

    refute is_nil(state.storage_table_ref)
    assert continuation == {:continue, :hydrate_repo}
  end

  test "handle_continue/2 :hydrate_repo loads up the products" do
    {:ok, state, _} = ProductsRepository.init([])
    {:noreply, ^state} = ProductsRepository.handle_continue(:hydrate_repo, state)

    assert :ets.tab2list(state.storage_table_ref) == @products
  end

  test "list_products/0 lists all the products loaded in the repository" do
    {:ok, _} = ProductsRepository.start_link([])
    Process.sleep(50)
    expected = Enum.map(@products, &elem(&1, 1))

    assert ProductsRepository.list_products() == expected
  end

  describe "get_product/1" do
    test "returns the product from a valid product code" do
      {:ok, _} = ProductsRepository.start_link([])
      Process.sleep(50)
      result = ProductsRepository.get_product("CF1")

      assert result == %Product{code: "CF1", name: "Coffee", price: Decimal.new("11.23")}
    end

    test "returns nil on an invalid product code" do
      {:ok, _} = ProductsRepository.start_link([])
      Process.sleep(50)
      result = ProductsRepository.get_product("FOO")

      assert is_nil(result)
    end
  end
end
