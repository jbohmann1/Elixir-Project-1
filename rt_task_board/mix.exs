defmodule RtTaskBoard.MixProject do
  use Mix.Project

  def project do
    [
      app: :rt_task_board,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: RTTaskBoard.CLI]   # <— makes `mix escript.build` produce a runnable binary
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RTTaskBoard.Application, []} # <- start our supervision tree
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "~> 1.4"},  # JSON encoder/decoder
      {:phoenix_pubsub, "~> 2.1", optional: true}
    ]
  end
end
