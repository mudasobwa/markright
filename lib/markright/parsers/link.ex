defmodule Markright.Parsers.Link do
  @moduledoc ~S"""
  Parses the input for the link.

  ## Examples

      iex> "http://example.com Hello my] lovely world!" |> Markright.Parsers.Link.to_ast
      {{:a, %{href: "http://example.com"}, "Hello my"}, " lovely world!"}
  """

  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty()) when is_binary(input) and
                                                              (is_nil(fun) or is_function(fun)) and
                                                               is_map(opts) do

    {first, rest} = Markright.Parsers.Word.to_ast(input)

    case astify(rest, fun, opts, acc) do
      {{text, link}, rest} ->
        label = Markright.Parsers.Generic.to_ast(first <> " " <> text, nil, %{only: :ast}, %Buf{tags: [:span]})
        {{:a, %{href: link}, label}, rest}
      {text, rest} ->
        label = Markright.Parsers.Generic.to_ast(text, nil, %{only: :ast}, %Buf{tags: [:span]})
        {{:a, %{href: first}, label}, rest}
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc)

  ##############################################################################

  Enum.each(~w/]( |/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, fun, opts, acc) do
      with {link, tail} <- astify(rest, fun, opts, Buf.empty()), do: {{acc.buffer, link}, tail}
    end
  end)

  Enum.each(~w/] )/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, _fun, _opts, acc),
      do: {acc.buffer, rest}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  ##############################################################################
end
