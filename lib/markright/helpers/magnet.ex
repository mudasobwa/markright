defmodule Markright.Helpers.Magnet do
  @moduledoc ~S"""
  Generic handler for magnets. Use as:

  ```elixir
  defmodule Markright.Parsers.Maillink do
    use Markright.Helpers.Magnet magnet: "mailto:", tag: :a, attr: :href

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

      @magnet opts[:magnet] || Markright.Syntax.get(Markright.Utils.atomic_module_name(module), Markright.Utils.atomic_module_name(__MODULE__))
      @terminators [" ", "\n", "\t", "\r", "]", "|"]

      @tag opts[:tag] || :a
      @continuation opts[:continuation] || :continuation
      @attr opts[:attr] || :href
      @value opts[:value] || :text

      use Markright.Buffer
      use Markright.Continuation

      ##############################################################################

      def to_ast(input, fun \\ nil, opts \\ %{})
        when is_binary(input) and (is_nil(fun) or is_function(fun)) and is_map(opts) do

        link = astify(input)
        value = case @value do
                  :text  -> link
                  :empty -> nil
                end
        attrs = case @attr do
                  :empty -> %{}
                  some -> %{some => link.ast}
                end

        Markright.Utils.continuation(@continuation, link, {@tag, attrs, fun})
      end

      @dialyzer {:nowarn_function, to_ast: 3}
      defoverridable [to_ast: 1, to_ast: 2, to_ast: 3]

      ##############################################################################

      @spec astify(String.t, Markright.Buffer.t) :: Markright.Continuation.t
      defp astify(part, acc \\ Markright.Buffer.empty())

      ##############################################################################

      Enum.each(@terminators, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter :: binary, _rest :: binary>> = rest, acc),
          do: %Markright.Continuation{ast: acc.buffer, tail: rest}
      end)
      Module.delete_attribute(__MODULE__, :delimiter)

      defp astify(<<letter :: binary-size(1), rest :: binary>>, acc),
        do: astify(rest, Markright.Buffer.append(acc, letter))

      defp astify("", acc),
        do: %Markright.Continuation{ast: acc.buffer}
    end
  end
end
