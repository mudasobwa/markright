defmodule Markright.Parsers.Img do
  @moduledoc ~S"""
  Parses the input for the link.

  ## Examples

      iex> "http://example.com] lovely world!" |> Markright.Parsers.Img.to_ast
      %Markright.Continuation{ast: {:img,
             %{alt: "http://example.com", src: "http://example.com"}, nil},
            bag: [tags: [], parser: Markright.Parsers.Generic], fun: nil, tail: " lovely world!"}

      iex> "http://example.com Hello my] lovely world!" |> Markright.Parsers.Img.to_ast
      %Markright.Continuation{ast: {:figure, %{},
            [{:img, %{alt: "Hello my", src: "http://example.com"}, nil},
             {:figcaption, %{}, "Hello my"}]},
            bag: [tags: [], parser: Markright.Parsers.Generic], fun: nil, tail: " lovely world!"}
  """

  ##############################################################################

  @behaviour Markright.Parser

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    with %Plume{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input, plume),
         %Plume{ast: ast, tail: tail} = cont <- astify(rest, plume) do
      attrs = case ast do
                ["", link] -> %{src: link, alt: first}
                [text, link] -> %{src: link, alt: first <> " " <> text}
                text when is_binary(text) -> %{src: first, alt: String.trim(text)}
              end

      case attrs do
        %{src: src, alt: ""} ->
          Markright.Utils.continuation(:empty, %Plume{plume | tail: tail}, {:img, %{attrs | alt: src}})
        %{src: src, alt: alt} ->
          cont = %Plume{cont | ast: [{:img, %{src: src, alt: alt}, nil},
                                     {:figcaption, %{}, alt}]}
          Markright.Utils.continuation(:continuation, cont, {:figure, %{}})
      end
    end
  end

  use Markright.Helpers.ImgLink

end
