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

      @tag opts[:tag] || Markright.Utils.atomic_module_name(__MODULE__)
      case opts[:lead_and_handler] || Markright.Syntax.get(Markright.Utils.atomic_module_name(module), opts[:lead] || @tag) do
        {lead, handler} ->
          @lead lead
          @handler handler
        other -> raise Markright.Errors.UnexpectedFeature, value: other, expected: "{lead, handler} tuple"
      end

      use Markright.Buffer
      use Markright.Continuation

      ##############################################################################

      def to_ast(input, fun \\ nil, opts \\ %{})
        when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

        with %Markright.Continuation{ast: ast, tail: tail} <- astify(input),
             %Markright.Continuation{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast) do

          Markright.Utils.continuation(%Markright.Continuation{ast: block, tail: tail}, {@tag, opts, fun})
        end
      end

      ##############################################################################

      @spec astify(String.t, Markright.Buffer.t) :: Markright.Continuation.t
      defp astify(part, acc \\ Markright.Buffer.empty())

      defp astify(<<unquote(@splitter) :: binary, rest :: binary>>, acc),
        do: %Markright.Continuation{ast: acc.buffer, tail: rest}

      Enum.each(0..Markright.Syntax.indent - 1, fn i ->
        @indent String.duplicate(" ", i)
        defp astify(<<
                      @unix_newline :: binary,
                      @indent :: binary,
                      @lead :: binary,
                      rest :: binary
                    >>, acc) do
          %Markright.Continuation{ast: String.trim(acc.buffer), tail: @unix_newline <> @indent <> @lead <> rest}
        end
      end)

      defp astify(<<letter :: binary-size(1), rest :: binary>>, acc),
        do: astify(rest, Markright.Buffer.append(acc, letter))

      defp astify("", acc),
        do: %Markright.Continuation{ast: String.trim(acc.buffer), tail: ""}
    end
  end
end
