defmodule EctoEnum.Mixfile do
  use Mix.Project

  @version "1.0.2"

  def project do
    [app: :ecto_enum,
     version: @version,
     elixir: "~> 1.2",
     deps: deps(),
     description: "Ecto extension to support enums in models",
     test_paths: test_paths(Mix.env),
     package: package(),
     name: "EctoEnum",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/gjaldon/ecto_enum"]]
  end

  defp test_paths(:mysql), do: ["test/mysql"]
  defp test_paths(_), do: ["test/pg"]

  defp package do
    [maintainers: ["Gabriel Jaldon"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/gjaldon/ecto_enum"},
     files: ~w(mix.exs README.md CHANGELOG.md lib)]
  end

  def application do
    [applications: [:logger, :ecto]]
  end

  defp deps do
    [{:ecto, "~> 2.0"},
     {:postgrex, "~> 0.13.0", optional: true},
     {:mariaex, "~> 0.8.0", optional: true},
     {:ex_doc, "~> 0.11", only: :dev},
     {:earmark, "~> 0.1", only: :dev},
     {:inch_ex, ">= 0.0.0", only: [:dev, :test]}]
  end
end
