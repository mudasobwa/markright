defmodule Markright.Finalizer do
  @moduledoc """
  The default behaviour for all the finalizers.
  """
  @callback finalize(Markright.Continuation.t) :: Markright.Continuation.t
end
