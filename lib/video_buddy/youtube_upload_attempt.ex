defmodule VideoBuddy.YoutubeUploadAttempt do
  alias VideoBuddy.Repo
  import Ecto.Query

  def new(params \\ %{}) do
    changeset(%VideoBuddy.Models.YoutubeUploadAttempt{}, params)
  end

  def get(upload_id) do
    Repo.get(VideoBuddy.Models.YoutubeUploadAttempt, upload_id)
  end

  def inprogress_upload_ids() do
    (from yua in VideoBuddy.Models.YoutubeUploadAttempt,
      where: yua.upload_status in ["claimed_but_unstarted", "upload_uri_set", "uploading", "interrupted"],
      select: yua.id)
      |> Repo.all
  end

  def unstarted_upload_ids() do
    (from yua in VideoBuddy.Models.YoutubeUploadAttempt,
    where: yua.upload_status == "not_yet_attempted",
    select: yua.id)
    |> Repo.all
  end

  def complete_upload_and_set_youtube_id(upload_record, youtube_id) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: "upload_complete",
        upload_progress: upload_record.file_size,
        youtube_video_id: youtube_id
      }
    ) |> Repo.update!()
  end

  def set_upload_uri(upload_record, upload_uri) do
    changeset(
      upload_record,
      %{
        uploading_uri: upload_uri,
        upload_status: "upload_uri_set"
      }
    ) |> Repo.update!()
  end
  def claim_upload(upload_record) do
    changeset(
      upload_record,
      %{
        upload_status: "claimed_but_unstarted"
      }
    ) |> Repo.update!()
  end

  def mark_interrupted(upload_record, progress) do
    mark_state_progress(upload_record, "interrupted", progress)
  end

  def mark_complete(upload_record, progress) do
    mark_state_progress(upload_record, "upload_complete", progress)
  end

  def mark_uploading(upload_record, progress) do
    mark_state_progress(upload_record, "uploading", progress)
  end

  defp changeset(upload_record, params) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(upload_record, params)
  end

  defp mark_state_progress(upload_record, new_state, progress) do
    VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      upload_record,
      %{
        upload_status: new_state,
        upload_progress: progress
      }
    ) |> Repo.update!()
  end

end
