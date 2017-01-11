defmodule Markright.Utils do

  ##############################################################################

  use Markright.Continuation

  import Markright.Guards

  ##############################################################################

  def join!(asts, flatten \\ true) when is_list(asts), do: squeeze!(asts, flatten)

  ##############################################################################

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  def to_module(atom, opts \\ [prefix: Markright.Parsers, fallback: Markright.Parsers.Generic]) do
    mod = to_module_name(atom, [prefix: opts[:prefix]])
    if Code.ensure_loaded?(mod), do: mod, else: opts[:fallback]
  end

  ##############################################################################

  @spec continuation(Atom.t, Markright.Continuation.t, {Atom.t, Map.t, Function.t}) :: Markright.Continuation.t
  def continuation(:continuation, cont, {tag, opts, fun}) do
    case C.callback(C.continue(cont, {tag, opts}), fun) do
      %C{} = c -> c
      other    -> raise Markright.Errors.UnexpectedContinuation, value: other
    end
  end

  def continuation(:ast, cont, {tag, opts, fun}) do
    continuation(:continuation, cont, {tag, opts, fun}).ast
  end

  def continuation(:tail, cont, {tag, opts, fun}) do
    continuation(:continuation, cont, {tag, opts, fun}).tail
  end

  def continuation(:empty, cont, {tag, opts, fun}) do
    case C.callback(C.continue({tag, opts, nil}, cont.tail), fun) do
      %C{} = c -> c
      other    -> raise Markright.Errors.UnexpectedContinuation, value: other
    end
  end

  @spec continuation(Markright.Continuation.t, {Atom.t, Map.t, Function.t}) :: Markright.Continuation.t
  def continuation(cont, {tag, opts, fun}) do
    continuation(:continuation, cont, {tag, opts, fun})
  end

  ##############################################################################

  @spec split_ast(String.t | List.t) :: {String.t | List.t, List.t}
  def split_ast(ast) when is_binary(ast), do: {ast, []}
  def split_ast(ast) when is_list(ast) do
    Enum.split_while(ast, fn
      {:p, _, _} -> false
      {:pre, _, _} -> false
      {:blockquote, _, _} -> false
      _ -> true
    end)
   end

  ##############################################################################

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  defp to_module_name(atom, opts) do
    if String.starts_with?("#{atom}", "Elixir.") do
      atom
    else
      mod = atom
            |> to_string
            |> String.downcase
            |> camelize
      if is_atom(opts[:prefix]), do: Module.concat(opts[:prefix], mod), else: mod
    end
  end

  defp camelize(str) when is_binary(str) do
    Regex.replace(~r/(?:_|\A)(.)/, str, fn _, m -> String.upcase(m) end)
  end

  ##############################################################################

end
