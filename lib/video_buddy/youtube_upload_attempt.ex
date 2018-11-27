defmodule VideoBuddy.YoutubeUploadAttempt do
  alias VideoBuddy.Repo
  import Ecto.Query

  def get(upload_id) do
    Repo.get(VideoBuddy.Models.YoutubeUploadAttempt, upload_id)
  end

  def inprogress_upload_ids() do
    (from yua in VideoBuddy.Models.YoutubeUploadAttempt,
      where: yua.status in ["claimed_but_unstarted", "upload_uri_set", "uploading", "interrupted"],
      select: yua.id)
      |> Repo.all
  end

  def unstarted_upload_ids() do
    (from yua in VideoBuddy.Models.YoutubeUploadAttempt,
    where: yua.status == "claimed_but_unstarted",
    select: yua.id)
    |> Repo.all
  end
end
