# SupermarketsChain

Start the Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To run the tests you simply need to run mix test

## System Description:

The system is composed of multiple modules. 

For data loading from our sample data
we have the modules `ProductsRepository` and `DiscountRulesRepository`, these 
load data from JSON files stored in the application's `priv` dir and contain
our products as well as the discount rules the system has.

The storage of this data is kept in protected ETS tables that are read-accessible to any
process in the application and are optimized for read-concurrency.

The products and discount rules are loaded from JSON and validated through the use of Ecto
embedded schemas. In a real production scenario these two components would be redundant and instead be a full Ecto Repo backed by a database such as PostgreSQL.


Next, we have our shopping carts manager, which is the `CartsManagement.Manager` module
its role is to create, destroy and keep track of the shopping carts alive in the system
it identifies them by UUID.

The spawning of carts is done dynamically through a `DynamicSupervisor` that is a child of our `Manager` genserver, the mappings are stored in a Registry instance searchable by UUID

The purpose of this is system is to be able to provide our LiveView with the ability to create a cart on mount, this is not dissimilar to what a production system would be like in that once the user's session starts it has a cart assigned to him and can back any changes the user makes to their cart throughout our store.

In a real checkout process, the cart would be terminated once the user completes the purchase.

Following our `Manager` server, we have the actual carts themselves which are the `CartsManagement.Cart` module. This server holds the list of items the users have added to their cart through the `CartsManagement.Cart.Item` struct which keeps track of the product name, code, desired items and subtotal per item.

To add or remove products we do it through our `Cart` module, by passing the UUID associated with the cart and the product code.

Internally the client interface of the `Cart` module will lookup if there's a cart associated with that UUID, if the product exists and if there's any discount rules applicable to said product. 
The `%Product{}` and `%DiscountRule{}` structs are passed as arguments to the cart process instance through a `GenServer.call` which will add or remove  the `%Item{}` from its list of items and call the `Item` itself to recalculate the subtotal for the values of unit price and units and call the discount strategy module to evaluate the specific discount rule applicable to said `Item`.

Now, in a real system there's a lot of things that could happen, we could for example have semi-dynamic changes to the underlying unit price of an item which could happen throughout the lifetime of a Cart process or changes to our discount rules, these calls would need to be implemented in order to be able to handle these scenarios and were left out in order to simplify the complexity of the overall solution. 

Regarding the discount system itself, the approach implemented was to have a static (code) and a dynamic component to them.

The static component is a set of strategies which determine if said strategy is applicable to a given `%Item{}` through the evaluation of the product code and amount of desired units, but could be further expanded to add other criteria such as customer category, rule priority etc.

The dynamic component of the system is the discount rules, which specify the conditions for a specific strategy, i.e. the actual data where a strategy will need to be applied.

An example of this is the `XForThePriceOfY` strategy, this strategy has a `min_threshold` which is our `X` value and a `Y` value stored in the `%DiscountRule{}` as the `y_count`, this strategy will recalculate the item's desired units count by computing `X` mod `Y` + `X` rem `Y`.

Thus for one of our acceptance criteria our rule looks like:

```
%DiscountRule{
  product_code: "GR1",
  name: "Green Tea Discount",
  rule_strategy: "x_for_the_price_of_y",
  description: "2 for the price of 1",
  conditions: %{"min_threshold" => "2", "y_count" => "1"}
}
```

But we could easily add a new rule that applies a 3x1 rule on any product or a to a new product altogether.

In addition, the application also has a LiveView that can be used to manually explore the products list, adding items to a cart and visualizing the cart with its subtotal per item and its total 

Finally, in a real production system where we might have more than 1 node running our web interface for our customers, we want to extract the entire `CartsManagement` and `DiscountRules` system to a separate node and have the web nodes interact with it in order to avoid data fragmentation issues as web requests randomly land on the different web nodes 


For the acceptance scenario tests of our system, they can be found as part of the `CartsManagement.CartTest` module, in specific the `calculate_total/1` tests which implement
the different test scenarios and evaluate that the returned total for the cart is what is expected.


