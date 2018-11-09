defmodule VideoBuddyWeb.PageController do
  use VideoBuddyWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
