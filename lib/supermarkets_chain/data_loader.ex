defmodule SuperMarketsChain.DataLoader do
  @moduledoc """
  Deals with loading a JSON from the project's priv dir
  """

  def load_products do
    load_file("products")
  rescue
    _ ->
      {:error, "error_loading_products"}
  end

  defp load_file(data_type) do
    "data/#{data_type}.json"
    |> priv_path()
    |> File.read!()
    |> Jason.decode!()
  end

  defp priv_path(relative_path) do
    Path.join(:code.priv_dir(:supermarkets_chain), relative_path)
  end
end
