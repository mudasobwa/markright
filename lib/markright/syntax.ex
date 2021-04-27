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
      h: "§",
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
      tag: "#",
      youtube: "✇"
    ],
    grip: [
      span: "⇓",
      em: "_",
      strong: "*",
      b: "**",
      strike: "~"
    ],
    custom: [
      link: "[",
      img: "![",
      code: "`"
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

  defp value(key, syntax) when is_atom(key) do
    case syntax[key] do
      nil ->
        []

      list when is_list(list) ->
        Enum.map(list, fn {k, v} -> {k, value_with_opts(v)} end)

      other ->
        raise Markright.Errors.UnexpectedSyntax, value: other, expected: "nil or list"
    end
  end

  defp value(key, syntax) when is_binary(key),
    do: key |> String.to_atom() |> get(syntax)

  def get(key, subkey, syntax \\ syntax())
      when (is_atom(key) or is_binary(key)) and is_atom(subkey),
      do: value(key, syntax)[subkey]

  def take(key, subkey, syntax \\ syntax())
      when (is_atom(key) or is_binary(key)) and is_atom(subkey),
      do: key |> value(syntax) |> Keyword.get_values(subkey)

  # These parameters do not have respected handlers
  Enum.each(~w|lookahead indent shield|a, fn e ->
    def unquote(e)(syntax \\ syntax()),
      do: syntax[unquote(e)] || @syntax[unquote(e)]
  end)

  # Sorting by the length of the sample
  Enum.each(~w|grip magnet flush block lead custom|a, fn e ->
    def unquote(e)(syntax \\ syntax()) do
      unquote(e)
      |> value(syntax)
      |> sort_by_length
    end
  end)

  def surrounding(tag, syntax \\ syntax()) when is_atom(tag), do: syntax[:surrounding][tag]

  ##############################################################################

  defp sort_by_length(nil), do: []
  defp sort_by_length([]), do: []

  defp sort_by_length(values) do
    Enum.sort(values, fn {_, v1}, {_, v2} ->
      String.length(plain_value(v1)) > String.length(plain_value(v2))
    end)
  end

  defp value_with_opts({value, opts}) when is_binary(value) and is_list(opts), do: {value, opts}

  defp value_with_opts({value, opts}) when is_atom(value) and is_list(opts),
    do: {Atom.to_string(value), opts}

  defp value_with_opts(value), do: {value, []}

  defp plain_value(whatever), do: with({value, _} <- value_with_opts(whatever), do: value || "")
end
