defmodule SupermarketsChain.DataLoaderTest do
  use ExUnit.Case, async: true

  alias SuperMarketsChain.DataLoader

  @test_data [
    %{"code" => "GR1", "name" => "Green tea", "price" => "3.11"},
    %{"code" => "SR1", "name" => "Strawberries", "price" => "5.00"},
    %{"code" => "CF1", "name" => "Coffee", "price" => "11.23"}
  ]

  test "load_products/0 returns decoded JSON data" do
    assert DataLoader.load_products() == @test_data
  end
end
