defmodule DemoWeb.Browser.AddressBrowserTest do
  use DemoWeb.CerberusCase, async: true
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  describe "addresses index" do
    test "a11y" do
      insert_list(10, :address)
      session = start_browser_session()

      session
      |> visit(~p"/admin/addresses")
      |> assert_a11y()
    end
  end

  describe "addresses show" do
    test "a11y" do
      address = insert(:address)
      session = start_browser_session()

      session
      |> visit(~p"/admin/addresses/#{address.id}/show")
      |> assert_a11y()
    end
  end

  describe "addresses edit" do
    test "a11y" do
      address = insert(:address)
      session = start_browser_session()

      session
      |> visit(~p"/admin/addresses/#{address.id}/edit")
      |> assert_a11y()
    end
  end

  describe "addresses new" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/addresses/new")
      |> assert_a11y()
    end
  end
end
