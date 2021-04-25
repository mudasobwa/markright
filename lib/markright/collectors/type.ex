defmodule Markright.Collectors.Type do
  @moduledoc ~S"""
  Collector that determines the type of the article.

  The pattern is:

  - **:decorated** — the article has at least one image in it
  - **:tech** — the article includes code blocks, value is the list of languages used
  - `type` as:
    - **:default** — default
    - **:twit** — single sentense, presumably of length <= 140 symbols (not validated here)
    - **:image** — the article contains a single image only
    - **:album** — the article has at least two images
  ```
  """

  @behaviour Markright.Collector

  @type t :: %__MODULE__{
          type: :default | :twit | :mediatwit | :image | :album | :reference,
          decorated: true | false,
          tech: list()
        }

  ##############################################################################

  @fields [type: :default, decorated: false, tech: []]
  def fields, do: @fields
  defstruct @fields

  def on_ast(%Markright.Continuation{ast: ast} = _cont, acc) do
    case ast do
      {:pre, _, [{:code, %{lang: lang}, _}]} ->
        put_in_kwd(acc, :tech, lang)

      {:p, _, _} ->
        put_in_int(acc, :paras)

      {:img, _, _} ->
        put_in_int(acc, :images)

      {:figure, _, _} ->
        put_in_int(acc, :images)

      {:blockquote, %{}, ast} when is_list(ast) ->
        case :lists.reverse(ast) do
          [{:a, %{href: _}, _} | _] -> put_in_int(acc, :blockquotes)
          _ -> put_in_kwd(acc, :rest, :blockquote)
        end

      # {:figure, _, _} -> put_in(acc, :images, (acc[:images] || 0) + 1) # FIXME!!! support figures
      {:article, _, _} ->
        acc

      {other, _, _} ->
        put_in_kwd(acc, :rest, other)
    end
  end

  def afterwards(acc, _opts) do
    decorated = !is_nil(acc[:images])

    type =
      case acc[:images] do
        nil -> if acc[:paras] == 1 and is_nil(acc[:rest]), do: :twit, else: :default
        1 -> if acc[:paras] == 1, do: :mediatwit, else: :image
        _ -> :album
      end

    type = if is_nil(acc[:blockquotes]), do: type, else: :reference
    tech = if acc[:tech], do: Enum.uniq(acc[:tech])
    %Markright.Collectors.Type{type: type, decorated: decorated, tech: tech}
  end

  ##############################################################################

  defp put_in_kwd(acc, key, value) do
    with {_, upd} <-
           Keyword.get_and_update(acc, key, fn
             nil -> {nil, [value]}
             list when is_list(list) -> {list, [value | list]}
           end),
         do: upd
  end

  defp put_in_int(acc, key) do
    with {_, upd} <-
           Keyword.get_and_update(acc, key, fn
             nil -> {nil, 1}
             n when is_integer(n) -> {n, n + 1}
           end),
         do: upd
  end
end
