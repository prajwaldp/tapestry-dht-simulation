use Mix.Config

config :logger, level: :info

# Time delay after which a node sends the next request in ms
config :tapestry, :delay_between_reqs, 1000