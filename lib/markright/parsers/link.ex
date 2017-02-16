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

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %Markright.Continuation{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input),
         %Markright.Continuation{ast: ast, tail: tail} <- astify(rest, fun) do
      {subinput, href} = case ast do
                           ["", link] -> {first, link}
                           [text, link] -> {first <> " " <> text, link}
                           text when is_binary(text) -> {String.trim(text), first}
                         end

      %Markright.Continuation{ast: label, tail: ""} = Markright.Parsers.Generic.to_ast(subinput)
      Markright.Utils.continuation(
        %Markright.Continuation{ast: label, tail: tail}, {:a, Map.merge(opts, %{href: href}), fun})
    end
  end

  use Markright.Helpers.ImgLink

end
