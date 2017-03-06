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

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    with %Plume{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input, plume),
         %Plume{ast: ast, tail: tail} <- astify(rest, plume) do
      attrs = case ast do
                ["", link] -> %{src: link, alt: first}
                [text, link] -> %{src: link, alt: first <> " " <> text}
                text when is_binary(text) -> %{src: first, alt: String.trim(text)}
              end
      Markright.Utils.continuation(:empty, %Plume{plume | tail: tail}, {:img, attrs})
    end
  end

  use Markright.Helpers.ImgLink

end
