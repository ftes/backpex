defmodule DemoWeb.Browser.InvoiceBrowserTest do
  use DemoWeb.CerberusCase, async: true
  use DemoWeb.A11yAssertions

  @moduletag :playwright

  describe "invoices index" do
    test "a11y" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/invoices")
      |> assert_a11y()
    end
  end
end
