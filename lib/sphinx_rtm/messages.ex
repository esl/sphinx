defmodule SphinxRtm.Messages do
  alias SphinxRtm.Messages.Parser
  alias Sphinx.Riddles
  alias Sphinx.SlackUtils
  alias Sphinx.Answers

  ## TODO: check if message is a question
  ## if yes then get the keywords and search for old questions
  ## else check if it is related to/ answering the recent question.
  ## If yes, save the answer
  ## Else discard (something like that?)
  @spec process(map()) :: {:ok, Riddles.Riddle.t()} | {:error, Ecto.Changeset.t()}
  def process(message = %{thread_ts: _ts}) do
    save_reply(message)
    :no_reply
  end

  def process(message) do
    case Parser.mention_sphinx?(message.text) do
      true ->
        text = Parser.trim_mention(message.text)

        case Parser.check_content(text) do
          {:help, _} ->
            {:reply, help()}

          {:save, content} ->
            message
            |> Map.put(:text, content)
            |> save_question()

            {:ephemeral, "You're question is saved"}

          {:search, content} ->
            content = if content == "", do: text, else: content

            case SlackUtils.search(content, message.channel) do
              nil ->
                {:reply,
                 "You asked for \"#{content}\" but I have no answer! Invoke @sphinx [SAVE] [TEXT] to save the question for future use!"}

              reply ->
                {:reply,
                 "You asked for \"#{content}\", you might find these helpful: \n #{reply}"}
            end
        end

      false ->
        :no_reply
    end
  end

  def add_reaction(message) do
    permalink = permalink(message.item.channel, message.item.ts)

    case Answers.get(%{permalink: permalink}) do
      nil ->
        :ok

      answer ->
        upvote = answer.upvote
        Answers.update(%{permalink: permalink, upvote: upvote + 1})
    end
  end

  @spec save_question(map()) :: {:ok, Riddles.Riddle.t()} | {:error, Ecto.Changeset.t()}
  defp save_question(message) do
    %{}
    |> Map.put(:enquirer, user(message.user))
    |> Map.put(:title, message.text)
    |> Map.put(:permalink, permalink(message.channel, message.ts))
    |> Riddles.create()
  end

  @spec save_reply(map()) :: {:ok, Riddles.Riddle.t()} | {:error, Ecto.Changeset.t()} | :ok
  defp save_reply(message) do
    params = %{:permalink => get_thread_permalink(message.channel, message.thread_ts)}

    case Riddles.get(params) do
      # Ignore thread reply to not-saved messages
      nil ->
        :ok

      question ->
        %{}
        |> Map.put(:solver, user(message.user))
        |> Map.put(:permalink, permalink(message.channel, message.ts))
        |> Answers.create(question)
    end
  end

  defp user(user_id), do: SlackUtils.get_user_name(user_id)
  defp permalink(channel_id, ts), do: SlackUtils.get_permalink(channel_id, ts)

  defp get_thread_permalink(channel_id, ts) do
    permalink(channel_id, ts)
    |> String.replace(~r/[?](.)*/, "")
  end

  defp help do
    """
    ```
    @sphinx help Print Sphinx commands \n
    @sphinx [TEXT] Starts a thread with SphinxBot \n
    @sphinx [SAVE] [TEXT] It saves the link to the thread without title \n
    ...
    ```
    """
  end
end
