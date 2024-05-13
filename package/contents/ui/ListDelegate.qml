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
  property alias containsMouse: area.containsMouse
  property bool showIcons: plasmoid.configuration.showIcons
  property Item highlight

  Layout.fillWidth: true
  height: row.height

  MouseArea {
    id: area
    anchors.fill: parent
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
      visible: showIcons
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      PlasmaComponents.Label {
        id: label
        Layout.fillWidth: true
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        // padding: showIcons ? 0 : 5
        topPadding: showIcons ? 0 : 5
        rightPadding: showIcons ? 0 : 7
        bottomPadding: showIcons ? 0 : 5
        leftPadding: showIcons ? 0 : 7
      }
    }
  }
}
 
