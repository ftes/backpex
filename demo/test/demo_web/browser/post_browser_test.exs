defmodule DemoWeb.Browser.PostBrowserTest do
  use DemoWeb.FluffyCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "posts index" do
    test "a11y" do
      insert_list(10, :post)
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> assert_a11y()
    end
  end

  describe "posts show" do
    test "a11y" do
      post = insert(:post)
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts/#{post.id}/show")
      |> assert_a11y()
    end
  end

  describe "posts edit" do
    test "a11y" do
      post = insert(:post)
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts/#{post.id}/edit")
      |> assert_a11y()
    end
  end

  describe "posts new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts/new")
      |> assert_a11y()
    end
  end
end
