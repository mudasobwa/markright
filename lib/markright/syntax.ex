defmodule Markright.Syntax do
  @moduledoc """
  The syntax definition/helpers.
  """
  @syntax [
    lookahead: 10,
    language_name_length: 20,

    shield: ~w|/ \\|,
    block: [
      blockquote: ">"
    ],
    flush: [

    ],
    grip: [
      span: "⇓",
      em: "_",
      strong: "*",
      b: "**",
      code: "`",
      strike: "~",
    ]
  ]

  def syntax do
    config = Application.get_env(:markright, :syntax) || []
    Keyword.merge(config, @syntax, fn _k, v1, v2 ->
      Keyword.merge(v1, v2)
    end)
  end

  def lookahead, do: syntax()[:lookahead]
  def language_name_length, do: syntax()[:language_name_length]

  def shields, do: syntax()[:shield]

  def blocks do
    syntax()[:block]
    |> Keyword.values
    |> Enum.map(& "\n[\s\t]*" <> &1)
#    |> Enum.map(& Regex.escape/1) # We DO NOT escape to allow regexps
    |> Enum.join("|")
  end

  def grips do
    syntax()[:grip]
    |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
  end
end
