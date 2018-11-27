defmodule VideoBuddy.Models.YoutubeUploadAttempt do
  use Ecto.Schema
  import Ecto.Changeset

  @already_on_youtube_file_location "PREVIOUS_YOUTUBE_UPLOAD"

  schema "youtube_upload_attempts" do
    field :title, :string
    field :description, :string, default: ""
    field :source_file_location, :string
    field :recording_date, :utc_datetime
    field :upload_status, :string, default: "unlocked"
    field :upload_progress, :integer, default: 0
    field :file_size, :integer
    field :uploading_uri, :string
    field :youtube_video_id, :string
    field :publish_at, :utc_datetime
    field :tags, :string
    field :visibility, :string, default: "private"

    timestamps()
  end

  def new(params \\ %{}) do
    changeset(%__MODULE__{}, params)
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
           :youtube_video_id,
           :publish_at,
           :visibility,
           :file_size
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
          ["unlocked", "not_yet_attempted", "claimed_but_unstarted", "upload_uri_set", "uploading", "interrupted", "upload_complete"]
       )
      |> validate_publish_at_if_scheduled
      |> validate_file_location_and_set_size
  end

  defp validate_file_location_and_set_size(changeset) do
    case fetch_field(changeset, :source_file_location) do
      {_, nil} -> changeset # already done by required constraint
      {_, @already_on_youtube_file_location} -> changeset
      {_, loc_value} -> check_file_size(changeset, loc_value)
    end
  end

  defp check_file_size(changeset, file_location) do
    case File.stat(file_location) do
      {:ok, %{size: c_len}} -> change(changeset, file_size: c_len)
      _ -> add_error(changeset, :source_file_location, "is not a valid file location")
    end
  end

  defp validate_publish_at_if_scheduled(changeset) do
    case fetch_field(changeset, :visibility) do
      {:changes, "scheduled"} -> validate_publish_at(changeset)
      {:data, "scheduled"} -> validate_publish_at(changeset)
      _ -> changeset
    end
  end

  defp validate_publish_at(changeset) do
    case fetch_field(changeset, :publish_at) do
      {:changes, nil} -> add_error(changeset, :publish_at, "can't be blank")
      {:data, nil} -> add_error(changeset, :publish_at, "can't be blank")
      {:changes, _} -> changeset
      {:data, _} -> changeset
      _ -> add_error(changeset, :publish_at, "can't be blank")
    end
  end

  def already_on_youtube_location() do
    @already_on_youtube_file_location
  end
end
