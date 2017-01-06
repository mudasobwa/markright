defmodule Markright.Parsers.Img do
  @moduledoc ~S"""
  Parses the input for the link.

  ## Examples

      iex> "http://example.com Hello my] lovely world!" |> Markright.Parsers.Img.to_ast
      {{:img, %{src: "http://example.com", alt: "Hello my"}, nil}, " lovely world!"}
  """

  @behaviour Markright.Parser

  use Markright.Buffer

  def to_ast(input, fun \\ nil, opts \\ %{}, acc \\ Buf.empty()) when is_binary(input) and
                                                              (is_nil(fun) or is_function(fun)) and
                                                               is_map(opts) do

    {first, rest} = Markright.Parsers.Word.to_ast(input)

    case astify(rest, fun, opts, acc) do
      {{text, link}, rest} -> {{:img, %{src: link, alt: first <> " " <> text}, nil}, rest}
      {text, rest} -> {{:img, %{src: first, alt: text}, nil}, rest}
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc \\ Buf.empty())

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
