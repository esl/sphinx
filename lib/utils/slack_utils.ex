defmodule Sphinx.SlackUtils do
  use Slack
  alias Slack.Web.Channels
  alias Slack.Web.Chat
  alias Slack.Web.Users
  alias Slack.Web.Reactions
  alias Sphinx.SlackArgs

  require Logger

  @user_token Application.get_env(:slack, :user_token)
  @slack_url Application.get_env(:slack, :slack_url)

  @spec get_channel_name(String.t()) :: String.t()
  def get_channel_name(channel_id) do
    Channels.info(channel_id)
    |> get_in(["channel", "name"])
  end

  @spec get_permalink(String.t(), String.t()) :: String.t()
  def get_permalink(channel_id, ts) do
    Chat.get_permalink(channel_id, ts)
    |> Map.get("permalink")
  end

  @spec get_user_name(String.t()) :: String.t()
  def get_user_name(user) do
    user
    |> Users.info()
    |> get_in(["user", "name"])
  end

  @spec search(String.t(), String.t()) :: map() | nil
  def search(text, channel) do
    params = SlackArgs.search_args(%{query: text, channel: channel})
    url = build_url("search.messages", params)
    {:ok, response} = HTTPoison.get(url)
    {:ok, %{"messages" => %{"matches" => list_of_matches}}} = Poison.decode(response.body)

    case list_of_matches do
      [] ->
        nil

      _ ->
        build_response(list_of_matches, text, channel)
    end
  end

  @spec send_ephemeral_reply(String.t(), String.t(), String.t()) :: map()
  def send_ephemeral_reply(channel, text, user) do
    Chat.post_ephemeral(channel, text, user)
  end

  defp build_response(matches, _text, channel) do
    blocks =
      Enum.filter(matches, &match?(%{"channel" => %{"id" => ^channel}, "text" => text}, &1))
      |> Enum.sort_by(&get_upvote_count(&1), &>=/2)

    build_text("", 1, blocks)
  end

  defp get_upvote_count(block) do
    channel = get_in(block, ["channel", "id"])
    message = Reactions.get(%{channel: channel, timestamp: block["ts"]})

    case get_in(message, ["message", "reactions"]) do
      nil ->
        0

      reactions ->
        case Enum.find(reactions, fn map -> map["name"] == "+1" end) do
          nil -> 0
          upvote -> upvote["count"]
        end
    end
  end

  defp build_text("", _, []), do: nil
  defp build_text(response, _, []), do: response

  defp build_text(response, count, [block | blocks]) do
    conc = Integer.to_string(count) <> " ~> #{block["permalink"]} \n "
    build_text(response <> conc, count + 1, blocks)
  end

  defp build_url(path, params) do
    url = "#{@slack_url}#{path}?token=#{@user_token}"

    optional =
      for {k, v} <- params do
        "" <> "&#{k}=#{v}"
      end

    Enum.join([url] ++ optional, "")
    |> URI.encode()
  end
end
