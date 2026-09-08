defmodule DemoWeb.Browser.UserBrowserTest do
  use DemoWeb.FluffyCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "users index" do
    test "a11y" do
      insert_list(10, :user)
      session = start_browser_session()

      session
      |> visit(~p"/admin/users")
      |> assert_a11y()
    end
  end

  describe "users show" do
    test "a11y" do
      user = insert(:user)
      session = start_browser_session()

      session
      |> visit(~p"/admin/users/#{user.id}/show")
      |> assert_a11y()
    end
  end

  describe "users edit" do
    test "a11y" do
      user = insert(:user)
      session = start_browser_session()

      session
      |> visit(~p"/admin/users/#{user.id}/edit")
      |> assert_a11y()
    end
  end

  describe "users new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/users/new")
      |> assert_a11y()
    end
  end
end
