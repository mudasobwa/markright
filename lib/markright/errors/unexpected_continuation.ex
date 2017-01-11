defmodule Markright.Errors.UnexpectedContinuation do
  defexception [:value, :expected, :message]

  def exception(value: value, expected: expected) do
    message = "Value [#{inspect(value)}] is expected to be a #{expected}."
    %Markright.Errors.UnexpectedContinuation{value: value, expected: expected, message: message}
  end

  def exception(value: value) do
    exception(value: value, expected: :continuation)
  end
end
