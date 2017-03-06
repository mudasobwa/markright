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

  @leadings %{"[" => :class, "(" => :id, "{" => :style}

  ##############################################################################

  @behaviour Markright.Parser

  ##############################################################################

  use Markright.Continuation

  ##############################################################################

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    case input do
      "" -> %Plume{plume | ast: {:nil, %{}, ""}} # FIXME
      <<leading :: binary-size(1), rest :: binary>> ->
        case @leadings[leading] do
          nil  -> %Plume{plume | ast: {:nil, %{}, input}}
          type -> astify(rest, Plume.bag!(plume, {:type, type}))
        end
    end
  end

  ##############################################################################

  @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
  defp astify(part, plume)

  ##############################################################################

  Enum.each(~w|] ) }|, fn delimiter ->
    defp astify(<<unquote(delimiter) :: binary, rest :: binary>>, %Plume{} = plume) do
      with {type, plume} <- Plume.debag!(plume, :type) do
        %Plume{plume | tail: "", ast: {:nil, %{type => plume.tail}, rest}} # FIXME REMOVE type
      end
    end
  end)

  defp astify(<<letter :: binary-size(1), rest :: binary>>, %Plume{} = plume),
    do: astify(rest, Plume.tail!(plume, letter))

  defp astify("", %Plume{} = plume), do: astify("]", plume)

  ##############################################################################
end
