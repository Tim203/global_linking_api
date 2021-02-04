defmodule GlobalLinkingWeb.LinkController do
  use GlobalLinkingWeb, :controller
  alias GlobalLinking.Repo
  alias GlobalLinking.UUID
  alias GlobalLinking.Utils

  def get_java_link(conn, %{"uuid" => uuid}) do
    case UUID.cast(uuid) do
      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, message: "uuid has to be a valid uuid (36 chars long)"})

      _ ->
        {_, result} = Cachex.fetch(:java_link, uuid, fn _ ->
          link = Repo.get_java_link(uuid)
          |> Utils.update_username_if_needed_array
          {:commit, link}
        end)

        json(conn, %{success: true, data: result})
    end
  end

  def get_java_link(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, message: "Please provide an uuid to lookup"})
  end

  def get_bedrock_link(conn, %{"xuid" => xuid}) do
    case Utils.is_int_and_rounded(xuid) do
      false ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, message: "xuid should be an int"})

      true ->
        {_, result} = Cachex.fetch(:bedrock_link, xuid, fn _ ->
          link = Repo.get_bedrock_link(xuid)
          |> Utils.update_username_if_needed
          {:commit, link}
        end)

        json(conn, %{success: true, data: result})
    end
  end

  def get_bedrock_link(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{success: false, message: "Please provide a xuid to lookup"})
  end
end