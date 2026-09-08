defmodule DemoWeb.Browser.FilmReviewBrowserTest do
  use DemoWeb.FluffyCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "film-reviews index" do
    test "a11y" do
      insert_list(10, :film_review)
      session = start_browser_session()

      session
      |> visit(~p"/admin/film-reviews")
      |> assert_a11y()
    end
  end

  describe "film-reviews show" do
    test "a11y" do
      film_review = insert(:film_review)
      session = start_browser_session()

      session
      |> visit(~p"/admin/film-reviews/#{film_review.id}/show")
      |> assert_a11y()
    end
  end

  describe "film-reviews edit" do
    test "a11y" do
      film_review = insert(:film_review)
      session = start_browser_session()

      session
      |> visit(~p"/admin/film-reviews/#{film_review.id}/edit")
      |> assert_a11y()
    end
  end

  describe "film-reviews new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/film-reviews/new")
      |> assert_a11y()
    end
  end
end
