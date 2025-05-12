defmodule SupermarketsChain.DiscountRulesRepositoryTest do
  use ExUnit.Case

  alias SupermarketsChain.Schemas.DiscountRule
  alias SupermarketsChain.DiscountRulesRepository

  @rules [
    {"GR1",
     %DiscountRule{
       name: "Green Tea Discount",
       product_code: "GR1",
       description: "2 for the price of 1",
       conditions: %{"min_threshold" => "2", "y_count" => "1"},
       rule_strategy: "x_for_the_price_of_y"
     }},
    {"SR1",
     %DiscountRule{
       name: "Bulk Strawberries Discount",
       description: "10% off when buying 3 or more",
       conditions: %{"min_threshold" => "3", "percent_value" => "10"},
       product_code: "SR1",
       rule_strategy: "bulk_purchase"
     }},
    {"CF1",
     %DiscountRule{
       name: "Coffee discount",
       description: "2/3 price when buying 3 or more",
       conditions: %{"dividend" => "2", "divisor" => "3", "min_threshold" => "3"},
       product_code: "CF1",
       rule_strategy: "quotient_percent"
     }}
  ]

  test "init/1 initializes the ets storage table for the repository", ctx do
    assert {:ok, state, continuation} = DiscountRulesRepository.init(table_name: ctx.test)

    refute is_nil(state.storage_table_ref)
    assert continuation == {:continue, :hydrate_repo}
  end

  test "handle_continue/2 :hydrate_repo loads up the products", ctx do
    {:ok, state, _} = DiscountRulesRepository.init(table_name: ctx.test)
    {:noreply, ^state} = DiscountRulesRepository.handle_continue(:hydrate_repo, state)

    expected = Enum.sort_by(@rules, &elem(&1, 1))
    result = :ets.tab2list(state.storage_table_ref) |> Enum.sort_by(&elem(&1, 1))

    assert result == expected
  end

  test "list_rules/0 lists all the discount rules loaded in the repository", ctx do
    DiscountRulesRepository.start_link(table_name: ctx.test, name: ctx.test)
    Process.sleep(50)

    expected = Enum.map(@rules, &elem(&1, 1)) |> Enum.sort_by(& &1.product_code)

    result =
      DiscountRulesRepository.list_rules(table_name: ctx.test) |> Enum.sort_by(& &1.product_code)

    assert result == expected
  end

  describe "get_rule_for/1" do
    test "returns the discount rule for a given product code", ctx do
      DiscountRulesRepository.start_link(table_name: ctx.test, name: ctx.test)
      Process.sleep(50)
      result = DiscountRulesRepository.get_rule_for("CF1", table_name: ctx.test)

      assert result == %DiscountRule{
               name: "Coffee discount",
               description: "2/3 price when buying 3 or more",
               conditions: %{"dividend" => "2", "divisor" => "3", "min_threshold" => "3"},
               product_code: "CF1",
               rule_strategy: "quotient_percent"
             }
    end

    test "returns nil on an invalid product code", ctx do
      DiscountRulesRepository.start_link(table_name: ctx.test, name: ctx.test)
      Process.sleep(50)
      result = DiscountRulesRepository.get_rule_for("FOO", table_name: ctx.test)

      assert is_nil(result)
    end
  end
end
