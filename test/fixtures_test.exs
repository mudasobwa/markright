defmodule Markright.Fixtures.Test do
  @moduledoc false
  use ExUnit.Case

  @dir "test/fixtures"

  test "long text" do
    @dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.each(fn file ->
      params = [squeeze: true, silent: true, file: Path.join(@dir, file)]

      assert(
        params
        |> Markright.process()
        |> String.replace("\t", "  ")
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.join("\n") ==
          "#{@dir}/#{file}.html"
          |> File.read!()
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.join("\n")
          |> String.trim()
      )
    end)
  end
end
