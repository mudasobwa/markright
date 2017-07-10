defmodule Markright.Parsers.Youtube do
  @moduledoc ~S"""
  Parses the input for the youtube video.

  ## Examples

      iex> input = "✇https://www.youtube.com/watch?v=noQcPIeW6tE&size=5"
      iex> Markright.Parsers.Youtube.to_ast(input)
      %Markright.Continuation{ast: {:iframe,
             %{allowfullscreen: nil, frameborder: 0, height: 315,
               src: "http://www.youtube.com/embed/noQcPIeW6tE", width: 560},
             "http://www.youtube.com/embed/noQcPIeW6tE"},
            bag: [tags: [], parser: Markright.Parsers.Generic],
            fun: nil, tail: ""}

      iex> "✇http://www.youtube.com/embed/noQcPIeW6tE"
      ...> |> Markright.to_ast()
      ...> |> XmlBuilder.generate()
      "<article>\n\t<p>\n\t\t<iframe allowfullscreen=\"\" frameborder=\"0\" height=\"315\" src=\"http://www.youtube.com/embed/noQcPIeW6tE\" width=\"560\">http://www.youtube.com/embed/noQcPIeW6tE</iframe>\n\t</p>\n</article>"
  """

  use Markright.Continuation
  use Markright.Helpers.Magnet

  def to_ast(input, %Plume{} = plume \\ %Plume{}) when is_binary(input) do
    %Plume{ast: <<@magnet :: binary, url :: binary>>} = cont = astify(input, plume)
    url = code(url)
    iframe = {:iframe, %{width: 560, height: 315, src: url, frameborder: 0, allowfullscreen: nil}}
    Markright.Utils.continuation(:continuation, %Plume{cont | ast: url}, iframe)
  end

  defp youtubify(code), do: "http://www.youtube.com/embed/#{code}"
  (1..24) |> Enum.each(fn i ->
    defp code(<<"http://youtu.be/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"http://youtu.be/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/v/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/v/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/embed/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/embed/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/watch?v=" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"http://www.youtube.com/watch?v=" :: binary, code :: binary-size(unquote(i)), "&" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"https://youtu.be/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"https://youtu.be/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/v/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/v/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/embed/" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/embed/" :: binary, code :: binary-size(unquote(i)), "?" :: binary, _ :: binary>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/watch?v=" :: binary, code :: binary-size(unquote(i))>>), do: youtubify(code)
    defp code(<<"https://www.youtube.com/watch?v=" :: binary, code :: binary-size(unquote(i)), "&" :: binary, _ :: binary>>), do: youtubify(code)
  end)
  defp code(code), do: code
end
