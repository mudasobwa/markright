defmodule Markright.Fixtures.Test do
  use ExUnit.Case

  @dir "test/fixtures"

  @dir
  |> File.ls!
  |> Enum.filter(& String.ends_with?(&1, ".md"))
  |> Enum.each(fn file ->
       params = [squeeze: true, silent: true, file: Path.join(@dir, file)]
       # assert(String.replace(Markright.process(params), "\t", "  ") == File.read!("#{@dir}/#{file}.html"))
     end)
end
