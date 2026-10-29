// SPDX-License-Identifier: MIT
import QtQuick

// Omarchy's application library: names, no icons.
QtObject {
  property var entries: []
  function iconSource(icon) { return "" }
  function entryName(e) { return e ? String(e.name || e.id || "") : "" }
  function beginLaunchFeedback(name) {}
}
