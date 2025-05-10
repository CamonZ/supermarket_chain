defmodule SupermarketsChain.ProductsRepository do
  @moduledoc """
  Defines a GenServer that acts as an interface to return the current list of products in the system
  as well as return the details of a specific product.

  It checks if a given product being added to a cart exists (by its code) and it can further be extended
  to check inventory existences of the given product
  """

  use GenServer

  alias SuperMarketsChain.DataLoader
  alias SupermarketsChain.Schemas.Product

  defstruct storage_table_ref: nil

  @table_name :products_repository

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list_products do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  def get_product(code) do
    @table_name
    |> :ets.lookup(code)
    |> List.first()
    |> elem(1)
  rescue
    _ ->
      nil
  end

  @impl true
  def init(_opts) do
    table_ref =
      case :ets.whereis(@table_name) do
        :undefined ->
          :ets.new(@table_name, [:set, :protected, :named_table, {:read_concurrency, true}])

        other when is_reference(other) ->
          other
      end

    {:ok, %__MODULE__{storage_table_ref: table_ref}, {:continue, :hydrate_repo}}
  end

  @impl true
  def handle_continue(:hydrate_repo, state) do
    data = DataLoader.load_products()

    products = data |> Enum.map(&Product.load/1) |> Keyword.get_values(:ok)

    Enum.each(products, fn product ->
      :ets.insert(state.storage_table_ref, {product.code, product})
    end)

    {:noreply, state}
  end
end
