defmodule Markright.Finalizers.Blockquote do
  @moduledoc ~S"""
  Finalizer for `blockquote` tag: makes last AST element fancy if it’s a link.
  """

  @behaviour Markright.Finalizer

  @spec finalize(Markright.Continuation.t) :: Markright.Continuation.t
  def finalize(%Markright.Continuation{ast: {:blockquote, bq_attrs, bq_ast}} = cont) when is_list(bq_ast) do
    case :lists.reverse(bq_ast) do
      [{:a, %{href: href} = attrs, text} | t] ->
        img = with [capture] <- Regex.run(~r|\Ahttps?://[^/]+|, href),
          do: {:img, %{alt: "favicon", src: capture <> "/favicon.png", style: "height:16px;margin-bottom:-2px;"}, nil}
        patched = :lists.reverse([{:br, %{}, nil}, "— ", img, " ", {:a, attrs, text}])
        %Markright.Continuation{cont | ast: {:blockquote, Map.put(bq_attrs, :cite, href), :lists.reverse(patched ++ t)}}
      _ -> cont
    end
  end

  def finalize(%Markright.Continuation{} = cont), do: cont

  ##############################################################################
end
