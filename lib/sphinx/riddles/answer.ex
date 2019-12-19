defmodule Sphinx.Answers.Answer do
  use Ecto.Schema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]
  @required [:permalink, :solver]
  @fields [:upvote] ++ @required

  schema "answers" do
    field(:permalink, :string)
    field(:upvote, :integer)
    field(:solver, :string)
    belongs_to(:riddle, Sphinx.Riddles.Riddle)

    timestamps()
  end

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @fields)
    |> validate_required(@required)
  end
end
