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

  property bool showLogout: plasmoid.configuration.showLogout
  property bool showLockscreen: plasmoid.configuration.showLockscreen
  property bool showSuspend: plasmoid.configuration.showSuspend
  property bool showHibernate: plasmoid.configuration.showHibernate
  property bool showReboot: plasmoid.configuration.showReboot
  property bool showKexec: plasmoid.configuration.showKexec
  property bool showShutdown: plasmoid.configuration.showShutdown
  property string icon: plasmoid.configuration.icon

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
    // hovered: true
    z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
  }

  // function action_logOut() {
  //   executable.exec('qdbus org.kde.LogoutPrompt /LogoutPrompt  promptLogout')
  // }

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

      ListDelegate {
        id: logoutButton
        text: "Logout"
        highlight: delegateHighlight
        icon: "system-log-out"
        onClicked: executable.exec('qdbus org.kde.LogoutPrompt /LogoutPrompt promptLogout')
        visible: showLogout
      }

      ListDelegate {
        id: lockButton
        text: "Lock Screen"
        highlight: delegateHighlight
        icon: "system-lock-screen"
        onClicked: executable.exec('qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock')
        visible: showLockscreen
      }

      ListDelegate {
        id: suspendButton
        text: "Suspend"
        highlight: delegateHighlight
        icon: "system-suspend"
        onClicked: executable.exec('systemctl suspend')
        visible: showSuspend
      }

      ListDelegate {
        id: hibernateButton
        text: "Hibernate"
        highlight: delegateHighlight
        icon: "system-suspend-hibernate"
        onClicked: executable.exec('')
        visible: showHibernate
      }

      ListDelegate {
        id: rebootButton
        text: "Reboot"
        highlight: delegateHighlight
        icon: "system-reboot"
        onClicked: executable.exec('qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot')
        visible: showReboot
      }

      ListDelegate {
        id: kexecButton
        text: "Kexec Reboot"
        highlight: delegateHighlight
        icon: "system-reboot"
        // onClicked: executable.exec('')
        visible: showKexec
      }

      ListDelegate {
        id: shutdownButton
        text: "Shutdown"
        highlight: delegateHighlight
        icon: "system-shutdown"
        onClicked: executable.exec('qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown')
        visible: showShutdown
      }
    }
  }
}
