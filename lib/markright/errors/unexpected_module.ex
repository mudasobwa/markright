defmodule Markright.Errors.UnexpectedModule do
  defexception [:value, :expected, :message]

  def exception(value: value, expected: expected) do
    message = "Could not load [#{inspect(value)}]. It is expected to be a #{expected}."
    %Markright.Errors.UnexpectedFeature{value: value, expected: expected, message: message}
  end

  def exception(value: value) do
    exception(value: value, expected: :module)
  end
end
