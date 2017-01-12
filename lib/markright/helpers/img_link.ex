defmodule Markright.Helpers.ImgLink do
  @moduledoc ~S"""
  Common code for `Markright.Parsers.Img` and `Markright.Parsers.Link`.
  """

  defmacro __using__(_opts) do
    quote do
      ##############################################################################

      @spec astify(String.t, Function.t, Markright.Buffer.t) :: Markright.Continuation.t
      defp astify(part, fun, acc \\ Markright.Buffer.empty())

      ##############################################################################

      Enum.each(~w/]( |/, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter :: binary, rest :: binary>>, fun, acc),
          do: with %Markright.Continuation{ast: ast, tail: tail} <- astify(rest, fun),
                do: %Markright.Continuation{ast: [acc.buffer, ast], tail: tail}
      end)

      Enum.each(~w/] )/, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter :: binary, rest :: binary>>, _fun, acc),
          do: %Markright.Continuation{ast: acc.buffer, tail: rest}
      end)

      defp astify(<<letter :: binary-size(1), rest :: binary>>, fun, acc),
        do: astify(rest, fun, Markright.Buffer.append(acc, letter))

      ##############################################################################

      @delimiter nil
    end
  end
end
