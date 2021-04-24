defmodule Markright.Utils do
  @moduledoc ~S"""
  The utilities, used amongst the `Markright`.
  """

  use Markright.Continuation

  ##############################################################################

  def parser!(name, syntax, env \\ __ENV__) when is_atom(name) do
    case Code.ensure_loaded(name) do
      {:module, name} ->
        name

      {:error, _} ->
        contents =
          quote do
            use Markright.WithSyntax, syntax: unquote(syntax)
          end

        Module.create(name, contents, Macro.Env.location(env))
        name
    end
  end

  ##############################################################################

  def empty?(nil), do: true
  def empty?(""), do: true
  def empty?([]), do: true
  def empty?({}), do: true
  def empty?(%{}), do: true

  # If you want to uncomment the next line, PLEASE DON’T DO THAT
  # def empty?(s) when is_binary(s), do: String.trim(s) == ""
  def empty?({_, _, s}) when is_binary(s) or is_list(s) or is_map(s) or is_tuple(s), do: empty?(s)

  def empty?(list) when is_list(list), do: Enum.all?(list, &empty?/1)

  def empty?(map) when is_map(map),
    do:
      Enum.all?(map, fn
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
        empty?(e) -> acc
        is_list(e) -> acc ++ if flatten, do: squeeze!(e), else: [squeeze!(e)]
        true -> acc ++ [e]
      end
    end)
    |> unlist
  end

  def squeeze!(anything, _flatten), do: if(empty?(anything), do: [], else: anything)
  def join!(asts, flatten \\ true) when is_list(asts), do: squeeze!(asts, flatten)

  ##############################################################################

  defp unlist([string]) when is_binary(string), do: string
  defp unlist(anything), do: anything

  ##############################################################################

  @spec to_parser_module(Atom.t(), List.t()) :: Atom.t()
  def to_parser_module(atom, opts \\ []),
    do: to_module(Markright.Parsers, atom, opts)

  @spec to_finalizer_module(Atom.t(), List.t()) :: Atom.t()
  def to_finalizer_module(atom, opts \\ []),
    do: to_module(Markright.Finalizers, atom, opts)

  @spec to_preset_module(Atom.t(), List.t()) :: Atom.t()
  def to_preset_module(atom, opts \\ []),
    do: to_module(Markright.Presets, atom, opts)

  @spec to_module(Atom.t(), Atom.t(), List.t()) :: Atom.t()
  defp to_module(prefix, atom, opts) do
    opts = Keyword.merge([prefix: prefix, fallback: Module.concat(prefix, Generic)], opts)
    mod = to_module_name(atom, prefix: opts[:prefix])
    if Code.ensure_loaded?(mod), do: mod, else: opts[:fallback]
  end

  @spec all_of(Atom.t()) :: [Atom.t()]
  def all_of(<<"Elixir."::binary, prefix::binary>>), do: all_of(prefix)

  def all_of(prefix) when is_binary(prefix) do
    Enum.filter(get_modules(), &String.starts_with?(&1, "Elixir." <> prefix))
  end

  def all_of(prefix) when is_atom(prefix), do: all_of(Atom.to_string(prefix))

  defp get_modules do
    modules = Enum.map(:code.all_loaded(), &Atom.to_string(elem(&1, 0)))

    case :code.get_mode() do
      :interactive -> modules ++ get_modules_from_applications()
      _otherwise -> modules
    end
  end

  defp get_modules_from_applications do
    for [app] <- :ets.match(:ac_tab, {{:loaded, :"$1"}, :_}),
        {:ok, modules} = :application.get_key(app, :modules),
        module <- modules do
      Atom.to_string(module)
    end
  end

  @spec atomic_module_name(Atom.t()) :: Atom.t()
  def atomic_module_name(mod) do
    mod
    |> denamespace
    |> decamelize
    |> String.to_atom()
  end

  ##############################################################################

  @spec continuation(Atom.t(), Markright.Continuation.t(), {Atom.t(), Map.t()}) ::
          Markright.Continuation.t()
  def continuation(:continuation, %Plume{} = plume, {tag, %{} = attrs}) do
    case Plume.callback(Plume.continue(plume, {tag, attrs}), plume.fun) do
      %Plume{} = plume -> apply(to_finalizer_module(tag), :finalize, [plume])
      other -> raise Markright.Errors.UnexpectedContinuation, value: other
    end
  end

  def continuation(:ast, %Plume{} = plume, {tag, %{} = attrs}) do
    continuation(:continuation, plume, {tag, attrs}).ast
  end

  def continuation(:tail, %Plume{} = plume, {tag, %{} = attrs}) do
    continuation(:continuation, plume, {tag, attrs}).tail
  end

  def continuation(:empty, %Plume{} = plume, {tag, %{} = attrs}) do
    case Plume.callback(Plume.continue(plume, {tag, attrs, nil}), plume.fun) do
      %Plume{} = plume -> apply(to_finalizer_module(tag), :finalize, [plume])
      other -> raise Markright.Errors.UnexpectedContinuation, value: other
    end
  end

  @spec continuation(Markright.Continuation.t(), {Atom.t(), Map.t()}) ::
          Markright.Continuation.t()
  def continuation(%Plume{} = plume, {tag, %{} = attrs}) do
    continuation(:continuation, plume, {tag, attrs})
  end

  @spec delimit(Markright.Continuation.t()) :: Markright.Continuation.t()
  def delimit(%Plume{tail: tail} = plume) do
    delimit = if empty?(tail), do: "", else: @splitter <> String.trim_leading(tail, @unix_newline)
    %Plume{plume | tail: delimit}
  end

  ##############################################################################

  @spec split_ast(String.t() | List.t()) :: {String.t() | List.t(), List.t()}

  @splitters ~w|p div|a ++ (Markright.Syntax.block() |> Keyword.keys() |> Enum.uniq())
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

  @spec surround(Markright.Continuation.t(), Atom.t(), Atom.t()) :: Markright.Continuation.t()
  def surround(%Plume{ast: ast} = plume, tag, surrounding) when is_list(ast) do
    {head, middle_and_tail} =
      Enum.split_while(ast, fn
        {^tag, _, _} -> false
        _ -> true
      end)

    {middle, tail} =
      Enum.split_while(middle_and_tail, fn
        {^tag, _, _} -> true
        # FIXME!!!!
        {t, _, _} -> tag == :dt && t == :dd
        _ -> false
      end)

    {tail_head, tail_tail} = head_tail(tail)

    new_tail_head = case tail_head do
      {^surrounding, _, content} ->  [{surrounding, %{},  middle ++ content}]
      [] -> [{surrounding, %{}, middle}]
      element ->  [{surrounding, %{}, middle}] ++ [element]
    end

    ast = head ++ new_tail_head ++ tail_tail

    %Plume{plume | ast: ast}
  end

  defp head_tail([head|tail]), do: {head, tail}
  defp head_tail([]), do: {[],[]}


  ##############################################################################

  @spec to_module_name(Atom.t(), List.t()) :: Atom.t()
  defp to_module_name(atom, opts) do
    if String.starts_with?("#{atom}", "Elixir.") do
      atom
    else
      mod =
        atom
        |> to_string
        |> String.downcase()
        |> Macro.camelize()

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
    |> String.downcase()
  end

  def denamespace(atom) when is_atom(atom), do: atom |> to_string |> denamespace

  def denamespace(string) when is_binary(string),
    do: string |> String.split(".") |> Enum.at(-1)

  ##############################################################################
end
