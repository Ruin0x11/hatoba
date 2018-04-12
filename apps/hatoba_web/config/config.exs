# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :hatoba_web,
  namespace: HatobaWeb

# Configures the endpoint
config :hatoba_web, HatobaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zeW0AJDNNuRzsy4W5qw/z0vLQwzykNrrqq6wP9XaFWoefB2mSM+2P+yU7sSFUUYg",
  render_errors: [view: HatobaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: HatobaWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
