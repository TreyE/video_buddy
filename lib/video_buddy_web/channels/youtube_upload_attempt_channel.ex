defmodule VideoBuddyWeb.YoutubeUploadAttemptChannel do
  use Phoenix.Channel

  def join("youtube_upload_attempt:" <> _attempt_id, _params, socket) do
    {:ok, socket}
  end

  def broadcast_upload_update(upload_attempt_id, status, uploaded, total) do
    VideoBuddyWeb.Endpoint.broadcast(
      "youtube_upload_attempt:" <> Integer.to_string(upload_attempt_id),
      "upload_progress_update",
      %{status: status, uploaded: uploaded, total: total}
    )
  end
end
