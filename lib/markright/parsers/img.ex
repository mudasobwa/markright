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

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %Markright.Continuation{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input),
         %Markright.Continuation{ast: ast, tail: tail} <- astify(rest, fun) do
      attrs = Map.merge(
        opts, case ast do
                [text, link] -> %{src: link, alt: first <> " " <> text}
                text when is_binary(text) -> %{src: first, alt: text}
              end)
      Markright.Utils.continuation(:empty, %Markright.Continuation{tail: tail}, {:img, attrs, fun})
    end
  end

  use Markright.Helpers.ImgLink

end
