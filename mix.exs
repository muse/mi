defmodule Mi.Mixfile do
  use Mix.Project

  def project do
    [app: :mi,
     version: "0.1.0",
     escript: [main_module: Mi],
     default_task: "escript.build",
     elixir: "~> 1.3"]
  end
end
