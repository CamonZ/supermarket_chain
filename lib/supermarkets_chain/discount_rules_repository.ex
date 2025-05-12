defmodule SupermarketsChain.DiscountRulesRepository do
  @moduledoc """
  Defines a GenServer that acts as an interface to return the current list of
  discount rules applicable to different products
  """

  use GenServer

  alias SuperMarketsChain.DataLoader
  alias SupermarketsChain.Schemas.DiscountRule

  defstruct storage_table_ref: nil

  @table_name :discount_rules_repository

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def list_rules(opts \\ []) do
    table_name = Keyword.get(opts, :table_name, @table_name)

    table_name
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  def get_rule_for(product_code, opts \\ []) do
    table_name = Keyword.get(opts, :table_name, @table_name)

    table_name
    |> :ets.lookup(product_code)
    |> List.first()
    |> elem(1)
  rescue
    _ ->
      nil
  end

  @impl true
  def init(opts) do
    table_name = Keyword.get(opts, :table_name, @table_name)
    table_ref = :ets.new(table_name, [:bag, :protected, :named_table, {:read_concurrency, true}])

    {:ok, %__MODULE__{storage_table_ref: table_ref}, {:continue, :hydrate_repo}}
  end

  @impl true
  def handle_continue(:hydrate_repo, state) do
    data = DataLoader.load_rules()

    rules = data |> Enum.map(&DiscountRule.load/1) |> Keyword.get_values(:ok)

    Enum.each(rules, fn rule ->
      :ets.insert(state.storage_table_ref, {rule.product_code, rule})
    end)

    {:noreply, state}
  end
end
