defmodule Markright.Buffer do

  @typedoc """
  Buffer to hold a string buffer and the FILO of tags.
  """
  @type t :: %Markright.Buffer{}

  @fields [buffer: "", tags: []]

  def fields, do: @fields

  defstruct @fields

  alias Markright.Buffer, as: Buf

  def empty, do: %Buf{}
  def empty?(%Buf{buffer: "", tags: []}), do: true
  def empty?(%Buf{}), do: false

  defmacro __using__(_opts) do
    quote do
      alias Markright.Buffer, as: Buf
      defmacrop is_empty_buffer(data) do
        quote do: %Buf{buffer: "", tags: []} == unquote(data)
      end
    end
  end

  def append(%Buf{} = data, buffer) when is_binary(buffer) do
    %Buf{data | buffer: data.buffer <> buffer}
  end

  def cleanup(%Buf{} = data) do
    %Buf{data | buffer: ""}
  end

  def append_and_cleanup(%Buf{} = data, buffer) when is_binary(buffer) do
    {data.buffer <> buffer, %Buf{data | buffer: ""}}
  end

  def unshift_and_cleanup(%Buf{} = data, tag) when is_tuple(tag) do
    %Buf{data | tags: [tag] ++ data.tags, buffer: ""}
  end

  def push(%Buf{} = data, tag) when is_tuple(tag) do
    %Buf{data | tags: data.tags ++ [tag]}
  end

  @doc """
    Pops the element from the end of tags. Returns tuple `{elem, rest}`.

    ## Examples

        iex> Markright.Buffer.pop(%Markright.Buffer{tags: [:a, :b, :c]})
        {:c, %Markright.Buffer{buffer: "", tags: [:a, :b]}}
  """
  def pop(%Buf{} = data) do
    case data.tags do
      [] -> {nil, data}
      list when is_list(list) ->
        {List.last(list), %Buf{data | tags: Enum.slice(list, 0..Enum.count(list)-2)}}
    end
  end

  def unshift(%Buf{} = data, tag) when is_tuple(tag) do
    %Buf{data | tags: [tag] ++ data.tags}
  end

  def shift(%Buf{} = data) do
    case data.tags do
      [] -> {nil, data}
      [h | t] -> {h, %Buf{data | tags: t}}
    end
  end

end
