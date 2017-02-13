defmodule Markright.Parsers.Word do
  @moduledoc ~S"""
  Parses the input until the first occurence of a space.

  ## Examples

      iex> "Hello my lovely world!" |> Markright.Parsers.Word.to_ast
      %Markright.Continuation{ast: "Hello", tail: " my lovely world!"}
  """

  ##############################################################################

  use Markright.Helpers.Magnet

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{trim: true}) \
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do
      cont = astify(input)
      if Map.get(opts, :trim) do
        %Markright.Continuation{cont | tail: String.trim(cont.tail)}
      else
        cont
      end
  end

  ##############################################################################
end
