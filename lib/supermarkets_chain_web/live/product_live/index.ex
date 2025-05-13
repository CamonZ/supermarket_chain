defmodule SupermarketsChainWeb.ProductsLive.Index do
  use SupermarketsChainWeb, :live_view

  alias SupermarketsChain.ProductsRepository
  alias SupermarketsChain.CartsManagement.Manager
  alias SupermarketsChain.CartsManagement.Cart

  @impl true
  def mount(_params, _session, socket) do
    {:ok, cart_id} = Manager.create_cart()

    socket =
      socket
      |> assign(:products, ProductsRepository.list_products())
      |> assign(:cart_items_count, 0)
      |> assign(:display_cart, false)
      |> assign(:items, [])
      |> assign(:cart_total, Decimal.new("0"))
      |> assign(:cart_id, cart_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("add-to-cart", %{"product-code" => product_code}, socket) do
    cart_id = socket.assigns.cart_id

    socket =
      case Cart.add_product(cart_id, product_code) do
        {:ok, items} ->
          socket
          |> assign(:cart_items_count, Cart.total_items(Map.values(items)))
          |> assign(:items, Map.values(items))
          |> assign(:cart_total, Cart.calculate_total(Map.values(items)))

        {:error, _} ->
          put_flash(socket, :error, "There was a problem adding the item to the cart")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-cart", _, socket) do
    {:noreply, assign(socket, :display_cart, true)}
  end
end
