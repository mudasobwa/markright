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

    with %C{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input),
         %C{ast: ast, tail: tail} <- astify(rest, fun) do
      attrs = Map.merge(
        opts, case ast do
                [text, link] -> %{src: link, alt: first <> " " <> text}
                text when is_binary(text) -> %{src: first, alt: text}
              end)
      Markright.Utils.continuation(:empty, %C{tail: tail}, {:img, attrs, fun})
    end
  end

  ##############################################################################

  @spec astify(String.t, Function.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, fun, acc \\ Buf.empty())

  ##############################################################################

  Enum.each(~w/]( |/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, fun, acc),
      do: with %C{ast: ast, tail: tail} <- astify(rest, fun),
            do: %C{ast: [acc.buffer, ast], tail: tail}
  end)

  Enum.each(~w/] )/, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, _fun, acc),
      do: %C{ast: acc.buffer, tail: rest}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
    do: astify(rest, fun, Buf.append(acc, letter))

  ##############################################################################
end
