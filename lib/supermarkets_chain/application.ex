defmodule SupermarketsChain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SupermarketsChain.DiscountRulesRepository
  alias SupermarketsChain.ProductsRepository
  alias SupermarketsChain.CartsManagement.Manager

  @impl true
  def start(_type, _args) do
    children = [
      SupermarketsChainWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:supermarkets_chain, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SupermarketsChain.PubSub},
      # Start a worker by calling: SupermarketsChain.Worker.start_link(arg)
      # {SupermarketsChain.Worker, arg},
      # Start to serve requests, typically the last entry
      SupermarketsChainWeb.Endpoint
    ]

    children =
      if Mix.env() != :test do
        children ++ [ProductsRepository, DiscountRulesRepository, Manager]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SupermarketsChain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SupermarketsChainWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
