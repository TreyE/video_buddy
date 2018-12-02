defmodule VideoBuddyYoutube.UploadRequest do
  defstruct [
    source_uri: nil,
    title: nil,
    description: nil,
    recording_date: nil,
    visibility: :private,
    tags: []
  ]

  @type t() :: %__MODULE__{
    title: String.t(),
    description: String.t(),
    recording_date: DateTime.t(),
    visibility: :public | :private | {:scheduled, DateTime.t()},
    tags: [String.t()],
    source_uri: String.t()
  }

  @gaming_category_id 20

  @upload_path "/resumable/upload/youtube/v3/videos"

  @spec new(String.t(), String.t(), DateTime.t(), :public | :private | {:scheduled, DateTime.t()}, [String.t()], String.t()) ::
    __MODULE__.t()
  def new(title, description, recording_date, visibility, tags, source_uri) do
    %__MODULE__{
      title: title,
      description: description,
      recording_date: recording_date,
      visibility: visibility,
      tags: tags,
      source_uri: source_uri
    }
  end

  def create_resumable_request(%__MODULE__{} = req) do
    resource = convert_to_video_resource(req)
    %{size: c_len} = File.stat!(req.source_uri)
    [
      url: @upload_path,
      method: :post,
      query: [
        uploadType: "resumable",
        part: "snippet,status,recordingDetails"
      ],
      headers: %{
        "Content-Type": "application/json; charset=utf-8",
        "x-upload-content-length": c_len,
        "X-Upload-Content-Type": "application/octet-stream"
      },
      body: Poison.encode!(resource)
    ]
  end

  defp convert_to_video_resource(%__MODULE__{} = req) do
    %GoogleApi.YouTube.V3.Model.Video{
      snippet: %GoogleApi.YouTube.V3.Model.VideoSnippet{
        title: req.title,
        description: req.description,
        tags: req.tags,
        categoryId: @gaming_category_id,
        channelId: VideoBuddyYoutube.Config.channel_id
      },
      status: set_privacy_settings(
        %GoogleApi.YouTube.V3.Model.VideoStatus{},
        req.visibility
      ),
      recordingDetails: %GoogleApi.YouTube.V3.Model.VideoRecordingDetails{
        recordingDate: req.recording_date
      }
    }
  end

  defp set_privacy_settings(%GoogleApi.YouTube.V3.Model.VideoStatus{} = vs, :public) do
    %GoogleApi.YouTube.V3.Model.VideoStatus{vs |
      privacyStatus: "public"
    }
  end

  defp set_privacy_settings(%GoogleApi.YouTube.V3.Model.VideoStatus{} = vs, :private) do
    %GoogleApi.YouTube.V3.Model.VideoStatus{vs |
      privacyStatus: "private"
    }
  end

  defp set_privacy_settings(%GoogleApi.YouTube.V3.Model.VideoStatus{} = vs, {:scheduled, on_date}) do
    %GoogleApi.YouTube.V3.Model.VideoStatus{vs |
      privacyStatus: "private",
      publishAt: on_date
    }
  end
end
