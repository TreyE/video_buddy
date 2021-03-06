defmodule VideoBuddyYoutube.UploadProcess do
  @db_record_update_interval_ms 2000

  def init_worker_from_beginning(upload_record) do
    receive do
      :start -> start_upload_process(upload_record)
      _ -> :ok
    end
  end

  def init_resuming_worker(upload_record) do
    receive do
      :start -> resume_upload_process(upload_record)
      _ -> :ok
    end
  end

  defp start_upload_process(upload_record) do
    updated_record = VideoBuddy.YoutubeUploadAttempt.claim_upload(upload_record)
    upload_request = build_upload_request(updated_record)
    {:ok, upload_uri, video_id} = VideoBuddyYoutube.TeslaClient.start_upload_request(upload_request)
    record_with_upload_uri = VideoBuddy.YoutubeUploadAttempt.set_upload_uri(updated_record, upload_uri, video_id)
    ul = spawn(fn -> start_upload_listener(record_with_upload_uri) end)
    handle_upload_request_end(
      VideoBuddyYoutube.TeslaUploader.start_async_video_upload(upload_request, upload_uri, ul),
      ul,
      record_with_upload_uri.id
    )
  end

  defp resume_upload_process(upload_record) do
    case upload_record.upload_status do
      "claimed_but_unstarted" -> start_upload_process(upload_record)
      _ ->
        VideoBuddy.YoutubeUploadAttempt.mark_interrupted(upload_record)
        resume_interrupted_process(upload_record)
    end
  end

  defp build_upload_request(upload_record) do
    VideoBuddyYoutube.UploadRequest.new(
      upload_record.title,
      upload_record.description,
      upload_record.recording_date,
      convert_schedule(upload_record),
      convert_tags(upload_record.tags),
      upload_record.source_file_location
    )
  end

  defp resume_interrupted_process(upload_record) do
    upload_request = build_upload_request(upload_record)
    upload_status_response = VideoBuddyYoutube.TeslaUploader.check_upload_progress(upload_request, upload_record.uploading_uri)
    IO.inspect(upload_status_response)
    case upload_status_response do
      %{status: 308} = resp -> get_range_and_resume(upload_record, upload_request, resp)
      _ ->
        IO.puts("UPLOAD FAILED")
    end
  end

  defp get_range_and_resume(upload_record, upload_request, progress_response) do
    case Map.has_key?(progress_response.headers, "range") do
      false ->
        updated_record = VideoBuddy.YoutubeUploadAttempt.mark_uploading(upload_record, 0)
        ul = spawn(fn -> start_upload_listener(updated_record) end)
        handle_upload_request_end(
          VideoBuddyYoutube.TeslaUploader.start_async_video_upload(upload_request, updated_record.uploading_uri, ul),
          ul,
          updated_record.id
        )
      _ -> get_range_values_and_resume(upload_record, upload_request, Map.fetch!(progress_response.headers, "range"))
    end
  end

  defp get_range_values_and_resume(upload_record, upload_request, range_header_value) do
     {last_sent, _rest} = (String.trim(range_header_value)
                   |> String.split("-")
                   |> List.last()
                   |> Integer.parse())
      ul = spawn(fn -> start_upload_listener(upload_record) end)
      handle_upload_request_end(
        VideoBuddyYoutube.TeslaUploader.resume_async_video_upload(upload_request, upload_record.uploading_uri, ul, last_sent),
        ul,
        upload_record.id
      )
  end

  defp convert_tags(nil) do
    []
  end

  defp convert_tags("") do
    []
  end

  defp convert_tags(tags_string) do
     case String.trim(tags_string) do
        "" -> []
        clean_tags -> split_tags(clean_tags)
     end
  end

  defp split_tags(clean_tags) do
    String.split(clean_tags, ",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(fn(val) -> !(val == "") end)
  end

  defp convert_schedule(upload_record) do
    case upload_record.visibility do
      "public" -> :public
      "scheduled" -> {:scheduled, upload_record.publish_at}
      _ -> :private
    end
  end

  defp start_upload_listener(upload_record) do
     receive do
        {:start, progress_so_far, _total_size} ->
          updated_record = VideoBuddy.YoutubeUploadAttempt.mark_uploading(upload_record, progress_so_far)
          handle_upload_progress(updated_record, Time.utc_now)
     after
        20000 -> :ok
     end
  end

  defp handle_upload_progress(upload_record, last_update_time) do
    receive do
      {:data_read, _data_size, total_read, _total_len} ->
        new_time = Time.utc_now()
        time_difference = Time.diff(new_time, last_update_time, :millisecond)
        case (time_difference >= @db_record_update_interval_ms) do
          false -> handle_upload_progress(upload_record, last_update_time)
          _ ->
            updated_record = VideoBuddy.YoutubeUploadAttempt.mark_uploading(upload_record, total_read)
            VideoBuddyWeb.YoutubeUploadAttemptChannel.broadcast_upload_update(updated_record.id, "uploading", total_read, updated_record.file_size)
            handle_upload_progress(updated_record, new_time)
        end
      {:done, read_so_far, expected_len} ->
        handle_upload_stopped(upload_record, read_so_far, expected_len)
    after
      20000 -> :ok
    end
  end

  def handle_upload_stopped(upload_record, read_so_far, expected_len)  do
    case (read_so_far < expected_len) do
      false ->
        VideoBuddyWeb.YoutubeUploadAttemptChannel.broadcast_upload_update(upload_record.id, "upload_complete", read_so_far, upload_record.file_size)
        VideoBuddy.YoutubeUploadAttempt.mark_complete(upload_record, read_so_far)
      _ -> VideoBuddy.YoutubeUploadAttempt.mark_interrupted(upload_record, read_so_far)
    end
  end

  defp handle_upload_request_end(response, listener_pid, upload_record_id) do
     case Process.alive?(listener_pid) do
        false -> process_upload_end_with_response(response, upload_record_id)
        _ ->
          :timer.sleep(2000)
          handle_upload_request_end(response, listener_pid, upload_record_id)
     end
  end

  @spec process_upload_end_with_response(Tesla.Env.t(), integer()) :: any()
  defp process_upload_end_with_response(%{status: 200} = response, upload_record_id) do
     upload_record = VideoBuddy.YoutubeUploadAttempt.get(upload_record_id)
     video = Poison.decode!(Map.fetch!(response, :body), as: %GoogleApi.YouTube.V3.Model.Video{})
     VideoBuddy.YoutubeUploadAttempt.complete_upload_and_set_youtube_id(upload_record, video.id)
  end

  defp process_upload_end_with_response(response, upload_record_id) do
    upload_record = VideoBuddy.YoutubeUploadAttempt.get(upload_record_id)
    IO.inspect(response)
 end
end
