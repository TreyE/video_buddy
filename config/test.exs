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
  channelId: "your_channel_id",
  authToken: "your_auth_token"
