defmodule VideoBuddyWeb.YoutubeUploadAttemptsController do
  use VideoBuddyWeb, :controller

  def index(conn, _params) do
    upload_attempts = VideoBuddy.Repo.all(VideoBuddy.Models.YoutubeUploadAttempt)
    render conn, "index.html", youtube_upload_attempts: upload_attempts
  end
end
