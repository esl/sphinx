defmodule SphinxRtm.Messages.Parser do
  use Slack
  alias Sphinx.SlackUtils

  @spec mention_sphinx?(String.t()) :: boolean()
  def mention_sphinx?(text) do
    with true <- String.match?(text, ~r/^[<@](.)*[>]/) do
      [mention_id | _content] = String.split(text, ["<@", ">"], trim: true)
      is_sphinx_id?(mention_id)
    else
      false -> false
    end
  end

  @spec is_sphinx_id?(String.t()) :: boolean()
  defp is_sphinx_id?(id) do
    user_name = SlackUtils.get_user_name(id)
    String.contains?(user_name, ["sphinx"])
  end

  @spec trim_mention(String.t()) :: String.t()
  def trim_mention(text), do: String.replace(text, ~r/[<@](.)*[>]\s/, "")

  @spec check_content(String.t()) :: {atom(), String.t()}
  def check_content(text) do
    [tag | content] = String.split(text, " ", trim: true)
    tag = String.downcase(tag)

    cond do
      tag =~ ~r/help/ -> {:help, ""}
      tag =~ ~r/save/ -> {:save, Enum.join(content, " ")}
      tag =~ ~r/search/ -> {:search, Enum.join(content, " ")}
      true -> {:search, text}
    end
  end

  def build_text("", _, []), do: nil
  def build_text(response, _, []), do: response

  def build_text(response, count, [block | blocks]) do
    conc = Integer.to_string(count) <> " ~> #{block.permalink} \n "
    build_text(response <> conc, count + 1, blocks)
  end
end
