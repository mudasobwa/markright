defmodule Markright.Parsers.Generic do
  @behaviour Markright.Parser

  @max_lookahead     Markright.Syntax.lookahead
  @max_lang_name_len Markright.Syntax.language_name_length

  use Markright.Buffer
  import Markright.Utils, only: [leavify: 1, deleavify: 1, empty_tag?: 1]

  def to_ast(input, fun, opts \\ %{}, acc \\ Buf.empty()) when is_binary(input) and
                                          (is_nil(fun) or is_function(fun)) and
                                           is_map(opts) do

    ast = astify(input, fun, %{}, acc)
    case opts[:only] do
      :ast -> ast
      _    -> {ast, ""}
    end
  end

  ##############################################################################

  @spec callback_through(Tuple.t, Function.t, Buf.t | String.t) :: Tuple.t
  defp callback_through(ast, fun \\ nil, rest \\ nil)
  defp callback_through(ast, nil, rest), do: ast
  defp callback_through(ast, fun, rest) when is_function(fun, 1) do
    fun.({ast, rest})
    callback_through(ast, nil, rest)
  end
  defp callback_through(ast, fun, rest) when is_function(fun, 2) do
    fun.(ast, rest)
    callback_through(ast, nil, rest)
  end

  ##############################################################################

  @spec astify(String.t, Function.t, List.t, Buf.t) :: any
  defp astify(part, fun, opts, acc \\ %Buf{})

  ##############################################################################
  ##  CODE BLOCKS

  Enum.each(0..@max_lang_name_len-1, fn i ->
    defp astify(<<
                  "```"   :: binary,
                  lang    :: binary-size(unquote(i)),
                  "\n"    :: binary,
                  rest    :: binary
                >>, fun, opts, acc) when is_empty_buffer(acc) do
      with {code_ast, tail} <- Markright.Parsers.Code.to_ast(rest, fun, opts) do
        leavify({
          callback_through({:pre, opts, {:code, %{lang: lang}, code_ast}}, fun, acc),
          astify(tail, fun, opts, acc)
        })
      end
    end
  end)

  ##############################################################################
  ##  BLOCKS
  ##############################################################################

  defp astify(<<">"  :: binary, rest :: binary>>, fun, opts, acc) when is_empty_buffer(acc) do
    with {code_ast, tail} <- Markright.Parsers.Generic.to_ast(rest, fun, opts, Buf.unshift(acc, {:blockquote, opts})) do
      leavify({
        callback_through({:blockquote, opts, code_ast}, fun, acc),
        astify(tail, fun, opts, acc)
      })
    end
  end

  ##############################################################################
  ##  Last in BLOCKS

  defp astify(input, fun, opts, acc) when is_binary(input) and is_empty_buffer(acc) do
    callback_through({:p, opts, astify(input, fun, opts, Buf.unshift(acc, {:p, %{}}))}, fun, acc)
  end

  ##############################################################################
  ##############################################################################

  Enum.each(0..@max_lookahead-1, fn i ->
    Enum.each(Markright.Syntax.shields(), fn shield ->
      defp astify(<<
                    plain :: binary-size(unquote(i)),
                    unquote(shield) :: binary,
                    next :: binary-size(1),
                    rest :: binary
                  >>, fun, opts, acc) do
        astify(rest, fun, opts, Buf.append(acc, plain <> next))
      end
    end)

    Enum.each(Markright.Syntax.grips(), fn {t, g} ->
      defp astify(<<plain :: binary-size(unquote(i)), unquote(g) :: binary, rest :: binary>>, fun, opts, acc) do
        case Buf.shift(acc) do
          {{unquote(t), opts}, tail} ->
            [astify(plain, fun, opts, acc), {rest, Buf.cleanup(tail)}]

          _ ->
            deleavify(astify(plain, fun, opts, acc)) ++
            case astify(rest, fun, opts, Buf.unshift_and_cleanup(acc, {unquote(t), opts})) do
              s when is_binary(s) -> deleavify(s)
              astified when is_list(astified) ->
                {ready, [{tbd, tail}]} = Enum.split(astified, -1)

                deleavify(callback_through({unquote(t), opts, leavify(ready)}, fun, tail)) \
                  ++ \
                deleavify(astify(tbd, fun, opts, tail))
            end
        end
      end
    end)
  end)

  defp astify(<<plain :: binary-size(@max_lookahead), rest :: binary>>, fun, opts, acc) do
    astify(rest, fun, opts, Buf.append(acc, plain))
  end

  ##############################################################################
  ### MUST BE LAST
  ##############################################################################

  defp astify(unmatched, _fun, _opts, acc) when is_binary(unmatched) do
    Buf.append(acc, unmatched).buffer
  end

end
