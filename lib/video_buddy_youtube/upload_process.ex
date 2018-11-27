defmodule VideoBuddyYoutube.UploadProcess do
  alias VideoBuddy.Repo

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
    changeset = VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: "claimed_but_unstarted"
      }
    )
    updated_record = Repo.update!(changeset)
    upload_request = build_upload_request(updated_record)
    upload_uri = get_upload_uri(upload_request)
    record_with_upload_uri = set_upload_uri(updated_record, upload_uri)
    ul = spawn(fn -> start_upload_listener(record_with_upload_uri) end)
    VideoBuddyYoutube.TeslaUploader.start_async_video_upload(upload_request, upload_uri, ul)
  end

  defp resume_upload_process(_upload_record) do
    IO.puts("Don't handle resuming right now")
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

  def get_upload_uri(upload_request) do
    {:ok, upload_uri} = VideoBuddyYoutube.TeslaClient.start_upload_request(upload_request)
    upload_uri
  end

  def set_upload_uri(upload_record, upload_uri) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        uploading_uri: upload_uri,
        upload_status: "upload_uri_set"
      }
    ) |> Repo.update!()
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

  def mark_upload_started(upload_record, progress) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: "uploading",
        upload_progress: progress
      }
    ) |> Repo.update!()
  end

  defp start_upload_listener(upload_record) do
     receive do
        {:start, progress_so_far, total_size} ->
          updated_record = mark_upload_started(upload_record, progress_so_far)
          new_percent = (progress_so_far/total_size) * 100.0
          handle_upload_progress(updated_record, new_percent)
     after
        20000 -> :ok
     end
  end

  defp handle_upload_progress(upload_record, last_percent) do
    receive do
      {:data_read, _data_size, total_read, total_len} ->
        new_percent = (total_read / total_len) * 100.0
        case (new_percent - last_percent) > 1.0 do
          false -> handle_upload_progress(upload_record, last_percent)
          _ ->
            IO.puts("#{new_percent}")
            handle_upload_progress(upload_record, new_percent)
        end
      {:done, read_so_far, expected_len} ->
        handle_upload_stopped(upload_record, read_so_far, expected_len)
    after
      20000 -> :ok
    end
  end

  def handle_upload_stopped(upload_record, read_so_far, expected_len)  do
    case (read_so_far < expected_len) do
      false -> mark_upload_complete(upload_record, read_so_far)
      _ -> mark_upload_interrupted(upload_record, read_so_far)
    end
    IO.puts("Finished uploading a total of #{read_so_far} from #{expected_len}")
  end

  def mark_upload_complete(upload_record, progress) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: "upload_complete",
        upload_progress: progress
      }
    ) |> Repo.update!()
  end

  def mark_upload_interrupted(upload_record, progress) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: "interrupted",
        upload_progress: progress
      }
    ) |> Repo.update!()
  end
end
