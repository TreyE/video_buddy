defmodule VideoBuddy.Repo.Migrations.CreateYoutubeUploadAttempts do
  use Ecto.Migration

  def change do
    create table("youtube_upload_attempts") do
      add :title, :string, size: 256, null: false
      add :description, :text, default: ""
      add :source_file_location, :string, size: 512, null: false
      add :recording_date, :utc_datetime, null: false
      add :upload_status, :string, default: "unlocked", size: 80, null: false
      add :upload_progress, :integer, default: 0, null: false
      add :file_size, :integer
      add :uploading_uri, :string, size: 1024
      add :youtube_video_id, :string, size: 256
      add :publish_at, :utc_datetime
      add :tags, :string, size: 512
      add :visibility, :string, default: "private", size: 25, null: false
      timestamps()
    end

    create constraint("youtube_upload_attempts", "allowed_visibility_values", check: "visibility in ('public','private','scheduled')")
  end
end
