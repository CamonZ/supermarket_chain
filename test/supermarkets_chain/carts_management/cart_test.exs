defmodule SupermarketsChain.CartsManagement.CartTest do
  use ExUnit.Case

  alias SupermarketsChain.CartsManagement.Manager
  alias SupermarketsChain.CartsManagement.Cart
  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.ProductsRepository
  alias SupermarketsChain.DiscountRulesRepository

  setup_all do
    {:ok, _} = Registry.start_link(keys: :unique, name: Manager.registry_name())
    ProductsRepository.start_link([])
    DiscountRulesRepository.start_link([])

    Process.sleep(100)
    :ok
  end

  test "start_link/1 spawns a new shopping cart" do
    uuid = Ecto.UUID.generate()

    assert {:ok, pid} = Cart.start_link(uuid: uuid, name: TestCart)

    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  describe "add_product/2" do
    test "adds a new product to a cart and returns the items in the cart" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      {:ok, items} = Cart.add_product(uuid, "CF1")

      assert Map.get(items, "CF1") == %Item{
               product_code: "CF1",
               count: 1,
               unit_price: Decimal.new("11.23"),
               subtotal: Decimal.new("11.23")
             }
    end

    test "increases the count of items for an already existing product" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}

      items = %{
        "CF1" => %Item{
          product_code: "CF1",
          count: 1,
          unit_price: Decimal.new("11.23"),
          subtotal: Decimal.new("11.23")
        }
      }

      {:ok, _} = Cart.start_link(uuid: uuid, name: name, items: items)

      {:ok, items} = Cart.add_product(uuid, "CF1")

      assert Map.get(items, "CF1") == %Item{
               product_code: "CF1",
               count: 2,
               unit_price: Decimal.new("11.23"),
               subtotal: Decimal.new("22.46")
             }
    end

    test "adds a secondary product to the cart" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}

      items = %{
        "CF1" => %Item{
          product_code: "CF1",
          count: 1,
          unit_price: Decimal.new("11.23"),
          subtotal: Decimal.new("11.23")
        }
      }

      {:ok, _} = Cart.start_link(uuid: uuid, name: name, items: items)

      {:ok, items} = Cart.add_product(uuid, "SR1")

      assert items == %{
               "CF1" => %Item{
                 product_code: "CF1",
                 count: 1,
                 unit_price: Decimal.new("11.23"),
                 subtotal: Decimal.new("11.23")
               },
               "SR1" => %Item{
                 product_code: "SR1",
                 count: 1,
                 unit_price: Decimal.new("5.00"),
                 subtotal: Decimal.new("5.00")
               }
             }
    end

    test "returns an error when the cart doesn't exist" do
      assert {:error, "invalid_cart_id"} = Cart.add_product(Ecto.UUID.generate(), "CF1")
    end

    test "returns an error when the product doesn't exist" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      assert {:error, "invalid_product_code"} == Cart.add_product(uuid, "FOO1")
    end
  end

  describe "remove_product/2" do
    test "decreases the count of items of an already existing product if the count is greater than 1" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}

      items = %{
        "CF1" => %Item{
          product_code: "CF1",
          count: 2,
          unit_price: Decimal.new("11.23"),
          subtotal: Decimal.new("22.46")
        }
      }

      {:ok, _} = Cart.start_link(uuid: uuid, name: name, items: items)

      {:ok, items} = Cart.remove_product(uuid, "CF1")

      assert items == %{
               "CF1" => %Item{
                 product_code: "CF1",
                 count: 1,
                 unit_price: Decimal.new("11.23"),
                 subtotal: Decimal.new("11.23")
               }
             }
    end

    test "leaves the items unchanged if the product is not in the list of items in the cart" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}

      items = %{
        "CF1" => %Item{
          product_code: "CF1",
          count: 2,
          unit_price: Decimal.new("11.23"),
          subtotal: Decimal.new("22.46")
        }
      }

      {:ok, _} = Cart.start_link(uuid: uuid, name: name, items: items)

      assert {:ok, %{}} = Cart.remove_product(uuid, "SR1")
    end

    test "deletes the item for the product if the count gets to 0" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}

      items = %{
        "CF1" => %Item{
          product_code: "CF1",
          count: 1,
          unit_price: Decimal.new("11.23"),
          subtotal: Decimal.new("11.23")
        }
      }

      {:ok, _} = Cart.start_link(uuid: uuid, name: name, items: items)

      assert {:ok, %{}} = Cart.remove_product(uuid, "CF1")
    end
  end

  describe "calculate_total/1" do
    test "returns the correct total for scenario 1" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "SR1")
      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "CF1")

      assert {:ok, Decimal.new("22.45")} == Cart.calculate_total(uuid)
    end

    test "returns the correct total for scenario 2" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "GR1")

      assert {:ok, Decimal.new("3.11")} == Cart.calculate_total(uuid)
    end

    test "returns the correct total for scenario 3" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      Cart.add_product(uuid, "SR1")
      Cart.add_product(uuid, "SR1")
      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "SR1")

      assert {:ok, Decimal.new("16.61")} == Cart.calculate_total(uuid)
    end

    test "returns the correct total for scenario 4" do
      uuid = Ecto.UUID.generate()
      name = {:via, Registry, {Manager.registry_name(), uuid}}
      {:ok, _} = Cart.start_link(uuid: uuid, name: name)

      Cart.add_product(uuid, "GR1")
      Cart.add_product(uuid, "CF1")
      Cart.add_product(uuid, "SR1")
      Cart.add_product(uuid, "CF1")
      Cart.add_product(uuid, "CF1")

      assert {:ok, Decimal.new("30.57")} == Cart.calculate_total(uuid)
    end
  end
end
