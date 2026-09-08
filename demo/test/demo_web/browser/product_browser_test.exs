defmodule DemoWeb.Browser.ProductBrowserTest do
  use DemoWeb.FluffyCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "products index" do
    test "a11y" do
      insert_list(10, :product)
      session = start_browser_session()

      session
      |> visit(~p"/admin/products")
      |> assert_a11y()
    end
  end

  describe "products show" do
    test "a11y" do
      product = insert(:product)
      session = start_browser_session()

      session
      |> visit(~p"/admin/products/#{product.id}/show")
      |> assert_a11y()
    end
  end

  describe "products edit" do
    test "a11y" do
      product = insert(:product)
      session = start_browser_session()

      session
      |> visit(~p"/admin/products/#{product.id}/edit")
      |> assert_a11y()
    end
  end

  describe "products new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/products/new")
      |> assert_a11y()
    end
  end
end
