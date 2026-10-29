// SPDX-License-Identifier: MIT
import QtQuick

Item {
  property string text: ""
  property string iconText: ""
  property color foreground: "white"
  property int iconSize: 14
  property string size: ""
  signal clicked()
  MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
}
