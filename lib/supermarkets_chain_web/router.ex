defmodule SupermarketsChainWeb.Router do
  use SupermarketsChainWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SupermarketsChainWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SupermarketsChainWeb do
    pipe_through :browser

    live_session :default do
      live "/", ProductsLive.Index
    end
  end
end
