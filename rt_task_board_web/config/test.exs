import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rt_task_board_web, RtTaskBoardWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "0nHo5/wy8oQCE+/OMM8Akvrrd11QQfU5KAXHt3buGfIuZmxATwy5YjvYXUD3B0gX",
  server: false

# In test we don't send emails
config :rt_task_board_web, RtTaskBoardWeb.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
