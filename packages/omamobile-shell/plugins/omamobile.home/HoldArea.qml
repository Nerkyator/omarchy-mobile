// SPDX-License-Identifier: MIT
import QtQuick

// The MouseArea of an app tile or of a widget's tap target on the home. A
// click is the item's own; a hold of half a second, as long as the touch
// overlay's in Home.qml, asks for edit mode, and the release then clicks
// nothing (a connected onPressAndHold stops the click).
// A finger's hold already asks through the touch overlay, and a finger's
// press reaches a MouseArea synthesized from touch, so only a press that is
// not synthesized (a mouse or a touchpad) asks here: otherwise a touch hold
// would ask twice, and in landscape show the "turn the phone upright"
// notice twice. The event onPressAndHold gets always reads as synthesized,
// so the source is taken at the press.
// A press that moves past the drag distance is no hold, as on the overlay
// and the page's handler: its release clicks as it would without one.
MouseArea {
  // Home.qml's root, as every cell's content gets it.
  property var home: null
  property bool pressFromTouch: false
  property point pressAt
  property bool pressMoved: false

  pressAndHoldInterval: 500
  onPressed: function(mouse) {
    pressFromTouch = mouse.source !== Qt.MouseEventNotSynthesized
    pressAt = Qt.point(mouse.x, mouse.y)
    pressMoved = false
  }
  onPositionChanged: function(mouse) {
    var d = Qt.styleHints.startDragDistance
    if (Math.abs(mouse.x - pressAt.x) > d || Math.abs(mouse.y - pressAt.y) > d) pressMoved = true
  }
  onPressAndHold: function(mouse) {
    if (pressMoved) mouse.accepted = false
    else if (!pressFromTouch && home) home.requestEdit()
  }
}
