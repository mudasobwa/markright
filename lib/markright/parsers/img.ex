defmodule Markright.Parsers.Img do
  @moduledoc ~S"""
  Parses the input for the link.

  ## Examples

      iex> "http://example.com Hello my] lovely world!" |> Markright.Parsers.Img.to_ast
      %Markright.Continuation{ast: {:img,
             %{alt: "Hello my", src: "http://example.com"}, nil},
            tail: " lovely world!"}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    %C{ast: first, tail: rest} = Markright.Parsers.Word.to_ast(input)

    with %C{ast: ast, tail: tail} <- astify(rest, fun, opts) do
      case ast do
        [text, link] -> %C{ast: {:img, %{src: link, alt: first <> " " <> text}, nil}, tail: tail}
        text when is_binary(text) -> %C{ast: {:img, %{src: first, alt: text}, nil}, tail: tail}
      end
    end
    |> C.callback(fun)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, opts, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(~w/]( |/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, fun, opts, acc),
      do: with %C{ast: ast, tail: tail} <- astify(rest, fun, opts),
            do: %C{ast: [acc.buffer, ast], tail: tail}
  end)

  Enum.each(~w/] )/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, _fun, _opts, acc),
      do: %C{ast: acc.buffer, tail: rest}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, opts, acc),
    do: astify(rest, fun, opts, Buf.append(acc, letter))

  ##############################################################################
end
