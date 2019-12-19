defmodule SphinxRtm do
  use Slack

  require Logger

  alias SphinxRtm.Messages
  alias Sphinx.SlackUtils

  def handle_connect(slack, state) do
    Logger.info("Connected as #{slack.me.name}")
    {:ok, state}
  end

  # Ignore event with subtype (delete, change...)
  def handle_event(%{type: "message", subtype: _some_event}, _slack, state) do
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    user = SlackUtils.get_user_name(message.user)
    Logger.info("Processing message from #{user}")

    case Messages.process(message) do
      {:reply, reply} ->
        send_thread_reply(reply, message, slack)
        {:ok, state}

      :no_reply ->
        {:ok, state}
    end
  end

  def handle_event(message = %{type: "reaction_added", reaction: "+1"}, _slack, state) do
    Logger.info("Thumbsup reaction received")
    Messages.add_reaction(message)
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    Logger.info("Sending the message to #{channel}")

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  def send_thread_reply(reply, received_message, slack) do
    %{
      type: "message",
      text: reply,
      channel: received_message.channel,
      thread_ts: received_message.ts
    }
    |> Poison.encode!()
    |> send_raw(slack)
  end
end
