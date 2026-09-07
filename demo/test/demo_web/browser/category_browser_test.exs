defmodule DemoWeb.Browser.CategoryBrowserTest do
  use DemoWeb.CerberusCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "categories index" do
    test "a11y" do
      insert_list(10, :category)
      session = start_browser_session()

      session
      |> visit(~p"/admin/categories")
      |> assert_a11y()
    end
  end

  describe "categories show" do
    test "a11y" do
      category = insert(:category)
      session = start_browser_session()

      session
      |> visit(~p"/admin/categories/#{category.id}/show")
      |> assert_a11y()
    end
  end

  describe "categories edit" do
    test "a11y" do
      category = insert(:category)
      session = start_browser_session()

      session
      |> visit(~p"/admin/categories/#{category.id}/edit")
      |> assert_a11y()
    end
  end

  describe "categories new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/categories/new")
      |> assert_a11y()
    end
  end
end
