defmodule Mi.Mixfile do
  use Mix.Project

  def project do
    [app: :mi,
     version: "0.1.0",
     elixir: "~> 1.3",
     escript: [main_module: Mi],
     default_task: "escript.build",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application
  # Type "mix help compile.app" for more information
  def application do
    [applications: []]
  end

  def aliases do
    ["eb": ["escript.build"],
     "ei": ["escript.install"],
     "eu": ["escript."]]
  end

  # Dependencies can be Hex packages:
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do [] end
end
