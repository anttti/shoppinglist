defmodule Shoppinglist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShoppinglistWeb.Telemetry,
      Shoppinglist.Repo,
      {DNSCluster, query: Application.get_env(:shoppinglist, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Shoppinglist.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Shoppinglist.Finch},
      # Start a worker by calling: Shoppinglist.Worker.start_link(arg)
      # {Shoppinglist.Worker, arg},
      # Start to serve requests, typically the last entry
      ShoppinglistWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shoppinglist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShoppinglistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
