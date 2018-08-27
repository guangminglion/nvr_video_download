# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :nvr_mngt,
  ecto_repos: [NvrMngt.Repo]

# Configures the endpoint
config :nvr_mngt, NvrMngtWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JW/l4c817WtJ7LDK6VsfFEmI6vLHuWd2Rsqk8qGYC+cbsTAw8m/7LMz7acUjBd2s",
  render_errors: [view: NvrMngtWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NvrMngt.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
