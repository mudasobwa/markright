defmodule Markright.Finalizers.Generic do
  @moduledoc false

  # Generic (**noop**) finalizer.

  @behaviour Markright.Finalizer

  @spec finalize(Markright.Continuation.t) :: Markright.Continuation.t
  def finalize(%Markright.Continuation{} = cont), do: cont

end
