defmodule DemoWeb.Browser.SidebarBrowserTest do
  use DemoWeb.CerberusCase, async: false
  use DemoWeb.A11yAssertions

  import Demo.EctoFactory

  @moduletag :playwright

  # LiveView freezes the session at websocket-connect time, so a re-mount
  # after live_redirect inside the same live_session reads a stale cookie
  # and re-renders the sidebar (and its sections) from the default. The
  # hook keeps the user's most recent toggle in sessionStorage and
  # re-asserts it over the stale server render; these tests cover that.

  @blog_toggle ~s|[data-section-id="blog"] [data-menu-dropdown-toggle]|
  @sidebar_toggle ~s|#backpex-sidebar-toggle|

  @install_preference_gate """
  () => {
    const originalFetch = window.fetch.bind(window)
    const gate = { active: 0, calls: [], maxActive: 0 }
    window.__backpexPreferenceGate = gate

    window.fetch = (input, options = {}) => {
      const url = typeof input === 'string' ? input : input.url
      if (!url.includes('backpex_preferences')) return originalFetch(input, options)

      let release
      const blocked = new Promise((resolve) => { release = resolve })
      const call = { body: JSON.parse(options.body), release }
      gate.calls.push(call)
      gate.active += 1
      gate.maxActive = Math.max(gate.maxActive, gate.active)

      return blocked
        .then(() => originalFetch(input, options))
        .finally(() => { gate.active -= 1 })
    }

    return true
  }
  """

  @await_preference_calls """
  async (count) => {
    for (let index = 0; index < 100; index++) {
      const gate = window.__backpexPreferenceGate
      if (gate.calls.length >= count) {
        return {
          active: gate.active,
          calls: gate.calls.map(({ body }) => body),
          maxActive: gate.maxActive
        }
      }
      await new Promise((resolve) => setTimeout(resolve, 50))
    }

    throw new Error(`Timed out waiting for ${count} preference request(s)`)
  }
  """

  @preference_gate_state """
  () => {
    const gate = window.__backpexPreferenceGate
    return {
      active: gate.active,
      calls: gate.calls.map(({ body }) => body),
      maxActive: gate.maxActive
    }
  }
  """

  @release_preference_call """
  (index) => {
    window.__backpexPreferenceGate.calls[index].release()
    return true
  }
  """

  @await_preference_gate_settled """
  async () => {
    for (let index = 0; index < 100; index++) {
      const gate = window.__backpexPreferenceGate
      if (gate.active === 0 && !document.cookie.includes('backpex_prefs')) {
        return { active: gate.active, maxActive: gate.maxActive }
      }
      await new Promise((resolve) => setTimeout(resolve, 50))
    }

    throw new Error('Timed out waiting for preference writes to settle')
  }
  """

  @select_theme """
  (theme) => {
    document.querySelector(`input[name="theme-selector"][value="${theme}"]`).click()
    return document.documentElement.dataset.theme
  }
  """

  @clear_preference_mirrors """
  () => {
    Object.keys(sessionStorage)
      .filter((key) => key.startsWith('backpex.prefs.'))
      .forEach((key) => sessionStorage.removeItem(key))
    return true
  }
  """

  describe "sidebar section state across live_redirect" do
    test "collapsed section stays collapsed after navigating to a sibling LiveResource" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|#{@blog_toggle}[aria-expanded="true"]|) |> Expect.count(1))
      |> assert_a11y()
      |> click(by_css(@blog_toggle))
      |> expect(by_css(~s|#{@blog_toggle}[aria-expanded="false"]|) |> Expect.count(1))
      |> assert_a11y()
      |> click(by_css(~s|a[href="/admin/invoices"]|))
      |> expect(Expect.url("/admin/invoices"))
      |> expect(by_css(~s|#{@blog_toggle}[aria-expanded="false"]|) |> Expect.count(1))
    end
  end

  describe "sidebar open/closed state across live_redirect" do
    # Collapsed sidebar becomes `inert`, so a user-simulated click on a
    # sidebar link can't reach it. Fire a programmatic click via
    # `HTMLElement.click()` — it bubbles through LiveView's delegated
    # click handler and still triggers the live_redirect.
    test "collapsed sidebar stays collapsed after navigating to a sibling LiveResource" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="true"]|) |> Expect.count(1))
      |> assert_a11y()
      |> click(by_css(@sidebar_toggle))
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="false"]|) |> Expect.count(1))
      |> assert_a11y()
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, ~s|document.querySelector('a[href="/admin/invoices"]').click()|)
        session
      end)
      |> expect(Expect.url("/admin/invoices"))
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="false"]|) |> Expect.count(1))
    end
  end

  describe "empty sidebar sections" do
    test "CSS hides empty nested sections and reveals them when an item appears" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> then(fn session ->
        display =
          Cerberus.Playwright.evaluate(
            session,
            """
            (() => {
              const parent = document.createElement('li')
              parent.id = 'empty-section-parent'
              parent.className = 'not-has-[[data-sidebar-item]]:hidden'
              parent.innerHTML = `
                <ul>
                  <li id="empty-section-child" class="not-has-[[data-sidebar-item]]:hidden">
                    <ul id="empty-section-content"></ul>
                  </li>
                </ul>
              `
              document.querySelector('#backpex-sidebar').appendChild(parent)

              return {
                parent: getComputedStyle(parent).display,
                child: getComputedStyle(parent.querySelector('#empty-section-child')).display
              }
            })()
            """
          )

        assert display == %{"child" => "none", "parent" => "none"}
        session
      end)
      |> then(fn session ->
        display =
          Cerberus.Playwright.evaluate(
            session,
            """
            (() => {
              const item = document.createElement('li')
              item.dataset.sidebarItem = ''
              document.querySelector('#empty-section-content').appendChild(item)

              return {
                parent: getComputedStyle(document.querySelector('#empty-section-parent')).display,
                child: getComputedStyle(document.querySelector('#empty-section-child')).display
              }
            })()
            """
          )

        refute display["parent"] == "none"
        refute display["child"] == "none"
        session
      end)
    end
  end

  describe "preference write ordering" do
    test "serializes sibling Session preferences changed during an active request" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @install_preference_gate, is_function: true)
        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(
          session,
          ~s|document.querySelector('[data-section-id="blog"] [data-menu-dropdown-toggle]').click()|
        )

        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 1
          )

        assert gate["active"] == 1
        assert gate["maxActive"] == 1

        assert body_entries(List.first(gate["calls"])) == [
                 %{"key" => "global.sidebar_section.blog", "value" => false}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, ~s|document.querySelector('#backpex-sidebar-toggle').click()|)
        session
      end)
      |> then(fn session ->
        gate = Cerberus.Playwright.evaluate(session, @preference_gate_state, is_function: true)

        assert gate["active"] == 1
        assert gate["maxActive"] == 1
        assert length(gate["calls"]) == 1

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 0)
        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 2
          )

        assert gate["active"] == 1
        assert gate["maxActive"] == 1

        assert body_entries(Enum.at(gate["calls"], 1)) == [
                 %{"key" => "global.sidebar_open", "value" => false}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 1)
        session
      end)
      |> then(fn session ->
        gate = Cerberus.Playwright.evaluate(session, @await_preference_gate_settled, is_function: true)
        assert gate == %{"active" => 0, "maxActive" => 1}

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @clear_preference_mirrors, is_function: true)
        session
      end)
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|#backpex-app-shell[data-sidebar-open="false"]|) |> Expect.count(1))
      |> expect(by_css(~s|[data-section-id="blog"][data-section-open="false"]|) |> Expect.count(1))
    end

    test "persists the latest intent when the same key changes during a request" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @install_preference_gate, is_function: true)
        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @select_theme, is_function: true, arg: "dark")
        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 1
          )

        assert gate["active"] == 1

        assert body_entries(List.first(gate["calls"])) == [
                 %{"key" => "global.theme", "value" => "dark"}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @select_theme, is_function: true, arg: "cupcake")
        session
      end)
      |> then(fn session ->
        gate = Cerberus.Playwright.evaluate(session, @preference_gate_state, is_function: true)

        assert gate["active"] == 1
        assert gate["maxActive"] == 1
        assert length(gate["calls"]) == 1

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 0)
        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 2
          )

        assert gate["active"] == 1
        assert gate["maxActive"] == 1

        assert body_entries(Enum.at(gate["calls"], 1)) == [
                 %{"key" => "global.theme", "value" => "cupcake"}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 1)
        session
      end)
      |> then(fn session ->
        gate = Cerberus.Playwright.evaluate(session, @await_preference_gate_settled, is_function: true)
        assert gate == %{"active" => 0, "maxActive" => 1}

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @clear_preference_mirrors, is_function: true)
        session
      end)
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|html[data-theme="cupcake"]|) |> Expect.count(1))
      |> then(fn session ->
        checked? =
          Cerberus.Playwright.evaluate(
            session,
            ~s|document.querySelector('input[name="theme-selector"][value="cupcake"]').checked|
          )

        assert checked?

        session
      end)
    end
  end

  describe "preference batch rejection" do
    setup do
      prior = Application.get_env(:backpex, Backpex.Preferences)

      Application.put_env(:backpex, Backpex.Preferences,
        adapters: [{:default, DemoWeb.SelectivelyRejectingSessionPreferencesAdapter, []}]
      )

      on_exit(fn ->
        case prior do
          nil -> Application.delete_env(:backpex, Backpex.Preferences)
          value -> Application.put_env(:backpex, Backpex.Preferences, value)
        end
      end)
    end

    test "retries unaffected Session writes after the first rejected entry" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @install_preference_gate, is_function: true)
        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(
          session,
          """
          () => {
            document.querySelector('input[name="theme-selector"][value="dark"]').click()
            document.querySelector('#backpex-sidebar-toggle').click()
            document.querySelector('[data-section-id="blog"] [data-menu-dropdown-toggle]').click()
            return true
          }
          """,
          is_function: true
        )

        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 1
          )

        assert gate["active"] == 1

        assert body_entries(List.first(gate["calls"])) == [
                 %{"key" => "global.theme", "value" => "dark"},
                 %{"key" => "global.sidebar_open", "value" => false},
                 %{"key" => "global.sidebar_section.blog", "value" => false}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 0)
        session
      end)
      |> then(fn session ->
        gate =
          Cerberus.Playwright.evaluate(session, @await_preference_calls,
            is_function: true,
            arg: 2
          )

        assert gate["active"] == 1
        assert gate["maxActive"] == 1

        assert body_entries(Enum.at(gate["calls"], 1)) == [
                 %{"key" => "global.theme", "value" => "dark"},
                 %{"key" => "global.sidebar_section.blog", "value" => false}
               ]

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @release_preference_call, is_function: true, arg: 1)
        session
      end)
      |> then(fn session ->
        gate = Cerberus.Playwright.evaluate(session, @await_preference_gate_settled, is_function: true)
        assert gate == %{"active" => 0, "maxActive" => 1}

        session
      end)
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @clear_preference_mirrors, is_function: true)
        session
      end)
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|html[data-theme="dark"]|) |> Expect.count(1))
      |> expect(by_css(~s|#backpex-app-shell[data-sidebar-open="true"]|) |> Expect.count(1))
      |> expect(by_css(~s|[data-section-id="blog"][data-section-open="false"]|) |> Expect.count(1))
    end
  end

  describe "quick reload inside the persist race window" do
    # The bug, reproduced deterministically. The preferences POST is stalled so
    # the server NEVER sees the toggle: the session cookie stays "sidebar open"
    # for the whole test. That is exactly the state a real browser is in for the
    # ~1.1s between the click and the POST's Set-Cookie, and any reload landing
    # in that window used to paint the OLD sidebar and then flip.
    #
    # Everything the fix has to do is therefore observable here:
    #   1. the toggle is recorded in the `backpex_prefs` cookie synchronously;
    #   2. a document GET made in that state already renders the CLOSED sidebar
    #      (assertion (b) — the literal bytes the browser paints first, which is
    #      what the flash is, and it is not subject to paint-timing flakiness);
    #   3. after the reload the page STAYS closed instead of being stomped back
    #      open by the hook's once-cached `desktopOpen` (aggravating factor B);
    #   4. once the POST is allowed through, the pending entry retires and the
    #      cookie disappears, so it can never become a second store.

    # Stall the preferences POST only. Every other request (including the
    # document fetch below) goes through the original `fetch`, which we stash on
    # `window` so the test can still make one.
    @stall_preferences """
    () => {
      window.__originalFetch = window.fetch.bind(window)
      window.fetch = (input, opts) => {
        const url = typeof input === 'string' ? input : input.url
        if (url.includes('backpex_preferences')) return new Promise(() => {})
        return window.__originalFetch(input, opts)
      }
      return true
    }
    """

    # The bytes a hard reload would paint, fetched in the state the click left
    # the browser in: stale session cookie + fresh `backpex_prefs` cookie.
    @fetch_dead_render """
    async () => {
      const response = await window.__originalFetch(location.href, { cache: 'no-store' })
      return await response.text()
    }
    """

    # `replayPending()` re-POSTs the write on the next page load; the response
    # retires the entry. Poll rather than sleep so the test does not encode the
    # round-trip time.
    @await_cookie_retired """
    async () => {
      for (let i = 0; i < 50; i++) {
        if (!document.cookie.includes('backpex_prefs')) return 'retired'
        await new Promise((resolve) => setTimeout(resolve, 100))
      }
      return document.cookie
    }
    """

    test "a reload before the preferences POST lands renders the collapsed sidebar" do
      session = start_browser_session()

      session
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="true"]|) |> Expect.count(1))
      |> then(fn session ->
        Cerberus.Playwright.evaluate(session, @stall_preferences, is_function: true)
        session
      end)
      |> click(by_css(@sidebar_toggle))
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="false"]|) |> Expect.count(1))
      # (a) The write is in the cookie, synchronously, before any round trip.
      |> then(fn session ->
        cookie = Cerberus.Playwright.evaluate(session, "document.cookie")
        entry = cookie |> String.split("; ") |> Enum.find(&String.starts_with?(&1, "backpex_prefs="))
        assert is_binary(entry)

        envelope = entry |> String.split("=", parts: 2) |> List.last() |> URI.decode() |> Jason.decode!()
        assert envelope["version"] == 1
        assert get_in(envelope, ["values", "global.sidebar_open", "value"]) == false
        assert is_binary(get_in(envelope, ["values", "global.sidebar_open", "token"]))
        session
      end)
      # (b) THE FLASH ITSELF: the document the browser would paint first.
      |> then(fn session ->
        html = Cerberus.Playwright.evaluate(session, @fetch_dead_render, is_function: true)

        assert html =~ ~s(data-sidebar-open="false")
        refute html =~ ~s(data-sidebar-open="true")
        refute html =~ "lg:translate-x-0"
        session
      end)
      # A full document GET — same cookies, same dead render, now actually
      # painted. The stalled `fetch` stub dies with the old document, so the
      # reloaded page replays the pending write for real.
      |> visit(~p"/admin/posts")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      # (c) It lands closed and STAYS closed. Before the fix the hook re-asserted
      # its mount-time `desktopOpen` through the higher-specificity
      # `data-[state]` classes and the page ended up open.
      |> expect(by_css(~s|#{@sidebar_toggle}[aria-expanded="false"]|) |> Expect.count(1))
      |> expect(by_css(~s|#backpex-sidebar[data-state="closed"]|) |> Expect.count(1))
      |> expect(by_css(~s|#backpex-main[data-shift="off"]|) |> Expect.count(1))
      |> assert_a11y()
      # (d) The pending entry retires on the replay's response: the cookie holds
      # unacknowledged writes only and cannot shadow the adapter.
      |> then(fn session ->
        result = Cerberus.Playwright.evaluate(session, @await_cookie_retired, is_function: true)
        assert result == "retired"
        session
      end)
      # The mirror survives — it is the live_redirect carrier and has a
      # different job.
      |> then(fn session ->
        value =
          Cerberus.Playwright.evaluate(
            session,
            """
            (() => {
              const manifest = JSON.parse(document.getElementById('backpex-preferences').dataset.preferencesManifest)
              return sessionStorage.getItem(`backpex.prefs.${manifest.routes[0].token}.global.sidebar_open`)
            })()
            """
          )

        assert value == "false"
        session
      end)
    end
  end

  describe "the sidebar transition guard" do
    # `data-suppress-transition` is static markup, so morphdom morphs it back on
    # any patch that re-renders the shell. Only mounted() used to take it off,
    # so the first sort left the sidebar unable to animate for the rest of the
    # page load. live_redirect hides this — it replaces the nodes and re-mounts
    # the hook; the in-place patch is the path that strands the guard.
    test "a live_patch does not strand the transition guard" do
      insert_list(3, :address)
      session = start_browser_session()

      session
      |> visit(~p"/admin/addresses")
      |> expect(by_css("body .phx-connected") |> Expect.count(1))
      |> expect(by_css(~s|#backpex-sidebar:not([data-suppress-transition])|) |> Expect.count(1))
      # Sorting re-renders the shell in place, without re-mounting the hook.
      |> click(by_css(~s|thead a[href*="order_by=street"]|))
      |> expect(by_css(~s|#backpex-sidebar:not([data-suppress-transition])|) |> Expect.count(1))
      |> expect(by_css(~s|#backpex-main:not([data-suppress-transition])|) |> Expect.count(1))
    end
  end

  defp body_entries(%{"preferences" => entries}), do: entries
  defp body_entries(%{"key" => key, "value" => value}), do: [%{"key" => key, "value" => value}]
end
