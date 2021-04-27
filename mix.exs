defmodule Markright.Mixfile do
  @moduledoc false
  use Mix.Project

  @app :markright

  def project do
    [
      app: @app,
      version: "0.7.3",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Markright, path: "bin/#{@app}"],
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger],
      extra_applications: [:crypto, :xml_builder]
    ]
  end

  defp deps do
    [
      {:xml_builder, "~> 2.0"},
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.22", only: :dev}
    ]
  end

  defp description do
    """
    **The extended, configurable markdown-like syntax parser, that produces an AST.**

    Supports the full set of `markdown`, plus extensions
    (custom markup with a bit of elixir code to handle parsing.)

    The AST produced is understandable by [`XmlBuilder`](https://github.com/joshnuss/xml_builder).
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|bin lib mix.exs README.md|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/mudasobwa/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end
end
