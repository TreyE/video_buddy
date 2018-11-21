defmodule VideoBuddyYoutube.Models.YoutubeUploadAttemptTest do
  use ExUnit.Case, async: true

  test "is invalid with a visibility of scheduled and no published_at date" do
    changeset = VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      %VideoBuddy.Models.YoutubeUploadAttempt{},
      %{visibility: "scheduled"}
    )
    error_list = Ecto.Changeset.traverse_errors(changeset,
      fn({msg, _}) -> msg end
    )
    ["can't be blank"] = Map.fetch!(error_list, :published_at)
  end

  test "requires a title" do
    changeset = VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      %VideoBuddy.Models.YoutubeUploadAttempt{},
      %{}
    )
    error_list = Ecto.Changeset.traverse_errors(changeset,
      fn({msg, _}) -> msg end
    )
    ["can't be blank"] = Map.fetch!(error_list, :title)
  end

  test "has a default value of \"private\" for visibility" do
    changeset = VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      %VideoBuddy.Models.YoutubeUploadAttempt{},
      %{}
    )
    yua = Ecto.Changeset.apply_changes(changeset)
    "private" = yua.visibility
  end

  test "has a default value of \"not_yet_attempted\" for upload_status" do
    changeset = VideoBuddy.Models.YoutubeUploadAttempt.changeset(
      %VideoBuddy.Models.YoutubeUploadAttempt{},
      %{}
    )
    yua = Ecto.Changeset.apply_changes(changeset)
    "not_yet_attempted" = yua.upload_status
  end
end
