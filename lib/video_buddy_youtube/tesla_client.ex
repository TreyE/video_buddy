defmodule VideoBuddyYoutube.TeslaClient do
  use Tesla

  adapter :hackney

  plug Tesla.Middleware.BaseUrl, "https://www.googleapis.com"
  plug Tesla.Middleware.Headers, %{ 'user-agent': "Elixir" }
  plug Tesla.Middleware.DebugLogger

  @spec start_upload_request(VideoBuddyYoutube.UploadRequest.t()) ::
          {:error, Tesla.Env.t()} | {:ok, binary(), binary()}
  def start_upload_request(req) do
    t_request = VideoBuddyYoutube.UploadRequest.create_resumable_request(req)
    case exec_request(t_request) do
      %{status: 200} = good_resp -> {:ok, Map.fetch!(good_resp.headers, "location"), Map.fetch!(good_resp.headers, "x-goog-correlation-id")}
      bad_resp -> {:error, bad_resp}
    end
  end

  defp add_auth_information(req) do
    {:ok, token} = VideoBuddyYoutube.AuthTokenManager.get_auth_token()
    auth_header_val = "Bearer " <> token
    Keyword.update(req, :headers, %{authorization: auth_header_val},
      fn(headers) ->
        Map.put(headers, :authorization, auth_header_val)
      end
    )
  end

  defp exec_request(req) do
     headered_request = add_auth_information(req)
     request(headered_request)
  end
end
