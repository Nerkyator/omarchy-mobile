// SPDX-License-Identifier: MIT
// The home screen under a mouse and under touch (#147): a click or a tap
// opens an app or taps a widget (an OWL one too), a hold of either kind
// enters edit mode once and opens nothing, a slow press that drifts is no
// hold, and both kinds swipe pages. Run by test/home-touch, which copies the
// plugin to ./home.
import QtQuick
import QtTest
import Quickshell
import "home" as H
import "home/owl/catalog.js" as OwlCatalog

Item {
  id: top
  width: 1040
  height: 1040

  // The phone's screen: 480x1040 upright, 1040x480 on its side.
  Item {
    id: screen
    width: 480
    height: 1040
    H.Home { id: home; anchors.fill: parent }
  }

  // Every notice the home shows, cleared at once so the same text twice
  // counts twice.
  property var notices: []
  Connections {
    target: home
    function onNoticeChanged() {
      if (!home.notice) return
      top.notices = top.notices.concat([home.notice])
      home.notice = ""
    }
  }

  TestCase {
    id: test
    name: "HomeTouch"
    when: windowShown

    function find(item, pred) {
      if (pred(item)) return item
      for (var i = 0; i < item.children.length; i++) {
        var found = find(item.children[i], pred)
        if (found) return found
      }
      return null
    }
    function tile(app) { return find(home, function(i) { return i.missing !== undefined && !!i.entry && i.entry.app === app }) }
    function notes() { return find(home, function(i) { return i.missing === undefined && i.home !== undefined && !!i.entry && i.entry.type === "notes" }) }
    function pager() { return find(home, function(i) { return i.snapMode !== undefined && i.orientation === ListView.Horizontal }) }
    function launches(app) {
      return Quickshell.executed.filter(function(argv) { return argv[0] === "omamobile-launch" && argv[2] === app }).length
    }
    readonly property string owlType: "owl:simonschubert.analog-clock"
    function owlCell() { return find(home, function(i) { return i.widgetId === test.owlType && i.running !== undefined }) }
    // The OWL widget's tap count (its state n).
    function owlTaps() {
      var w = find(owlCell(), function(i) { return typeof i.stateValue === "function" && typeof i.runHandler === "function" })
      return w.stateValue("n")
    }
    // Turning the screen rebuilds the cells, and the widget starts again.
    function owlReady() {
      tryVerify(function() { var c = owlCell(); return !!c && c.running && owlTaps() !== undefined }, 3000, "the OWL widget runs")
      wait(100)
    }
    function centre(item) { return item.mapToItem(top, item.width / 2, item.height / 2) }
    // A free grid cell on page 1: the fourth column, the fifth row.
    function empty() { var p = pager(); return p.mapToItem(top, p.width * 7 / 8, p.height * 9 / 12) }

    function touchHold(p, ms) {
      var t = touchEvent(top)
      t.press(0, top, p.x, p.y).commit()
      wait(ms)
      t.release(0, top, p.x, p.y).commit()
    }
    function mouseHold(p, ms) {
      mousePress(top, p.x, p.y)
      wait(ms)
      mouseRelease(top, p.x, p.y)
    }
    function touchTap(p) {
      var t = touchEvent(top)
      t.press(0, top, p.x, p.y).commit()
      t.release(0, top, p.x, p.y).commit()
    }
    function settle() { wait(100) }

    function initTestCase() {
      DesktopEntries.entries = {
        foot: { id: "foot", name: "Terminal", icon: "foot" },
        files: { id: "files", name: "Files", icon: "files" },
      }
      // An OWL widget that counts its taps, in a built-in's place: its text
      // goes straight into the home's cache with an approval that grants
      // nothing, so no store file is read.
      var owlText = 'widget "t" {\n  state n = 0\n  onTap: n = n + 1\n  Text { text: "tap ${n}" }\n}'
      var info = OwlCatalog.describe(test.owlType, owlText, { columns: 4, rows: 6 }, 160, 1)
      info.text = owlText
      var cache = {}
      cache[test.owlType] = info
      home.owlBuiltinCache = cache
      var approvals = {}
      approvals[test.owlType] = { commands: [], devices: [] }
      home.owlApprovals = approvals
      home.loadText(JSON.stringify({ version: 1, grid: { columns: 4, rows: 6 }, home: 0, nextId: 6, pages: [
        { items: [{ id: "a1", kind: "app", app: "foot", x: 0, y: 0, w: 1, h: 1 },
                  { id: "w2", kind: "widget", type: "notes", x: 0, y: 2, w: 2, h: 2, config: { text: "hi" } },
                  { id: "w5", kind: "widget", type: test.owlType, x: 2, y: 0, w: 2, h: 2, config: { owlState: {} } }] },
        { items: [{ id: "a3", kind: "app", app: "files", x: 0, y: 0, w: 1, h: 1 }] }] }))
      tryVerify(function() { return tile("foot") !== null && notes() !== null && owlCell() !== null && pager() !== null },
                3000, "the app, the note, the OWL widget and the pager")
      owlReady()
      compare(owlTaps(), 0, "the OWL widget's state")
    }

    function init() {
      screen.width = 480
      screen.height = 1040
      tryVerify(function() { return !home.landscape }, 2000, "upright")
      home.setEditing(false)
      home.sheet = ""
      home.goToPage(0, false)
      tryCompare(pager(), "currentIndex", 0)
      tryVerify(function() { return !pager().moving }, 2000, "the pager at rest")
      Quickshell.executed = []
      top.notices = []
    }

    function test_01_a_mouse_click_opens_an_app() {
      var p = centre(tile("foot"))
      mouseClick(top, p.x, p.y)
      settle()
      compare(launches("foot"), 1, "one launch")
      verify(!home.editing)
    }

    function test_02_a_tap_opens_an_app() {
      touchTap(centre(tile("foot")))
      settle()
      compare(launches("foot"), 1, "one launch")
      verify(!home.editing)
    }

    function test_03_a_mouse_hold_on_an_app_edits_and_opens_nothing() {
      mouseHold(centre(tile("foot")), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(launches("foot"), 0, "no launch after the hold")
    }

    function test_04_a_touch_hold_on_an_app_edits_and_opens_nothing() {
      touchHold(centre(tile("foot")), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(launches("foot"), 0, "no launch after the hold")
    }

    function test_05_a_mouse_hold_on_empty_space_edits() {
      mouseHold(empty(), 800)
      settle()
      verify(home.editing, "edit mode")
    }

    function test_06_a_touch_hold_on_empty_space_edits() {
      touchHold(empty(), 800)
      settle()
      verify(home.editing, "edit mode")
    }

    function test_07_a_mouse_click_on_empty_space_does_nothing() {
      var p = empty()
      mouseClick(top, p.x, p.y)
      wait(700)
      verify(!home.editing, "no edit mode")
      compare(Quickshell.executed.length, 0, "nothing run")
    }

    function test_08_a_mouse_click_taps_a_widget() {
      var p = centre(notes())
      mouseClick(top, p.x, p.y)
      settle()
      compare(home.sheet, "settings", "the note's settings")
      compare(home.settingsId, "w2")
    }

    function test_09_a_mouse_hold_on_a_widget_edits_and_taps_nothing() {
      mouseHold(centre(notes()), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(home.sheet, "", "no settings after the hold")
    }

    function test_10_a_touch_hold_on_a_widget_edits_and_taps_nothing() {
      touchHold(centre(notes()), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(home.sheet, "", "no settings after the hold")
    }

    function test_11_a_mouse_drag_from_an_app_changes_page_and_opens_nothing() {
      var p = centre(tile("foot"))
      mousePress(top, p.x, p.y)
      for (var s = 1; s <= 10; s++) {
        wait(16)
        mouseMove(top, p.x - 30 * s, p.y)
      }
      mouseRelease(top, p.x - 300, p.y)
      tryCompare(home, "currentPage", 1, 2000, "page 2")
      settle()
      compare(launches("foot"), 0, "no launch")
      verify(!home.editing)
    }

    function test_12_a_touch_swipe_from_an_app_changes_page_and_opens_nothing() {
      var p = centre(tile("foot"))
      var t = touchEvent(top)
      t.press(0, top, p.x, p.y).commit()
      for (var s = 1; s <= 10; s++) {
        wait(16)
        t.move(0, top, p.x - 30 * s, p.y).commit()
      }
      t.release(0, top, p.x - 300, p.y).commit()
      tryCompare(home, "currentPage", 1, 2000, "page 2")
      settle()
      compare(launches("foot"), 0, "no launch")
      verify(!home.editing)
    }

    function test_13_a_mouse_click_on_empty_space_leaves_edit_mode() {
      home.setEditing(true)
      settle()
      var p = empty()
      mouseClick(top, p.x, p.y)
      tryCompare(home, "editing", false, 1000)
    }

    // On its side the home can't be edited: a hold says so, once, whatever
    // asked (the touch overlay, or the tile for a mouse), and opens nothing.
    function sideways() {
      screen.width = 1040
      screen.height = 480
      tryVerify(function() { return home.landscape }, 2000, "on its side")
      waitForRendering(top)
    }

    function test_14_on_its_side_a_touch_hold_on_an_app_asks_once() {
      sideways()
      touchHold(centre(tile("foot")), 800)
      settle()
      compare(top.notices, ["Turn the phone upright to edit"], "one notice")
      verify(!home.editing)
      compare(launches("foot"), 0, "no launch after the hold")
    }

    function test_15_on_its_side_a_mouse_hold_on_an_app_asks_once() {
      sideways()
      mouseHold(centre(tile("foot")), 800)
      settle()
      compare(top.notices, ["Turn the phone upright to edit"], "one notice")
      verify(!home.editing)
      compare(launches("foot"), 0, "no launch after the hold")
    }

    function test_16_on_its_side_a_touch_hold_on_a_widget_asks_once() {
      sideways()
      touchHold(centre(notes()), 800)
      settle()
      compare(top.notices, ["Turn the phone upright to edit"], "one notice")
      compare(home.sheet, "", "no settings after the hold")
    }

    // A slow press that moves past the drag distance is no hold, for the
    // overlay or for the tile, so its release is a tap or a click as before.
    function test_17_a_slow_tap_that_drifts_still_opens_the_app() {
      var p = centre(tile("foot"))
      var t = touchEvent(top)
      t.press(0, top, p.x, p.y).commit()
      for (var s = 1; s <= 6; s++) {
        wait(130)
        t.move(0, top, p.x, p.y + 5 * s).commit()
      }
      wait(50)
      t.release(0, top, p.x, p.y + 30).commit()
      settle()
      verify(!home.editing, "no edit mode")
      compare(launches("foot"), 1, "one launch")
    }

    function test_18_a_slow_click_that_drifts_still_opens_the_app() {
      var p = centre(tile("foot"))
      mousePress(top, p.x, p.y)
      for (var s = 1; s <= 8; s++) {
        wait(100)
        mouseMove(top, p.x, p.y + 3 * s)
      }
      mouseRelease(top, p.x, p.y + 24)
      settle()
      verify(!home.editing, "no edit mode")
      compare(launches("foot"), 1, "one launch")
    }

    function test_19_a_mouse_click_taps_an_owl_widget() {
      owlReady()
      var n = owlTaps()
      var p = centre(owlCell())
      mouseClick(top, p.x, p.y)
      settle()
      compare(owlTaps(), n + 1, "one onTap")
      verify(!home.editing)
    }

    function test_20_a_mouse_hold_on_an_owl_widget_edits_and_taps_nothing() {
      owlReady()
      var n = owlTaps()
      mouseHold(centre(owlCell()), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(owlTaps(), n, "no onTap after the hold")
    }

    function test_21_a_touch_hold_on_an_owl_widget_edits_and_taps_nothing() {
      owlReady()
      var n = owlTaps()
      touchHold(centre(owlCell()), 800)
      settle()
      verify(home.editing, "edit mode")
      compare(owlTaps(), n, "no onTap after the hold")
    }

    function test_22_on_its_side_a_touch_hold_on_an_owl_widget_asks_once() {
      sideways()
      owlReady()
      var n = owlTaps()
      touchHold(centre(owlCell()), 800)
      settle()
      compare(top.notices, ["Turn the phone upright to edit"], "one notice")
      compare(owlTaps(), n, "no onTap after the hold")
    }

    function test_23_on_its_side_a_mouse_hold_on_an_owl_widget_asks_once() {
      sideways()
      owlReady()
      var n = owlTaps()
      mouseHold(centre(owlCell()), 800)
      settle()
      compare(top.notices, ["Turn the phone upright to edit"], "one notice")
      compare(owlTaps(), n, "no onTap after the hold")
    }
  }
}
