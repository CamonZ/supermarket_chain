defmodule SupermarketsChain.CartsManagement.ManagerTest do
  use ExUnit.Case

  alias SupermarketsChain.CartsManagement.Manager

  test "init/1 starts the dynamic supervisor and the carts registry" do
    assert {:ok, state} = Manager.init([])

    assert is_pid(state.supervisor_pid)
    assert is_pid(state.registry_pid)

    assert Process.alive?(state.supervisor_pid)
    assert Process.alive?(state.registry_pid)
  end

  test "create_cart spawns a new cart and returns an uuid" do
    Manager.start_link([])
    {:ok, uuid} = Manager.create_cart()

    assert {:ok, ^uuid} = Ecto.UUID.cast(uuid)
  end

  test "delete_cart deletes terminates the shopping cart" do
    Manager.start_link([])
    {:ok, uuid} = Manager.create_cart()
    {:ok, _} = Manager.lookup_cart(uuid)

    assert Manager.delete_cart(uuid) == :ok
    assert {:error, "not_found"} == Manager.lookup_cart(uuid)
  end

  test "lookup/1 returns the pid of a given registered shopping cart" do
    Manager.start_link([])
    {:ok, uuid} = Manager.create_cart()
    {:ok, pid} = Manager.lookup_cart(uuid)

    assert is_binary(uuid)
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "lookup returns error for non-existent uuid" do
    Manager.start_link([])

    assert {:error, "not_found"} = Manager.lookup_cart("non-existent-uuid")
  end
end
