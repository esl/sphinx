defmodule Sphinx.SlackArgs do
  alias Sphinx.SlackUtils

  @spec search_args(map()) :: map()
  def search_args(attrs \\ %{}) do
    channel_name =
      Map.get(attrs, :channel)
      |> SlackUtils.get_channel_name()

    query = "in:##{channel_name} " <> Map.get(attrs, :query)
    count = Map.get(attrs, :count, nil)
    highlight = Map.get(attrs, :highlight, nil)
    page = Map.get(attrs, :page, nil)
    sort = Map.get(attrs, :sort, nil)
    sort_dir = Map.get(attrs, :sort_dir, nil)
    pretty = Map.get(attrs, :pretty, 1)

    optional =
      clean_fields(%{
        count: count,
        highlight: highlight,
        page: page,
        sort: sort,
        sort_dir: sort_dir,
        pretty: pretty
      })

    Map.merge(%{query: query}, optional)
  end

  defp clean_fields(params) do
    params
    |> Enum.reject(fn {_k, v} -> v == nil end)
    |> Enum.into(%{})
  end
end
