defmodule Markright.Errors.UnexpectedSyntax do
  defexception [:value, :expected, :message]

  def exception(value: value, expected: expected) do
    message = "Could not understand [#{inspect(value)}]. It is expected to be a #{expected}."
    %Markright.Errors.UnexpectedSyntax{value: value, expected: expected, message: message}
  end

  def exception(value: value) do
    exception(value: value, expected: :invalid_syntax)
  end
end
