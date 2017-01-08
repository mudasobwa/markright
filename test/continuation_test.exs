defmodule Markright.Continuation.Test do
  use ExUnit.Case
  use Markright.Tester
  doctest Markright.Continuation

  test "is_last guard" do
    Code.eval_string """
    defmodule Sample do
      use Markright.Continuation
      def guarded(%C{tail: tail} = _data) when tail == "", do: :last
      def guarded(%C{tail: _tail} = _data), do: :leading
    end
    """
    data = %Markright.Continuation{}
    assert Sample.guarded(data) == :last
    assert Sample.guarded(%Markright.Continuation{tail: "hello"}) == :leading
  after
    purge Sample
  end
end
