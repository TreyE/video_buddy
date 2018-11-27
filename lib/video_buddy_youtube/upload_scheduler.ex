defmodule VideoBuddyYoutube.UploadScheduler do
  def schedule_youtube_uploads() do
    Enum.each(unstarted_uploads(), fn(upload_id) ->
      start_new_upload(upload_id)
    end)
    Enum.each(dead_uploads(), fn(upload_id) ->
      resume_upload(upload_id)
    end)
  end

  defp unstarted_uploads() do
    VideoBuddy.YoutubeUploadAttempt.unstarted_upload_ids()
      |> VideoBuddyYoutube.UploadWorkerManager.filter_assigned_uploads
  end

  defp dead_uploads() do
    VideoBuddy.YoutubeUploadAttempt.inprogress_upload_ids()
      |> VideoBuddyYoutube.UploadWorkerManager.filter_assigned_uploads
  end

  defp start_new_upload(upload_id) do
    upload_record = VideoBuddy.YoutubeUploadAttempt.get(upload_id)
    upload_pid = spawn(fn() -> VideoBuddyYoutube.UploadProcess.init_worker_from_beginning(upload_record) end)
    register_and_signal_worker(upload_id, upload_pid)
  end

  def resume_upload(upload_id) do
    upload_record = VideoBuddy.YoutubeUploadAttempt.get(upload_id)
    upload_pid = spawn(fn() -> VideoBuddyYoutube.UploadProcess.init_resuming_worker(upload_record) end)
    register_and_signal_worker(upload_id, upload_pid)
  end

  defp register_and_signal_worker(upload_id, upload_pid) do
    case VideoBuddyYoutube.UploadWorkerManager.register_upload_worker(upload_id, upload_pid) do
      :ok -> send(upload_pid, :start)
      _ -> send(upload_pid, :die)
    end
  end
end
