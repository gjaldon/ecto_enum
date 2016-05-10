defmodule EctoEnum.Mixfile do
  use Mix.Project

  @version "0.3.1"

  def project do
    [app: :ecto_enum,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     description: "Ecto extension to support enums in models",
     package: package,
     name: "EctoEnum",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/gjaldon/ecto_enum"]]
  end

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
    [{:ecto, ">= 0.13.1"},
     {:postgrex, ">= 0.8.3", optional: true},
     {:mariaex, ">= 0.3.0", optional: true},
     {:ex_doc, "~> 0.7", only: :docs},
     {:earmark, "~> 0.1", only: :docs},
     {:inch_ex, ">= 0.0.0", only: :docs}]
  end
end
