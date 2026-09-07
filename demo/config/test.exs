import Config

config :cerberus, Cerberus.Sandbox, header: "user-agent"

config :cerberus,
  ecto_repos: [Demo.Repo],
  playwright: [
    enabled: true,
    engine: :chromium,
    executable: Path.expand("../node_modules/playwright/cli.js", __DIR__),
    timeout: 15_000,
    launch_options: [headless: true],
    artifact_dir: System.get_env("CERBERUS_ARTIFACT_DIR")
  ]

config :demo, Demo.Repo, pool: Ecto.Adapters.SQL.Sandbox
config :demo, DemoWeb.Endpoint, server: true

config :phoenix, :plug_init_mode, :runtime

config :phoenix_test,
  endpoint: DemoWeb.Endpoint,
  otp_app: :demo
