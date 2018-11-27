defmodule VideoBuddyYoutube.Config do
  def client_id do
    Application.get_env(:video_buddy, VideoBuddyYoutube.Config, %{})
      |> Keyword.fetch!(:clientId)
  end

  def client_secret do
    Application.get_env(:video_buddy, VideoBuddyYoutube.Config, %{})
      |> Keyword.fetch!(:clientSecret)
  end

  def refresh_token do
    Application.get_env(:video_buddy, VideoBuddyYoutube.Config, %{})
      |> Keyword.fetch!(:refreshToken)
  end

  def channel_id do
    Application.get_env(:video_buddy, VideoBuddyYoutube.Config, %{})
      |> Keyword.fetch!(:channelId)
  end
end
