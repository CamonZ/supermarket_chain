defmodule SupermarketsChain.ProductsRepositoryTest do
  use ExUnit.Case, async: true

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

  describe "with data already loaded" do
    setup do
      {:ok, state, _} = ProductsRepository.init([])
      ProductsRepository.handle_continue(:hydrate_repo, state)

      {:ok, state: state}
    end

    test "handle_call/3 :list_products lists all the products loaded in the repository", ctx do
      expected = Enum.map(@products, &elem(&1, 1))

      assert {:reply, reply, _} =
               ProductsRepository.handle_call(:list_products, self(), ctx.state)

      assert reply == expected
    end

    test "handle_call/3 :get_product returns the details of a product", ctx do
      assert {:reply, reply, _} =
               ProductsRepository.handle_call({:get_product, "CF1"}, self(), ctx.state)

      assert reply == %Product{code: "CF1", name: "Coffee", price: Decimal.new("11.23")}
    end
  end
end
