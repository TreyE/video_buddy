defmodule VideoBuddyYoutube.TeslaUploader do
  use Tesla

  @upload_block_size 4096

  adapter :hackney

  plug Tesla.Middleware.Headers, %{ 'user-agent': "Elixir" }

  def check_upload_progress(upload_request, upload_uri) do
    %{size: c_len} = File.stat!(upload_request.source_uri)
    req = [
      method: :put,
      url: upload_uri,
      headers: %{
        "Content-Length": 0,
        "Content-Type": "bytes */#{c_len}"
      }
    ]
    exec_request(req)
  end

  def start_async_video_upload(upload_request, upload_uri, listener_pid) do
    %{size: c_len} = File.stat!(upload_request.source_uri)
    read_file_stream = Stream.resource(fn -> {File.open!(upload_request.source_uri, [:read, :binary]), 0} end,
                fn({file, read_so_far}) ->
                  case IO.binread(file, @upload_block_size) do
                    data when is_binary(data) ->
                      data_size = byte_size(data)
                      total_read = read_so_far + data_size
                      send(listener_pid, {:data_read, data_size, total_read, c_len})
                      {[data], {file, total_read}}
                    _ ->
                      send(listener_pid, {:done, read_so_far, c_len})
                      {:halt, {file, read_so_far}}
                  end
                end,
                fn({file, _}) -> File.close(file) end)
    req = [
      method: :put,
      url: upload_uri,
      headers: %{
        "Content-Length": c_len,
        "Content-Type": "video/*"
      },
      body: read_file_stream
    ]
    send(listener_pid, {:start, 0, c_len})
    exec_request(req)
  end

  @spec resume_async_video_upload(
          %VideoBuddyYoutube.UploadRequest{},
          String.t(),
          pid(),
          integer()
        ) :: Tesla.Env.t()
  def resume_async_video_upload(upload_request, upload_uri, listener_pid, last_byte_of_previous) do
    %{size: c_len} = File.stat!(upload_request.source_uri)
    last_byte_to_send = c_len - 1
    first_byte_to_send = last_byte_of_previous + 1
    read_previously = last_byte_of_previous + 1
    remaining_bytes = c_len - read_previously
    read_file_stream = Stream.resource(fn ->
                  f = File.open!(upload_request.source_uri, [:read, :binary])
                  {:ok, ^first_byte_to_send} = :file.position(f,{:bof, first_byte_to_send})
                  {f, read_previously}
                end,
                fn({file, read_so_far}) ->
                  case IO.binread(file, @upload_block_size) do
                    data when is_binary(data) ->
                      data_size = byte_size(data)
                      total_read = read_so_far + data_size
                      send(listener_pid, {:data_read, data_size, total_read, c_len})
                      {[data], {file, total_read}}
                    _ ->
                      send(listener_pid, {:done, read_so_far, c_len})
                      {:halt, {file, read_so_far}}
                  end
                end,
                fn({file, _}) -> File.close(file) end)
    req = [
      method: :put,
      url: upload_uri,
      headers: %{
        "Content-Length": remaining_bytes,
        "Content-Type": "video/*",
        "Content-Range": "#{first_byte_to_send}-#{last_byte_to_send}/#{c_len}"
      },
      body: read_file_stream
    ]
    send(listener_pid, {:start, read_previously, c_len})
    exec_request(req)
  end

  def simple_upload_listener(last_percent) do
    receive do
      {:data_read, _data_size, total_read, total_len} ->
        new_percent = (total_read / total_len) * 100.0
        case (new_percent - last_percent) > 1.0 do
          false -> simple_upload_listener(last_percent)
          _ ->
            IO.puts("#{new_percent}")
            simple_upload_listener(new_percent)
        end
      {:done, read_so_far, expected_len} -> IO.puts("Finished reading a total of #{read_so_far} from #{expected_len}")
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
