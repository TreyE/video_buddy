defmodule VideoBuddyYoutube.ConfigTest do
  use ExUnit.Case, async: true

  test "reads YouTube authToken" do
    "test_auth_token" = VideoBuddyYoutube.Config.auth_token
  end

  test "reads YouTube channelId" do
    "test_channel_id" = VideoBuddyYoutube.Config.channel_id
  end
end
