// SPDX-License-Identifier: MIT
import QtQuick

// Never runs anything.
QtObject {
  property var command: []
  property bool running: false
  property var environment: ({})
  property string workingDirectory: ""
  property var stdout: null
  property var stderr: null
  property bool stdinEnabled: false
  signal exited(int exitCode, int exitStatus)
  signal started()
  function write(s) {}
  function signal(n) {}
  default property list<QtObject> data
}
