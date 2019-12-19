defmodule Sphinx.AnswersTest do
  use Sphinx.Support.DataCase

  alias Sphinx.Answers
  alias Sphinx.Riddles

  @question_params %{
    title: "title",
    permalink: "question_permalink",
    keywords: ["keyword", "key", "word"],
    enquirer: "A_USER"
  }

  @answer_params %{
    permalink: "answer_permalink",
    upvote: 1,
    solver: "B_USER"
  }

  describe "Answers.create/2" do
    test "works with correct params" do
      {:ok, riddle} = Riddles.create(@question_params)
      assert [] = Answers.all(riddle)
      assert {:ok, answer} = Answers.create(@answer_params, riddle)
      assert answer.permalink == @answer_params.permalink
      assert answer.upvote == @answer_params.upvote
      assert answer.upvote == @answer_params.upvote
    end

    test "fails with wrong params" do
      {:ok, riddle} = Riddles.create(@question_params)
      assert {:error, changeset} = Answers.create(Map.delete(@answer_params, :permalink), riddle)
      refute changeset.valid?
    end
  end

  describe "Answers.all/1" do
    test "returns all answers belong to a riddle" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, answer1} = Answers.create(@answer_params, riddle)
      {:ok, answer2} = Answers.create(%{@answer_params | permalink: "answer_permalink2"}, riddle)

      result = Answers.all(riddle)

      assert Enum.member?(result, answer1)
      assert Enum.member?(result, answer2)
    end
  end

  describe "Answers.get/1" do
    test "returns answers if exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, answer} = Answers.create(@answer_params, riddle)
      assert answer == Answers.get(%{permalink: @answer_params.permalink})
    end

    test "returns nil if no answer exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      assert [] == Answers.all(riddle)

      refute Answers.get(%{permalink: @answer_params.permalink})
    end

    test "returns nil if answer with specific parameter does not exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, _answer} = Answers.create(@answer_params, riddle)

      refute Answers.get(%{permalink: "some_link"})
    end
  end

  describe "Answer.delete/1" do
    test "deletes answer successfully if exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, answer} = Answers.create(@answer_params, riddle)
      assert [answer] == Answers.all(riddle)
      assert {:ok, deleted_answer} = Answers.delete(%{permalink: @answer_params.permalink})
      assert answer.id == deleted_answer.id
      assert [] = Answers.all(riddle)
    end

    test "returns error if no answer exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      assert [] = Answers.all(riddle)
      assert {:error, :not_found} == Answers.delete(%{permalink: @answer_params.permalink})
    end

    test "returns error if answer with specific parameter does not exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, _answer} = Answers.create(@answer_params, riddle)
      assert {:error, :not_found} == Answers.delete(%{permalink: "Some_link"})
    end
  end

  describe "Answers.update/1" do
    test "updates an answer if exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, answer} = Answers.create(@answer_params, riddle)

      new_params = %{@answer_params | upvote: 3}

      assert {:ok, updated_answer} = Answers.update(new_params)
      assert answer.id == updated_answer.id
      assert updated_answer.upvote == 3
    end

    test "does not update with wrong parameters" do
      {:ok, riddle} = Riddles.create(@question_params)
      {:ok, _answer} = Answers.create(@answer_params, riddle)

      new_params = %{@answer_params | upvote: "three"}

      assert {:error, changeset} = Answers.update(new_params)
      refute changeset.valid?
    end

    test "does not update when answer does not exists" do
      {:ok, riddle} = Riddles.create(@question_params)
      assert [] == Answers.all(riddle)
      assert {:error, :not_found} = Answers.update(@answer_params)
    end
  end
end
