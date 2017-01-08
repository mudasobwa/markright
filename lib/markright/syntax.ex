defmodule Markright.Syntax do
  @moduledoc """
  The syntax definition/helpers.
  """

#  import Markright.Utils, only: [to_module: 1]

  @syntax [
    lookahead: 10,
    indent: 10,

    shield: ~w|/ \\|,
    block: [
      blockquote: ">",
      code: "```",
      p: "\n\n"
    ],
    flush: [
    ],
    lead: [
      li: "-",
    ],
    grip: [
      span: "⇓",
      em: "_",
      strong: "*",
      b: "**",
      code: "`",
      strike: "~",
    ],
    custom: [
      link: "[",
      img: "![",
    ]
  ]

  def syntax do
    config = Application.get_env(:markright, :syntax) || []
    Keyword.merge(config, @syntax, fn _k, v1, v2 ->
      Keyword.merge(v1, v2)
    end)
  end

  def lookahead, do: syntax()[:lookahead]
  def indent, do: syntax()[:indent]

  def shields, do: syntax()[:shield]

  def blocks(opts \\ [regex: false]) do
    if opts[:regex] do
      syntax()[:block]
      |> Keyword.values
      |> Enum.map(&("\n[\s\t]*" <> &1))
      |> Enum.join("|")
    else
      syntax()[:block]
    end
  end

  def grips do
    syntax()[:grip]
    |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
  end

  def leads do
    syntax()[:lead]
    |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
  end

  def customs do
    syntax()[:custom]
#    |> Enum.map(fn {k, v} -> {to_module(k), v} end)
  end

end
