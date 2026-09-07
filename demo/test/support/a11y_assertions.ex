defmodule DemoWeb.A11yAssertions do
  @moduledoc """
  Provides a11y assertions.
  """
  defmacro __using__(_opts) do
    quote do
      import DemoWeb.A11yAssertions, only: [assert_a11y: 1]
    end
  end

  def assert_a11y(%{__struct__: Cerberus.Session} = session) do
    Cerberus.Playwright.evaluate(session, A11yAudit.JS.axe_core())
    json = Cerberus.Playwright.evaluate(session, "axe.run()")

    json
    |> A11yAudit.Results.from_json()
    |> A11yAudit.Assertions.assert_no_violations()

    session
  end
end
