defmodule EctoEnum.Mixfile do
  use Mix.Project

  @version "0.4.0"

  def project do
    [app: :ecto_enum,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     description: "Ecto extension to support enums in models",
     test_paths: test_paths(Mix.env),
     package: package,
     name: "EctoEnum",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/gjaldon/ecto_enum"]]
  end

  defp test_paths(:mysql), do: ["test/mysql"]
  defp test_paths(_), do: ["test/pg"]

  defp package do
    [contributors: ["Gabriel Jaldon"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/gjaldon/ecto_enum"},
     files: ~w(mix.exs README.md CHANGELOG.md lib)]
  end

  def application do
    [applications: [:logger, :ecto]]
  end

  defp deps do
    [{:ecto, ">= 0.13.1 and ~> 1.1.0 or ~> 2.0"},
     {:postgrex, ">= 0.12.0", optional: true},
     {:mariaex, ">= 0.7.8", optional: true},
     {:ex_doc, "~> 0.14.3", only: :docs},
     {:earmark, "~> 1.0", only: :docs},
     {:inch_ex, ">= 0.0.0", only: :docs}]
  end
end
