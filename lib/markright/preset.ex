defmodule Markright.Preset do
  @moduledoc """
  The default behaviour for all the presets.
  """

  @callback syntax() :: Keyword.t()
end
