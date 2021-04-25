defmodule Markright.Continuation do
  @moduledoc """
  The tuple, that is being returned from any call to `Parser.to_ast/3`.
  """

  ##############################################################################

  @typedoc """
  The continuation, returned from any call to `Parser.to_ast/3`.
  """
  @type t :: %__MODULE__{
          ast: tuple() | list(),
          tail: String.t(),
          bag: list(),
          fun: (Markright.Continuation.t() -> Markright.Continuation.t()) | nil
        }

  ##############################################################################

  @unix_newline "\n"

  @fields [ast: [], tail: "", bag: [tags: [], parser: Markright.Parsers.Generic], fun: nil]

  def fields, do: @fields

  defstruct @fields

  ##############################################################################

  defmacro __using__(_opts) do
    quote do
      @unix_newline unquote(@unix_newline)
      @splitter @unix_newline <> @unix_newline
      alias Markright.Continuation, as: Plume
    end
  end

  alias Markright.Continuation, as: Plume

  ##############################################################################

  def empty(), do: %Plume{}

  def empty?(%Plume{ast: {nil, _, _}} = _data), do: true
  def empty?(%Plume{ast: {_, _, []}, tail: ""} = _data), do: true
  def empty?(%Plume{ast: {_, _, ""}, tail: ""} = _data), do: true
  def empty?(%Plume{} = _data), do: false

  def last?(%Plume{tail: ""} = _data), do: true
  def last?(%Plume{} = _data), do: false

  def last!(tag, opts, value), do: last!({tag, opts, value})
  def last!({tag, opts, value}), do: %Plume{ast: {tag, opts, value}}

  def tail!(%Plume{tail: tail} = cont, string) when is_binary(string) do
    %Plume{cont | tail: tail <> string}
  end

  def astail!(%Plume{tail: tail} = cont, string \\ "", trim \\ false) when is_binary(string) do
    %Plume{cont | ast: if(trim, do: String.trim(tail), else: tail), tail: string}
  end

  def detail!(%Plume{tail: tail} = cont) do
    {tail, %Plume{cont | tail: ""}}
  end

  def untail!(%Plume{} = cont) do
    %Plume{cont | tail: ""}
  end

  def bag(%Plume{bag: bag} = _cont, key), do: get_in(bag, [key])

  def bag!(%Plume{bag: bag} = cont, {key, value}) do
    %Plume{cont | bag: put_in(bag, [key], value)}
  end

  def debag!(%Plume{bag: bag} = cont, key) do
    {value, bag} = pop_in(bag, [key])
    {value, %Plume{cont | bag: bag}}
  end

  def tag!(%Plume{bag: bag} = cont, {key, value}) do
    %Plume{cont | bag: put_in(bag, [:tags], [{key, value} | bag[:tags] || []])}
  end

  def detag!(%Plume{bag: bag} = cont) do
    case bag[:tags] do
      [{key, value} | tail] -> {{key, value}, %Plume{cont | bag: put_in(bag, [:tags], tail)}}
      _ -> {nil, cont}
    end
  end

  def continue(%Plume{} = data, {tag, opts}),
    do: %Plume{data | ast: {tag, opts, Markright.Utils.squeeze!(data.ast)}}

  def continue(%Plume{} = data, {tag, opts, nil}),
    do: %Plume{data | ast: {tag, opts, nil}}

  def continue(%Plume{} = data, ast, tail)
      when (is_tuple(ast) or is_list(ast)) and is_binary(tail),
      do: %Plume{data | ast: Markright.Utils.squeeze!(ast), tail: tail}

  ##############################################################################

  @spec callback(
          Markright.Continuation.t(),
          (Markright.Continuation.t() -> Markright.Continuation.t())
          | Markright.Continuation.t()
          | nil
        ) ::
          Markright.Continuation.t()
  def callback(data, fun \\ nil)

  def callback(%Plume{} = data, %Plume{} = result),
    do: Map.merge(data, result)

  def callback(%Plume{} = data, fun) when is_function(fun, 1),
    do: callback(data, unless(Markright.Continuation.empty?(data), do: fun.(data)))

  def callback(%Plume{ast: ast, tail: tail} = data, fun) when is_function(fun, 2),
    do: callback(data, unless(Markright.Continuation.empty?(data), do: fun.(ast, tail)))

  def callback(%Plume{} = data, _), do: data
end
