defmodule Markright.Syntax do
  @moduledoc """
  The syntax definition/helpers.
  """

  @syntax [
    lookahead: 10,
    indent: 10,

    shield: ~w|/ \\|,
    block: [
      code: "```",
      blockquote: ">"
    ],
    flush: [
    ],
    lead: [
      ul: [li: "-"],
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
    |> Keyword.values
    |> Enum.reduce(& &1 ++ &2)
    |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
  end

  def surrounding(value) when is_binary(value) do
    syntax()[:lead]
    |> Enum.find_value(nil, fn {k, v} ->
      if v |> Keyword.values |> Enum.any?(& &1 == value), do: k
    end)
  end

  def surrounding(value) when is_atom(value) do
    syntax()[:lead]
    |> Enum.find_value(nil, fn {k, v} ->
      if v |> Keyword.keys |> Enum.any?(& &1 == value), do: k
    end)
  end

  def customs do
    syntax()[:custom]
#    |> Enum.map(fn {k, v} -> {to_module(k), v} end)
  end

end
