defmodule Markright.Buffer do

  @typedoc """
  Buffer to hold a string buffer and the FILO of tags.
  """
  @type t :: %Markright.Buffer{}

  @fields [buffer: "", tags: []]

  def fields, do: @fields

  defstruct @fields

  alias Markright.Buffer, as: B

  def empty(data), do: %Markright.Buffer{}
  def empty?(%B{buffer: "", tags: []}), do: true
  def empty?(%B{}), do: false

  def append(%B{} = data, buffer) when is_binary(buffer) do
    %B{data | buffer: data.buffer <> buffer}
  end

  def cleanup(%B{} = data) do
    %B{data | buffer: ""}
  end

  def append_and_cleanup(%B{} = data, buffer) when is_binary(buffer) do
    {data.buffer <> buffer, %B{data | buffer: ""}}
  end

  def push(%B{} = data, tag) when is_atom(tag) do
    %B{data | tags: data.tags ++ [tag]}
  end

  @doc """
    Pops the element from the end of tags. Returns tuple `{elem, rest}`.

    ## Examples

        iex> Markright.Buffer.pop(%Markright.Buffer{tags: [:a, :b, :c]})
        {:c, %Markright.Buffer{buffer: "", tags: [:a, :b]}}
  """
  def pop(%B{} = data) do
    case data.tags do
      [] -> {nil, data}
      list when is_list(list) ->
        {List.last(list), %B{data | tags: Enum.slice(list, 0..Enum.count(list)-2)}}
    end
  end

  def unshift(%B{} = data, tag) when is_tuple(tag) do
    %B{data | tags: [tag] ++ data.tags}
  end

  def shift(%B{} = data) do
    case data.tags do
      [] -> {nil, data}
      [h | t] -> {h, %B{data | tags: t}}
    end
  end

end
