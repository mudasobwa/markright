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
      li: {"-", [parser: Markright.Parsers.Li]},
      li: {"•", [parser: Markright.Parsers.Li]},
      dt: {"▷", [parser: Markright.Parsers.Dt]}
    ],
    magnet: [
      maillink: "mailto:",
      httplink: "http://",
      httpslink: "https://",
      lj: "✎",
      tag: "#"
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
    ],
    surrounding: [
      li: :ul,
      dt: :dl
    ]
  ]

  def syntax do
    config = Application.get_env(:markright, :syntax) || []
    Keyword.merge(@syntax, config, fn _k, v1, v2 ->
      Keyword.merge(v1, v2)
    end)
  end

  defp get(key) when is_atom(key), do: Enum.map(syntax()[key], fn {k, v} -> {k, value_with_opts(v)} end)
  defp get(key) when is_binary(key), do: key |> String.to_atom |> get

  def get(key, subkey) when (is_atom(key) or is_binary(key)) and is_atom(subkey), do: get(key)[subkey]

  # These parameters do not have respected handlers
  Enum.each(~w|lookahead indent shield|a, fn e ->
    def unquote(e)(), do: syntax()[unquote(e)]
  end)

  # Sorting by the length of the sample
  Enum.each(~w|grip magnet flush block lead custom|a, fn e ->
    def unquote(e)() do
      unquote(e)
      |> get
      |> sort_by_length
    end
  end)

  def surrounding(tag) when is_atom(tag), do: syntax()[:surrounding][tag]

  ##############################################################################

  defp sort_by_length(values) do
    Enum.sort(values, fn {_, v1}, {_, v2} ->
      String.length(value(v1)) > String.length(value(v2))
    end)
  end

  defp value_with_opts({value, opts}) when is_binary(value) and is_list(opts), do: {value, opts}
  defp value_with_opts({value, opts}) when is_atom(value) and is_list(opts), do: {Atom.to_string(value), opts}
  defp value_with_opts(value), do: {value, []}

  defp value(whatever), do: with {value, _} <- value_with_opts(whatever), do: value

end
