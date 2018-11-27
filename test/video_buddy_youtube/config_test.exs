defmodule VideoBuddyYoutube.ConfigTest do
  use ExUnit.Case, async: true

  test "reads YouTube clientId" do
    "test_client_id" = VideoBuddyYoutube.Config.client_id
  end

  test "reads YouTube clientSecret" do
    "test_client_secret" = VideoBuddyYoutube.Config.client_secret
  end

  test "reads YouTube channelId" do
    "test_channel_id" = VideoBuddyYoutube.Config.channel_id
  end

  test "reads YouTube refreshToken" do
    "test_refresh_token" = VideoBuddyYoutube.Config.refresh_token
  end
end
