defmodule VideoBuddyWeb.Router do
  use VideoBuddyWeb, :router

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

  scope "/", VideoBuddyWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/youtube_upload_attempts", YoutubeUploadAttemptsController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", VideoBuddyWeb do
  #   pipe_through :api
  # end
end
