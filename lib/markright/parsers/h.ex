defmodule Markright.Parsers.H do
  @moduledoc ~S"""
  Parses the headers.

  ## Examples

      iex> input = "## Hello _world_!
      ...> Other text.
      ...> "
      iex> Markright.Parsers.H.to_ast(input)
      %Markright.Continuation{
        ast: {:h3, %{}, ["Hello ", {:em, %{}, "world"}, "!"]},
        tail: " Other text.\n "}

      iex> input = "## Hello _world_!
      ...> Other text.
      ...> "
      iex> Markright.to_ast(input)
      {:article, %{}, [
        {:h2, %{}, ["Hello ", {:em, %{}, "world"}, "!"]},
        {:p, %{}, " Other text.\n "}]}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{})
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    with %C{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input),
         %C{ast: ast, tail: tail} <- astify(rest),
         %C{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast) do

      tag = case first do
              ""  -> :h1
              "1" -> :h1
              "2" -> :h2
              "3" -> :h3
              "4" -> :h4
              "5" -> :h5
              "6" -> :h6
              _   -> String.to_atom("h#{String.length(first) + 1}")
            end

      Markright.Utils.continuation(%C{ast: block, tail: tail}, {tag, opts, fun})
    end
  end

  ##############################################################################

  @spec astify(String.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, acc \\ Buf.empty())

  ##############################################################################

  defp astify(<<unquote(@unix_newline) :: binary, rest :: binary>>, acc),
    do: %C{ast: acc.buffer, tail: rest}

  defp astify(<<letter :: binary-size(1), rest :: binary>>, acc),
    do: astify(rest, Buf.append(acc, letter))

  defp astify("", acc),
    do: %C{ast: acc.buffer, tail: ""}

  ##############################################################################
end
