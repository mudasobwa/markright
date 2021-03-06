defmodule Markright.Helpers.Magnet do
  @moduledoc ~S"""
  Generic handler for magnets. Use as:

  ```elixir
  defmodule Markright.Parsers.Maillink do
    use Markright.Helpers.Magnet magnet: :maillink, tag: :a, attr: :href

    # the below code is redundant, this functions is generated by `use`,
    #   the snippet is here to provide a how-to, since `to_ast/3` is overridable
    def to_ast(input, fun \\ nil, opts \\ %{}) \
      when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts),
    do: astify(input, fun)
  end
  ```

  **NYI:** This file also declares all default magnets. **FIXME** **TODO**
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, module: __MODULE__] do
      @behaviour Markright.Parser

      @tag opts[:tag] || :a
      @continuation opts[:continuation] || :continuation
      @attr opts[:attr] || :href
      @value opts[:value] || :text

      case opts[:magnet_and_handler] ||
             Markright.Syntax.get(
               Markright.Utils.atomic_module_name(module),
               opts[:magnet] || Markright.Utils.atomic_module_name(__MODULE__)
             ) do
        {magnet, handler} ->
          @magnet magnet
          @handler handler

        nil ->
          @magnet ""
          @handler Markright.Parsers.Word

        other ->
          raise Markright.Errors.UnexpectedFeature,
            value: other,
            expected: "{magnet, handler} tuple"
      end

      @terminators [" ", "\n", "\t", "\r", "]", "|"]

      alias Markright.Continuation, as: Plume

      ##############################################################################

      def to_ast(input, %Plume{} = plume) when is_binary(input) do
        cont = astify(input, plume)

        value =
          case @value do
            :empty -> %Plume{plume | ast: "", tail: input}
            :text -> cont
          end

        attrs =
          case @attr do
            :empty -> %{}
            some -> %{some => cont.ast}
          end

        Markright.Utils.continuation(@continuation, value, {@tag, attrs})
      end

      defoverridable to_ast: 2

      ##############################################################################

      @spec astify(String.t(), Markright.Continuation.t()) :: Markright.Continuation.t()
      defp astify(part, plume)

      ##############################################################################

      Enum.each(@terminators, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter::binary, _rest::binary>> = rest, %Plume{} = plume),
          do: Plume.astail!(plume, rest)
      end)

      Module.delete_attribute(__MODULE__, :delimiter)

      defp astify(<<letter::binary-size(1), rest::binary>>, %Plume{} = plume),
        do: astify(rest, Plume.tail!(plume, letter))

      defp astify("", %Plume{} = plume),
        do: %Plume{plume | ast: String.trim(plume.tail), tail: ""}
    end
  end
end
