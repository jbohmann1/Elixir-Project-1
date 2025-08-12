defmodule RtTaskBoardWebWeb.PageController do
  use RtTaskBoardWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
