defmodule DemoWeb.CerberusCase do
  @moduledoc """
  Shared sandbox and imports for incremental Cerberus browser migrations.

  Tests deliberately start their own sessions so BrowserContext options and
  lifecycle remain visible at each call site.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use DemoWeb, :verified_routes

      import Cerberus
      import Cerberus.Locator

      alias Cerberus.Expect

      def start_browser_session(options \\ []) do
        defaults = [base_url: DemoWeb.Endpoint.url(), endpoint: DemoWeb.Endpoint]
        Cerberus.start_session(:playwright, Keyword.merge(defaults, options))
      end
    end
  end

  setup context do
    Cerberus.Test.setup(context)
  end
end
