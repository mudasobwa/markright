defmodule Markright.Mixfile do
  use Mix.Project

  def project do
    [app: :markright,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:xml_builder, "~> 0.0.9", only: ~w|dev test|a},
      {:credo, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp description do
    """
    **The extended, configurable markdown-like syntax parser, that produces an AST.**

    Out of the box is supports the full set of `markdown`, plus some extensions.
    The user of this library might easily extend the functionality with her own
    markup definition and a bit of elixir code to handle parsing.

    There is no one single call to `Regex` used. The whole parsing is done solely
    on pattern matching the input binary.

    The AST produced is understandable by [`XmlBuilder`](https://github.com/joshnuss/xml_builder).
    """
  end

  defp package do
    [
     name: :markright,
     files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mudasobwa/markright",
              "Docs" => "https://hexdocs.pm/markright"}]
  end
end
