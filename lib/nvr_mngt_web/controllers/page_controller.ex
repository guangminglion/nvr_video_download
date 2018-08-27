defmodule NvrMngtWeb.PageController do
  use NvrMngtWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
