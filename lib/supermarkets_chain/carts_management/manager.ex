defmodule SupermarketsChain.CartsManagement.Manager do
  @moduledoc """
  Server that's dedicated to managing shopping carts

  It deals with spawning shopping carts and managing the mapping between UUIDs and the PID
  """

  use GenServer

  alias SupermarketsChain.CartsManagement.Cart

  defstruct supervisor_pid: nil, registry_pid: nil

  @registry_name SupermarketsChain.CartsManagement.Registry

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_cart do
    GenServer.call(__MODULE__, :create_cart)
  end

  def delete_cart(uuid) do
    case lookup_cart(uuid) do
      {:ok, pid} ->
        GenServer.call(__MODULE__, {:delete_cart, pid})

      {:error, "not_found"} ->
        :ok
    end
  end

  def lookup_cart(uuid) do
    case Registry.lookup(@registry_name, uuid) do
      [{pid, nil}] ->
        {:ok, pid}

      [] ->
        {:error, "not_found"}
    end
  end

  def registry_name do
    @registry_name
  end

  @impl true
  def init(_opts) do
    {:ok, supervisor_pid} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, registry_pid} =
      case Registry.start_link(keys: :unique, name: @registry_name) do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}
      end

    {:ok, %__MODULE__{supervisor_pid: supervisor_pid, registry_pid: registry_pid}}
  end

  @impl true
  def handle_call(:create_cart, _, state) do
    uuid = Ecto.UUID.generate()

    module_spec = {
      Cart,
      [uuid: uuid, registry: @registry_name]
    }

    {:ok, _} = DynamicSupervisor.start_child(state.supervisor_pid, module_spec)

    {:reply, {:ok, uuid}, state}
  rescue
    _err ->
      {:reply, {:error, "error_registering_cart"}, state}
  end

  @impl true
  def handle_call({:delete_cart, pid}, _, state) do
    DynamicSupervisor.terminate_child(state.supervisor_pid, pid)
    {:reply, :ok, state}
  end
end
