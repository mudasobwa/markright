defmodule Markright.Helpers.Lead do
  @moduledoc ~S"""
  Generic handler for leads. Use as:

  ```elixir
  defmodule Markright.Parsers.Li do
    use Markright.Parsers.Lead
  end
  ```
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Markright.Parser
      @li Markright.Syntax.lead()[__MODULE__ |> Markright.Utils.denamespace |> Markright.Utils.decamelize |> String.to_atom]

      use Markright.Buffer
      use Markright.Continuation

      ##############################################################################

      def to_ast(input, fun \\ nil, opts \\ %{})
        when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

        with %Markright.Continuation{ast: ast, tail: tail} <- astify(input, fun),
             %Markright.Continuation{ast: block, tail: ""} <- Markright.Parsers.Generic.to_ast(ast) do

          Markright.Utils.continuation(%Markright.Continuation{ast: block, tail: tail}, {:li, opts, fun})
        end
      end

      ##############################################################################

      @spec astify(String.t, Function.t, Markright.Buffer.t) :: Markright.Continuation.t
      defp astify(part, fun, acc \\ Markright.Buffer.empty())

      Enum.each(0..Markright.Syntax.indent-1, fn i ->
        @indent String.duplicate(" ", i)
        defp astify(<<
                      @unix_newline :: binary,
                      @indent :: binary,
                      @li :: binary,
                      rest :: binary
                    >>, _fun, acc) do
          %Markright.Continuation{ast: String.trim(acc.buffer), tail: @unix_newline <> @indent <> @li <> rest}
        end
      end)

      defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
        do: astify(rest, fun, Markright.Buffer.append(acc, letter))

      defp astify("", _fun, acc),
        do: %Markright.Continuation{ast: String.trim(acc.buffer), tail: ""}
    end
  end
end
