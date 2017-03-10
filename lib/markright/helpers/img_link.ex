defmodule Markright.Helpers.ImgLink do
  @moduledoc ~S"""
  Common code for `Markright.Parsers.Img` and `Markright.Parsers.Link`.
  """

  defmacro __using__(_opts) do
    quote do
      alias Markright.Continuation, as: Plume
      ##############################################################################

      @spec astify(String.t, Markright.Continuation.t) :: Markright.Continuation.t
      defp astify(part, plume)

      ##############################################################################

      Enum.each(~w/]( |/, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter :: binary, rest :: binary>>, %Plume{} = plume) do
          with {tail, plume} <- Plume.detail!(plume),
               %Plume{} = plume <- astify(rest, plume),
            do: %Plume{plume | ast: [tail, plume.ast], tail: plume.tail}
        end
      end)

      Enum.each(~w/] )/, fn delimiter ->
        @delimiter delimiter
        defp astify(<<@delimiter :: binary, rest :: binary>>, %Plume{} = plume),
          do: Plume.astail!(plume, rest)
      end)
      Module.delete_attribute(__MODULE__, :delimiter)

      defp astify(<<letter :: binary-size(1), rest :: binary>>, %Plume{} = plume),
        do: astify(rest, Plume.tail!(plume, letter))
    end
  end
end
