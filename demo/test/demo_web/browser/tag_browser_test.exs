defmodule DemoWeb.Browser.TagBrowserTest do
  use DemoWeb.FluffyCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "tags index" do
    test "a11y" do
      insert_list(10, :tag)
      session = start_browser_session()

      session
      |> visit(~p"/admin/tags")
      |> assert_a11y()
    end
  end

  describe "tags show" do
    test "a11y" do
      tag = insert(:tag)
      session = start_browser_session()

      session
      |> visit(~p"/admin/tags/#{tag.id}/show")
      |> assert_a11y()
    end
  end

  describe "tags edit" do
    test "a11y" do
      tag = insert(:tag)
      session = start_browser_session()

      session
      |> visit(~p"/admin/tags/#{tag.id}/edit")
      |> assert_a11y()
    end
  end

  describe "tags new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/tags/new")
      |> assert_a11y()
    end
  end
end
