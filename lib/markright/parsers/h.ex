defmodule Markright.Parsers.H do
  @moduledoc ~S"""
  Parses the headers.

  ## Examples

      iex> input = "## Hello _world_!\nOther text."
      iex> Markright.Parsers.H.to_ast(input)
      %Markright.Continuation{
        ast: {:h3, %{}, ["Hello ", {:em, %{}, "world"}, "!"]},
        tail: "Other text."}

      iex> input = "## Hello _world_!\nOther text."
      iex> Markright.to_ast(input)
      {:article, %{}, [
        {:h2, %{}, ["Hello ", {:em, %{}, "world"}, "!"]},
        {:p, %{}, "Other text."}]}
  """

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  require Logger

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    with %Plume{ast: first, tail: rest} <- Markright.Parsers.Word.to_ast(input, plume), # FIXME PUT TRIM PARAM
         %Plume{ast: ast, tail: tail} <- astify(rest, plume),
         %Plume{ast: block, tail: ""} <- apply(plume.bag[:parser], :to_ast, [ast, plume]) do

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

      Markright.Utils.continuation(%Plume{plume | ast: block, tail: tail}, {tag, %{}})
    end
  end

  ##############################################################################

  @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
  defp astify(part, plume)

  ##############################################################################

  defp astify(<<unquote(@splitter) :: binary, rest :: binary>>, %Plume{} = plume),
    do: Plume.astail!(plume, rest)

  defp astify(<<unquote(@unix_newline) :: binary, rest :: binary>>, %Plume{} = plume),
    do: Plume.astail!(plume, rest)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, %Plume{} = plume),
    do: astify(rest, Plume.tail!(plume, letter))

  defp astify("", %Plume{} = plume),
    do: Plume.astail!(plume, "")

  ##############################################################################
end
