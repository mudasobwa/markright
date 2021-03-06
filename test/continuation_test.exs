defmodule Markright.Continuation.Test do
  use ExUnit.Case
  use Markright.Tester
  doctest Markright.Continuation

  test "is_last guard" do
    defmodule Sample do
      use Markright.Continuation
      def guarded(%Markright.Continuation{tail: tail} = _data) when tail == "", do: :last
      def guarded(%Markright.Continuation{tail: _tail} = _data), do: :leading
    end

    data = %Markright.Continuation{}
    assert Sample.guarded(data) == :last
    assert Sample.guarded(%Markright.Continuation{tail: "hello"}) == :leading
  after
    purge(Sample)
  end
end
