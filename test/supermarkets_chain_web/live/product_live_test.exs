defmodule SupermarketsChainWeb.ProductLiveTest do
  use SupermarketsChainWeb.ConnCase

  import Phoenix.LiveViewTest

  alias SupermarketsChain.DiscountRulesRepository
  alias SupermarketsChain.ProductsRepository
  alias SupermarketsChain.CartsManagement.Manager

  setup_all do
    ProductsRepository.start_link([])
    DiscountRulesRepository.start_link([])
    Manager.start_link([])

    Process.sleep(100)

    :ok
  end

  test "displays the list of products", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ".product-CF1")
    assert has_element?(view, ".product-CF1 > h3.product-name", "Coffee")
    assert has_element?(view, ".product-CF1 > button.add-to-cart-button", "Add to Cart")

    assert has_element?(view, ".product-SR1")
    assert has_element?(view, ".product-SR1 > h3.product-name", "Strawberries")
    assert has_element?(view, ".product-SR1 > button.add-to-cart-button", "Add to Cart")

    assert has_element?(view, ".product-GR1")
    assert has_element?(view, ".product-GR1 h3.product-name", "Green tea")
    assert has_element?(view, ".product-GR1 > button.add-to-cart-button", "Add to Cart")
  end

  test "adds an item to the shopping cart", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ".show-cart-toggle")
    assert has_element?(view, ".show-cart-toggle > span.shopping-cart-items-count", "0")

    view
    |> element(".product-SR1 > button.add-to-cart-button")
    |> render_click()

    assert has_element?(view, ".show-cart-toggle > span.shopping-cart-items-count", "1")

    view
    |> element(".product-SR1 > button.add-to-cart-button")
    |> render_click()

    view
    |> element(".product-SR1 > button.add-to-cart-button")
    |> render_click()

    assert has_element?(view, ".show-cart-toggle > span.shopping-cart-items-count", "3")
  end

  test "displays the subtotal per item and the total of the shopping cart", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element(".product-SR1 > button.add-to-cart-button")
    |> render_click()

    view
    |> element(".product-GR1 > button.add-to-cart-button")
    |> render_click()

    view
    |> element(".product-GR1 > button.add-to-cart-button")
    |> render_click()

    view
    |> element(".show-cart-toggle")
    |> render_click()

    assert has_element?(view, ".cart-items-container")

    assert has_element?(view, ".cart-item-SR1 .cart-item-name", "Strawberries")
    assert has_element?(view, ".cart-item-SR1 .cart-item-count", "1")
    assert has_element?(view, ".cart-item-SR1 .cart-item-subtotal", "£5.00")

    assert has_element?(view, ".cart-item-GR1 .cart-item-name", "Green tea")
    assert has_element?(view, ".cart-item-GR1 .cart-item-count", "2")
    assert has_element?(view, ".cart-item-GR1 .cart-item-subtotal", "£3.11")

    assert has_element?(view, ".cart-items-container .cart-total", "£8.11")
  end
end
