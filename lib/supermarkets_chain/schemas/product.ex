defmodule SupermarketsChain.Schemas.Product do
  @moduledoc """
  Struct for holding our schema of a product
  """

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(code name price)a

  @primary_key false

  embedded_schema do
    field(:code, :string)
    field(:name, :string)
    field(:price, :decimal)
  end

  def changeset(%__MODULE__{} = product, attrs) do
    product
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def load(attrs) do
    ch = changeset(%__MODULE__{}, attrs)

    case ch.valid? do
      true ->
        {:ok, apply_changes(ch)}

      false ->
        {:error, "invalid_data"}
    end
  end
end
