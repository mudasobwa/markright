defmodule Markright.Top do
  @moduledoc ~S"""
  The module to `use` in presets to produce a top-level tag and parse the content.
  """

  defmacro __using__(opts) do
    quote do
      @behaviour Markright.Parser
      @behaviour Markright.Preset

      @tag unquote(opts)[:tag] || Markright.Utils.atomic_module_name(__MODULE__)

      use Markright.Continuation
      alias Markright.Continuation, as: Plume

      def to_ast(input, %Plume{} = plume \\ %Plume{}, opts \\ [])
          when is_binary(input) and is_list(opts) do
        {syntax, params} = {opts[:syntax], opts[:params] || %{}}
        Markright.Utils.continuation(astify(input, plume, syntax), {@tag, params})
      end

      def syntax, do: []
      defoverridable syntax: 0

      ##############################################################################

      defp astify(input, %Plume{} = plume, syntax) do
        parser_module = parser(syntax) || plume.bag[:parser]
        plume = %Plume{plume | bag: [parser: parser_module, syntax: syntax]}

        case apply(parser_module, :to_ast, [@splitter <> input, plume]) do
          %Plume{ast: "", tail: ""} ->
            plume

          %Plume{ast: ast, tail: ""} ->
            %Plume{plume | ast: plume.ast ++ [ast]}

          # %Plume{plume | ast: tail, tail: ""}
          %Plume{ast: "", tail: tail} ->
            astify(tail, plume, syntax)

          %Plume{ast: ast, tail: tail} ->
            astify(tail, %Plume{plume | ast: plume.ast ++ [ast]}, syntax)
        end
      end

      defp parser(nil), do: nil

      defp parser(syntax) do
        hash =
          :md5
          |> :crypto.hash(inspect(syntax))
          |> Base.encode16()

        Markright.Utils.parser!(
          Module.concat("Markright.Parsers", "Syntax_#{hash}"),
          syntax,
          __ENV__
        )
      end
    end
  end
end
