defmodule SphinxRtm do
  use Slack

  alias SphinxRtm.Messages

  def handle_connect(slack, state) do
    IO.puts("Connected as #{slack.me.name}")
    {:ok, state}
  end

  # Ignore event with subtype (delete, change...)
  def handle_event(%{type: "message", subtype: _some_event}, _slack, state) do
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, _slack, state) do
    Messages.process(message)
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts("Sending your message, captain!")

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}
end
