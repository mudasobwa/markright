defmodule Markright.Helpers.Lead do
  @moduledoc ~S"""
  Generic handler for leads. Use as:

  ```elixir
  defmodule Markright.Parsers.Li do
    use Markright.Helpers.Lead
  end
  ```
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, module: __MODULE__] do
      @behaviour Markright.Parser

      use Markright.Continuation
      alias Markright.Continuation, as: Plume

      @tag opts[:tag] || Markright.Utils.atomic_module_name(__MODULE__)
      case opts[:lead_and_handler] ||
             Markright.Syntax.take(
               Markright.Utils.atomic_module_name(module),
               opts[:lead] || @tag
             ) do
        {lead, handler} ->
          @lead [lead]
          @handler [handler]

        [{lead, handler}] ->
          @lead [lead]
          @handler [handler]

        many ->
          @lead Enum.map(many, &elem(&1, 0))
          @handler Enum.map(many, &elem(&1, 1))

        other ->
          raise Markright.Errors.UnexpectedFeature,
            value: other,
            expected: "{lead, handler} tuple"
      end

      ##############################################################################

      def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
        with %Plume{ast: ast, tail: tail} <- astify(input, plume),
             plume <- plume |> Plume.untail!(),
             %Plume{ast: block, tail: ""} <- apply(plume.bag[:parser], :to_ast, [ast, plume]) do
          Markright.Utils.continuation(%Plume{plume | ast: block, tail: tail}, {@tag, %{}})
        end
      end

      ##############################################################################

      @spec astify(String.t(), Markright.Continuation.t()) :: Markright.Continuation.t()
      defp astify(part, plume)

      defp astify(<<unquote(@splitter)::binary, rest::binary>>, %Plume{} = plume),
        do: Plume.astail!(plume, rest)

      Enum.each(@lead, fn l ->
        @l l
        Enum.each(0..(Markright.Syntax.indent() - 1), fn i ->
          @indent String.duplicate(" ", i)
          defp astify(
                 <<
                   @unix_newline::binary,
                   @indent::binary,
                   @l::binary,
                   rest::binary
                 >>,
                 %Plume{} = plume
               ) do
            %Plume{
              plume
              | ast: String.trim(plume.tail),
                tail: @unix_newline <> @indent <> @l <> rest
            }
          end
        end)
      end)

      defp astify(<<letter::binary-size(1), rest::binary>>, %Plume{} = plume),
        do: astify(rest, Plume.tail!(plume, letter))

      defp astify("", %Plume{} = plume), do: Plume.astail!(plume, "", true)
    end
  end
end
