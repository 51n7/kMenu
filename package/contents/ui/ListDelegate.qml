import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
  id: item

  signal clicked
  signal iconClicked

  property alias text: label.text
  property alias icon: icon.source
  property bool interactive: true
  property bool interactiveIcon: false

  property alias containsMouse: area.containsMouse

  property Item highlight

  Layout.fillWidth: true

  height: row.height

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: item.interactive
    hoverEnabled: true
    onClicked: item.clicked()
    onContainsMouseChanged: {
      if (!highlight) {
        return
      }

      if (containsMouse) {
        highlight.parent = item
        highlight.width = item.width
        highlight.height = item.height
      }

      highlight.visible = containsMouse
    }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    width: parent.width - Kirigami.Units.smallSpacing
    spacing: Kirigami.Units.smallSpacing

    Kirigami.Icon {
      id: icon
      Layout.minimumWidth: 1.6 * Kirigami.Units.iconSizes.small
      Layout.maximumWidth: 1.6 * Kirigami.Units.iconSizes.small
      Layout.minimumHeight: 1.6 * Kirigami.Units.iconSizes.small
      Layout.maximumHeight: 1.6 * Kirigami.Units.iconSizes.small

      MouseArea {
        anchors.fill: parent
        visible: item.interactiveIcon
        cursorShape: Qt.PointingHandCursor
        onClicked: item.iconClicked()
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      PlasmaComponents.Label {
        id: label
        Layout.fillWidth: true
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
      }

      PlasmaComponents.Label {
        id: sublabel
        Layout.fillWidth: true
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        opacity: 0.6
        font: Kirigami.Theme.smallFont
        visible: text !== ""
      }
    }
  }
}
 
