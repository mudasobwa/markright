defmodule Markright.Parsers.ClassOrId do
  @moduledoc ~S"""
  Parses the input for the class and or id specified.

  ## Examples

      iex> "[class]world*!" |> Markright.Parsers.ClassOrId.to_ast
      %Markright.Continuation{ast: {nil, %{class: "class"}, "world*!"}, tail: ""}

      iex> "Hello *[class1]my* _{style1 style2}lovely_ world!" |> Markright.to_ast
      {:article, %{},
        [{:p, %{},
          ["Hello ", {:strong, %{class: "class1"}, "my"}, " ",
           {:em, %{style: "style1 style2"}, "lovely"}, " world!"]}]}
  """

  ##############################################################################

  @leadings %{"[" => :class, "(" => :id, "{" => :style }

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  use Markright.Buffer
  use Markright.Continuation

  ##############################################################################

  def to_ast(input, fun \\ nil, opts \\ %{}) \
    when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

    case input do
      "" -> %C{ast: {:nil, opts, ""}}
      <<leading :: binary-size(1), rest :: binary>> ->
        case @leadings[leading] do
          nil  -> %C{ast: {:nil, opts, input}}
          type -> astify(rest, opts, Buf.put(Buf.empty(), {:type, type}))
        end
    end
  end

  ##############################################################################

  @spec astify(String.t, Map.t, Buf.t) :: Markright.Continuation.t
  defp astify(part, opts, acc)

  ##############################################################################

  Enum.each(~w|] ) }|, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, opts, acc),
      do: %C{ast: {:nil, Map.put(opts, Buf.get(acc, :type), acc.buffer), rest}}
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, opts, acc),
    do: astify(rest, opts, Buf.append(acc, letter))

  defp astify("", opts, acc),
    do: astify("]", opts, acc)

  ##############################################################################
end
