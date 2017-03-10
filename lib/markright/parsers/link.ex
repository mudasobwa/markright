defmodule Markright.Parsers.Link do
  @moduledoc ~S"""
  Parses the input for the link.

  ## Examples

      iex> "http://example.com Hello my] lovely world!" |> Markright.Parsers.Link.to_ast
      %Markright.Continuation{
        ast: {:a, %{href: "http://example.com"}, "Hello my"}, tail: " lovely world!"}
  """

  ##############################################################################

  @behaviour Markright.Parser

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    with %Plume{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input, plume),
         plume <- plume |> Plume.untail!,
         %Plume{ast: ast, tail: tail} <- astify(rest, plume) do
      {subinput, href} = case ast do
                           ["", link] -> {first, link}
                           [text, link] -> {first <> " " <> text, link}
                           text when is_binary(text) -> {String.trim(text), first}
                         end

      %Plume{ast: label, tail: ""} = Markright.Parsers.Generic.to_ast(subinput, plume)
      Plume.continue(%Plume{plume | ast: label, tail: tail}, {:a, %{href: href}})
    end
  end

  use Markright.Helpers.ImgLink

end
