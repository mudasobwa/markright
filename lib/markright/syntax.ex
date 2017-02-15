defmodule Markright.Syntax do
  @moduledoc """
  The syntax definition/helpers.
  """

  @syntax [
    lookahead: 10,
    indent: 10,

    shield: ~w|/ \\|,
    block: [
      h: "#",
      pre: "```",
      blockquote: ">"
    ],
    flush: [
      hr: "\n---",
      br: "  \n",
      br: "  \n"
    ],
    lead: [
      ul: [li: "-"],
      dl: [dt: "▷"]
    ],
    magnet: [
      maillink: "mailto:",
      httplink: "http://",
      httpslink: "https://",
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

  def get(key) when is_atom(key), do: syntax()[key]
  def get(key, subkey) when is_atom(key) and is_atom(subkey),
    do: syntax()[key][subkey] || apply(Markright.Syntax, key, [])[subkey]

  Enum.each(~w|lookahead indent shield|a, fn e ->
    def unquote(e)(), do: syntax()[unquote(e)]
  end)

  Enum.each(~w|grip magnet flush|a, fn e ->
    def unquote(e)() do
      syntax()[unquote(e)]
      |> Enum.sort(fn {_, v1}, {_, v2} -> String.length(v1) > String.length(v2) end)
    end
  end)

  def block(opts \\ [regex: false]) do
    if opts[:regex] do
      syntax()[:block]
      |> Keyword.values
      |> Enum.map(&("\n[\s\t]*" <> &1))
      |> Enum.join("|")
    else
      syntax()[:block]
    end
  end

  def lead do
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
  end

end
