defmodule SupermarketsChain.CartsManagement.Cart do
  @moduledoc """
  The shopping cart itself

  It holds CartItems which are a composite type of a Product and a multiplier indicating
  how many instances of a given product the user has added to the cart.

  It deals with adding and removing items from the cart as well as increasing
  or decreasing its count.
  """

  use GenServer

  alias SupermarketsChain.CartsManagement.Cart.Item
  alias SupermarketsChain.CartsManagement.Manager
  alias SupermarketsChain.ProductsRepository
  alias SupermarketsChain.Schemas.Product

  defstruct items: %{}, cart_id: nil

  def start_link(opts) do
    {:ok, name} = Keyword.fetch(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def add_product(uuid, code) do
    with {:cart_lookup, {:ok, pid}} <- lookup_cart(uuid),
         {:product_lookup, {:ok, product}} <- lookup_product(code) do
      GenServer.call(pid, {:add_product, product})
    else
      {_, error} ->
        error
    end
  end

  def remove_product(uuid, code) do
    with {:cart_lookup, {:ok, pid}} <- lookup_cart(uuid),
         {:product_lookup, {:ok, product}} <- lookup_product(code) do
      GenServer.call(pid, {:remove_product, product})
    else
      {_, error} ->
        error
    end
  end

  def child_spec(opts) do
    {:ok, uuid} = Keyword.fetch(opts, :uuid)
    {:ok, registry} = Keyword.fetch(opts, :registry)

    name = {:via, Registry, {registry, uuid}}

    %{
      id: {__MODULE__, uuid},
      start: {__MODULE__, :start_link, [[uuid: uuid, name: name]]}
    }
  end

  @impl true
  def init(opts) do
    {:ok, uuid} = Keyword.fetch(opts, :uuid)
    items = Keyword.get(opts, :items, %{})

    {:ok, %__MODULE__{cart_id: uuid, items: items}}
  rescue
    _ ->
      {:stop, "missing_cart_id"}
  end

  @impl true
  def handle_call(:get_products, _, state) do
    {:reply, {:ok, state.items}, state}
  end

  @impl true
  def handle_call({:add_product, product}, _, state) do
    item = cart_item_from_added_product(state.items, product)
    items = Map.put(state.items, product.code, item)

    {:reply, {:ok, items}, %{state | items: items}}
  end

  @impl true
  def handle_call({:remove_product, product}, _, state) do
    item = cart_item_from_removed_product(state.items, product)

    items =
      if is_nil(item) do
        Map.delete(state.items, product.code)
      else
        Map.put(state.items, product.code, item)
      end

    {:reply, {:ok, items}, %{state | items: items}}
  end

  defp cart_item_from_added_product(items, product) do
    if Map.has_key?(items, product.code) do
      increase_cart_item_count(items, product)
    else
      Item.new(product)
    end
  end

  defp cart_item_from_removed_product(items, product) do
    if Map.has_key?(items, product.code) do
      decrease_cart_item_count(items, product)
    else
      nil
    end
  end

  defp increase_cart_item_count(items, product) do
    items
    |> Map.get(product.code)
    |> Item.increase_count()
  end

  defp decrease_cart_item_count(items, product) do
    items
    |> Map.get(product.code)
    |> Item.decrease_count()
  end

  defp lookup_cart(uuid) do
    case Manager.lookup_cart(uuid) do
      {:ok, pid} ->
        {:cart_lookup, {:ok, pid}}

      _ ->
        {:cart_lookup, {:error, "invalid_cart_id"}}
    end
  end

  defp lookup_product(code) do
    case ProductsRepository.get_product(code) do
      nil ->
        {:product_lookup, {:error, "invalid_product_code"}}

      %Product{} = product ->
        {:product_lookup, {:ok, product}}
    end
  end
end
