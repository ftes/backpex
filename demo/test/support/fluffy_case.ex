defmodule DemoWeb.FluffyCase do
  @moduledoc """
  Shared sandbox and imports for incremental Fluffy browser migrations.

  Tests deliberately start their own sessions so BrowserContext options and
  lifecycle remain visible at each call site.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use DemoWeb, :verified_routes
      use Fluffy.Assert

      import Fluffy
      import Fluffy.Locator

      def start_browser_session(options \\ []) do
        defaults = [base_url: DemoWeb.Endpoint.url(), endpoint: DemoWeb.Endpoint]
        Fluffy.start_session(:playwright, Keyword.merge(defaults, options))
      end
    end
  end

  setup context do
    Fluffy.Test.setup(context)
  end
end
