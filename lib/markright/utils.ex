defmodule Markright.Utils do
  @moduledoc ~S"""
  The utilities, used amongst the `Markright`.
  """

  use Markright.Continuation

  ##############################################################################

  def empty?(nil), do: true
  def empty?(""), do: true
  def empty?([]), do: true
  def empty?({}), do: true
  def empty?(%{}), do: true
  def empty?({_, _, ""}), do: true
  def empty?({_, _, []}), do: true

  def empty?(list) when is_list(list), do: Enum.all?(list, &empty?/1)
  def empty?(map) when is_map(map), do: Enum.all?(map, fn
    {_, v} -> empty?(v)
    v -> empty?(v)
  end)
  def empty?(_), do: false
  def empty?(arg1, arg2), do: empty?(arg1) and empty?(arg2)
  def empty?(arg1, arg2, arg3), do: empty?(arg1, arg2) and empty?(arg3)

  ##############################################################################

  def squeeze!(ast, flatten \\ true)
  def squeeze!({ast1, ast2}, flatten), do: {squeeze!(ast1, flatten), squeeze!(ast2, flatten)}
  def squeeze!({tag, opts, ast}, flatten), do: {tag, opts, squeeze!(ast, flatten)}
  def squeeze!(ast, flatten) when is_list(ast) do
    ast
    |> Enum.reduce([], fn e, acc ->
      cond do
        empty?(e)  -> acc
        is_list(e) -> acc ++ (if flatten, do: squeeze!(e), else: [squeeze!(e)])
        true       -> acc ++ [e]
      end
    end)
    |> unlist
  end
  def squeeze!(anything, _flatten), do: if empty?(anything), do: [], else: anything
  def join!(asts, flatten \\ true) when is_list(asts), do: squeeze!(asts, flatten)

  ##############################################################################

  defp unlist([string]) when is_binary(string), do: string
  defp unlist(anything), do: anything

  ##############################################################################

  @spec to_parser_module(Atom.t, List.t) :: Atom.t
  def to_parser_module(atom, opts \\ []),
    do: to_module(Markright.Parsers, atom, opts)

  @spec to_finalizer_module(Atom.t, List.t) :: Atom.t
  def to_finalizer_module(atom, opts \\ []),
    do: to_module(Markright.Finalizers, atom, opts)

  @spec to_module(Atom.t, Atom.t, List.t) :: Atom.t
  defp to_module(prefix, atom, opts) do
    opts = Keyword.merge([prefix: prefix, fallback: Module.concat(prefix, Generic)], opts)
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
      %C{} = c -> apply(to_finalizer_module(tag), :finalize, [c])
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
      %C{} = c -> apply(to_finalizer_module(tag), :finalize, [c])
      other    -> raise Markright.Errors.UnexpectedContinuation, value: other
    end
  end

  @spec continuation(Markright.Continuation.t, {Atom.t, Map.t, Function.t}) :: Markright.Continuation.t
  def continuation(cont, {tag, opts, fun}) do
    continuation(:continuation, cont, {tag, opts, fun})
  end

  ##############################################################################

  @spec split_ast(String.t | List.t) :: {String.t | List.t, List.t}

  @splitters ~w|p div|a ++ Keyword.keys(Markright.Syntax.block())
  @clauses Enum.map(@splitters, fn tag ->
    {:->, [], [[{:{}, [], [tag, {:_, [], Elixir}, {:_, [], Elixir}]}], false]}
  end) ++ [{:->, [], [[{:_, [], Elixir}], true]}]
  defmacrop split_while_ast_function, do: {:fn, [], @clauses}

  def split_ast(ast) when is_binary(ast), do: {ast, []}
  def split_ast(ast) when is_list(ast) do
    ast
    |> Enum.split_while(split_while_ast_function())
    |> squeeze!
  end

  ##############################################################################

  @spec surround(Markright.Continuation.t | List.t | String.t, Atom.t, Atom.t) :: Markright.Continuation.t | List.t | String.t
  def surround(%C{} = cont, tag, surrounding),
    do: %C{cont | ast: surround(cont.ast, tag, surrounding)}
  def surround(ast, tag, surrounding) when is_list(ast) do
    {head, middle_and_tail} = Enum.split_while(ast, fn
      {^tag, _, _} -> false
      _ -> true
    end)
    {middle, tail} = Enum.split_while(middle_and_tail, fn
      {^tag, _, _} -> true
      {t, _, _} ->
        tag == :dt && t == :dd # FIXME!!!!
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
