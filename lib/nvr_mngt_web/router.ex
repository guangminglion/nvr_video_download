defmodule NvrMngtWeb.Router do
  use NvrMngtWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NvrMngtWeb do
    pipe_through :browser # Use the default browser stack
    post "/",NvrController, :download_videos

    get "/", NvrController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", NvrMngtWeb do
  #   pipe_through :api
  # end
end
