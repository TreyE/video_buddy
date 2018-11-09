# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :video_buddy,
  ecto_repos: [VideoBuddy.Repo]

# Configures the endpoint
config :video_buddy, VideoBuddyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "sdm1qFNiYDGcmLZ+kJbF8/dSAiK7r8XAKjhGOY2VYnOZ9KVl5jb5AaMEscKgoGB0",
  render_errors: [view: VideoBuddyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: VideoBuddy.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
