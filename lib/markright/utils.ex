defmodule Markright.Utils do

  ##############################################################################

  use Markright.Continuation

  import Markright.Guards

  ##############################################################################

  def join!(asts, flatten \\ true) when is_list(asts), do: squeeze!(asts, flatten)

  ##############################################################################

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  def to_module(atom, opts \\ []) do
    opts = Keyword.merge(
      [prefix: Markright.Parsers, fallback: Markright.Parsers.Generic], opts)
    mod = to_module_name(atom, [prefix: opts[:prefix]])
    if Code.ensure_loaded?(mod), do: mod, else: opts[:fallback]
  end

  @spec atomic_module_name(Atom.t) :: Atom.t
  def atomic_module_name(mod) do
    mod
    |> denamespace
    |> decamelize
    |> String.to_atom
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
    |> Markright.Guards.squeeze!
  end

  ##############################################################################

  @spec surround(Markright.Continuation.t | List.t | String.t, Atom.t, Atom.t) :: Markright.Continuation.t | List.t | String.t
  # {["Hello, world! List here:",
  #    {:li, %{}, "item 1"},
  #    {:li, %{}, "item 2"},
  #    {:li, %{}, "item 3"},
  #  {:p, %{}, "Afterparty."}], []}
  def surround(%C{} = cont, tag, surrounding),
    do: %C{cont | ast: surround(cont.ast, tag, surrounding)}
  def surround(ast, tag, surrounding) when is_list(ast) do
    {head, middle_and_tail} = Enum.split_while(ast, fn
      {^tag, _, _} -> false
      _ -> true
    end)
    {middle, tail} = Enum.split_while(middle_and_tail, fn
      {^tag, _, _} -> true
      _ -> false
    end)
    (if Enum.empty?(head), do: middle, else: head ++ [[{surrounding, %{}, middle}]]) ++ tail
  end
  def surround(ast, _tag, _surrounding), do: ast

  ##############################################################################

  @spec to_module_name(Atom.t, List.t) :: Atom.t
  defp to_module_name(atom, opts) do
    if String.starts_with?("#{atom}", "Elixir.") do
      atom
    else
      mod = atom
            |> to_string
            |> String.downcase
            |> Macro.camelize
      if is_atom(opts[:prefix]), do: Module.concat(opts[:prefix], mod), else: mod
    end
  end

  def camelize(str) when is_binary(str) do
    Regex.replace(~r/(?:_|\A)(.)/, str, fn _, m -> String.upcase(m) end)
  end

  def decamelize(atom) when is_atom(atom), do: atom |> to_string |> decamelize
  def decamelize(str) when is_binary(str) do
    ~r/(?<!\A)\p{Lu}/
    |> Regex.replace(str, fn _, m -> "_" <> m end)
    |> String.downcase
  end

  def denamespace(atom) when is_atom(atom), do: atom |> to_string |> denamespace
  def denamespace(string) when is_binary(string),
    do: string |> String.split(".") |> Enum.at(-1)

  ##############################################################################

end
