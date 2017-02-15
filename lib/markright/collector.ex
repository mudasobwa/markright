defmodule Markright.Collector do
  @moduledoc """
  The default behaviour for all the collectors. Collectors are designed
  to be called on AST transformation to collect the data while the AST is
  being created.

  The example of collector would be `Markright.Collectors.OgpTwitter`,
  which is responsible for collecting the title, the image and the description
  of the content data being parsed.
  """
  @callback on_ast(Markright.Continuation.t, any) :: any

  defmacro __using__(opts) do
    quote bind_quoted: [collectors: opts[:collectors] || [], module: __MODULE__] do
      @behaviour Markright.Collector

      @collectors if is_list(collectors), do: collectors, else: [collectors]

      ##########################################################################

      @doc false
      def start_link, do: Agent.start_link(fn -> [] end, name: __MODULE__)

      @doc false
      def stop, do: Agent.stop(__MODULE__)

      @doc "Updates the collectors"
      def ast_collect!(collector, value),
        do: Agent.update(__MODULE__, &Keyword.put(&1, collector, value))

      @doc "Retrieves the collected values"
      def ast_collected(),
        do: Agent.get(__MODULE__, &(&1))

      @doc "Retrieves the collected value for the particular collector"
      def ast_collected(collector, default_accumulator \\ []) when is_atom(collector),
        do: Agent.get(__MODULE__, &Keyword.get(&1, collector, default_accumulator))

      ##########################################################################

      def on_ast(%Markright.Continuation{} = cont, default_accumulator) do
        Enum.each(@collectors, fn collector when is_atom(collector) ->
          ast_collect!(collector, apply(collector, :on_ast, [cont, ast_collected(collector, default_accumulator)]))
        end)
        unless is_nil(internal = on_ast(cont)), do: ast_collect!(__MODULE__, ast_collected(__MODULE__) ++ [internal])
      end

      def on_ast_callback, do: fn(%Markright.Continuation{} = cont) -> on_ast(cont, []) end

      ##########################################################################

      def on_ast(%Markright.Continuation{} = _cont), do: nil

      defoverridable [on_ast: 1]
    end
  end
end