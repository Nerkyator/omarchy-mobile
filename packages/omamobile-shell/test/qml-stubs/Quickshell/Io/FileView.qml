// SPDX-License-Identifier: MIT
import QtQuick

// Every file reads as missing; nothing is written.
QtObject {
  property string path: ""
  property bool watchChanges: false
  property bool printErrors: true
  property bool blockLoading: false
  property bool blockWrites: false
  property bool atomicWrites: true
  property bool preload: true
  property bool loaded: false
  signal fileChanged()
  signal loaded()
  signal loadFailed(int error)
  signal saved()
  signal saveFailed(int error)
  function text() { return "" }
  function reload() {}
  function setText(t) {}
  function waitForJob() { return true }
  default property list<QtObject> data
}
