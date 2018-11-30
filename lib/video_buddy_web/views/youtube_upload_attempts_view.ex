defmodule VideoBuddyWeb.YoutubeUploadAttemptsView do
  use VideoBuddyWeb, :view

  def show_upload_bar?(%VideoBuddy.Models.YoutubeUploadAttempt{
    upload_status: "upload_complete"
  }) do
    false
  end

  def show_upload_bar?(%VideoBuddy.Models.YoutubeUploadAttempt{
    upload_status: "unlocked"
  }) do
    false
  end

  def show_upload_bar?(%VideoBuddy.Models.YoutubeUploadAttempt{
    upload_status: "not_yet_attempted"
  }) do
    false
  end

  def show_upload_bar?(_yua) do
    true
  end

  def upload_status(%VideoBuddy.Models.YoutubeUploadAttempt{
      upload_status: "upload_complete"
    }) do
    "Completed"
  end

  def upload_status(%VideoBuddy.Models.YoutubeUploadAttempt{
    upload_status: "not_yet_attempted"
  }) do
    "Not Yet Attempted"
  end

  def upload_status(%VideoBuddy.Models.YoutubeUploadAttempt{
    upload_status: "unlocked"
  }) do
    "unlocked"
  end

  def upload_status(%VideoBuddy.Models.YoutubeUploadAttempt{
      upload_status: us
    }) do
    us
  end
end
