defmodule RtTaskBoardWebWeb.Router do
  use RtTaskBoardWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RtTaskBoardWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RtTaskBoardWebWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/board", DashboardLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", RtTaskBoardWebWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rt_task_board_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RtTaskBoardWebWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/", RtTaskBoardWebWeb do
      pipe_through :browser

      live "/", DashboardLive, :index
    end
  end
end
