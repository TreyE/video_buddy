use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :video_buddy, VideoBuddyWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :video_buddy, VideoBuddy.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "video_buddy_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :video_buddy, VideoBuddyYoutube.Config,
  channelId: "test_channel_id",
  authToken: "test_auth_token",
  refreshToken: "test_refresh_token",
  clientId: "test_client_id",
  clientSecret: "test_client_secret"
