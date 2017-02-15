defmodule Markright.Finalizers.Dt do
  @moduledoc ~S"""
  Finalizer for `dt` tag: makes `dt`/`dd` pair out of it.
  """

  @behaviour Markright.Finalizer

  @spec finalize(Markright.Continuation.t) :: Markright.Continuation.t
  def finalize(%Markright.Continuation{} = cont) do
    %Markright.Continuation{cont | ast:
      case cont.ast do
        {:dt, attrs, content} -> split(content, attrs)
        other -> other
      end
    }
  end

  ##############################################################################

  defp split(content, attrs) when is_binary(content) do
    case String.split(content, [":", "\n", "⇒", "—"], parts: 2) do
      [dt, dd] -> [{:dt, attrs, dt}, {:dd, attrs, dd}]
      [dd] ->     [{:dt, attrs, ""}, {:dd, attrs, dd}]
    end
  end
  defp split([h | t], attrs) when is_binary(h) do
    case String.split(h, [":", "\n", "⇒", "—"], parts: 2) do
      [dt, dd] -> [{:dt, attrs, dt}, {:dd, attrs, [dd | t]}]
      [dd] ->     [{:dt, attrs, ""}, {:dd, attrs, [dd | t]}]
    end
  end
  defp split([h | t], attrs), do: [{:dt, attrs, h}, {:dd, attrs, t}]
end
