// https://develop.kde.org/docs/plasma/widget/porting_kf6/#new-plasma5support-library

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmoidItem  {
  id: root
  
  property string icon: plasmoid.configuration.icon
  property var iconList: plasmoid.configuration.iconList
  property var labelList: plasmoid.configuration.labelList
  property var cmdList: plasmoid.configuration.cmdList
  property var separatorList: plasmoid.configuration.separatorList

  property string lineColor: '#1E000000'
  
  Plasmoid.icon: icon

  Plasma5Support.DataSource {
    id: executable
    engine: "executable"
    connectedSources: []
    onNewData: (sourceName) => disconnectSource(sourceName)

    function exec(cmd) {
      executable.connectSource(cmd)
    }
  }

  PlasmaExtras.Highlight {
    id: delegateHighlight
    visible: false
    hovered: true
    z: -1
  }

  fullRepresentation: Item {
    Layout.preferredWidth: plasmoid.configuration.width
    Layout.preferredHeight: plasmoid.configuration.height
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight
    
    ColumnLayout {
      id: columm
      anchors.fill: parent
      spacing: 0

      Repeater {
        model: labelList
        anchors.fill: parent

        ColumnLayout {
          ListDelegate {
            text: i18n(modelData)
            highlight: delegateHighlight
            icon: iconList[index]
            onClicked: executable.exec(cmdList[index])
          }

          MenuSeparator {
            Layout.topMargin: -3
            padding: 0
            contentItem: Rectangle {
              implicitWidth: plasmoid.configuration.width
              implicitHeight: 1.1
              color: lineColor
            }
            visible: separatorList[index] === 'true'
          }
        }
      }
    }
  }
}
