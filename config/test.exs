use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :data_quality, DataQualityWeb.Endpoint,
  http: [port: 4001],
  server: true

config :data_quality, hashing_module: DataQuality.DummyHashing

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :data_quality, DataQuality.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "data_quality_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
