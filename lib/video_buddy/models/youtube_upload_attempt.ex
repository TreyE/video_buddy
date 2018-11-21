defmodule VideoBuddy.Models.YoutubeUploadAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "youtube_upload_attempts" do
    field :title, :string
    field :description, :string, default: ""
    field :source_file_location, :string
    field :recording_date, :utc_datetime
    field :upload_status, :string, default: "not_yet_attempted"
    field :upload_progress, :integer, default: 0
    field :uploading_uri, :string
    field :publish_at, :utc_datetime
    field :tags, :string
    field :visibility, :string, default: "private"
  end

  def changeset(yua, params \\ %{}) do
    yua
      |> cast(params, [
           :title,
           :description,
           :source_file_location,
           :recording_date,
           :upload_status,
           :tags,
           :uploading_uri,
           :upload_progress,
           :publish_at,
           :visibility
        ])
      |> validate_required([
           :title,
           :source_file_location
         ])
      |> validate_inclusion(
            :visibility,
            ["public", "private", "scheduled"]
         )
      |> validate_inclusion(
          :upload_status,
          ["not_yet_attempted", "upload_uri_set", "uploading", "upload_complete"]
       )
      |> validate_publish_at_if_scheduled
  end

  def validate_publish_at_if_scheduled(changeset) do
    case fetch_field(changeset, :visibility) do
      {:changes, "scheduled"} -> validate_published_at(changeset)
      {:data, "scheduled"} -> validate_published_at(changeset)
      _ -> changeset
    end
  end

  def validate_published_at(changeset) do
    case fetch_field(changeset, :published_at) do
      {:changes, nil} -> add_error(changeset, :published_at, "can't be blank")
      {:data, nil} -> add_error(changeset, :published_at, "can't be blank")
      {:changes, _} -> changeset
      {:data, _} -> changeset
      _ -> add_error(changeset, :published_at, "can't be blank")
    end
  end
end
