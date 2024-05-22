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

  property bool showAboutThisComputer: plasmoid.configuration.showAboutThisComputer
  property bool showSystemPreferences: plasmoid.configuration.showSystemPreferences
  property bool showAppStore: plasmoid.configuration.showAppStore
  property bool showForceQuit: plasmoid.configuration.showForceQuit
  property bool showSleep: plasmoid.configuration.showSleep
  property bool showHibernate: plasmoid.configuration.showHibernate
  property bool showRestart: plasmoid.configuration.showRestart
  property bool showShutdown: plasmoid.configuration.showShutdown
  property bool showLockScreen: plasmoid.configuration.showLockScreen
  property bool showLogout: plasmoid.configuration.showLogout
  
  property string icon: plasmoid.configuration.icon
  property string aboutThisComputer: plasmoid.configuration.aboutThisComputer
  property string systemPreferences: plasmoid.configuration.systemPreferences
  property string appStore: plasmoid.configuration.appStore
  property string forceQuit: plasmoid.configuration.forceQuit
  property string sleep: plasmoid.configuration.sleep
  property string restart: plasmoid.configuration.restart
  property string shutDown: plasmoid.configuration.shutDown
  property string lockScreen: plasmoid.configuration.lockScreen
  property string logOut: plasmoid.configuration.logOut

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

      ListDelegate {
        text: i18n("About This Computer")
        highlight: delegateHighlight
        icon: "help-hint"
        onClicked: executable.exec(aboutThisComputer)
        visible: showAboutThisComputer
      }

      MenuSeparator {
        padding: 0
        // topPadding: 5
        // bottomPadding: 5
        contentItem: Rectangle {
          implicitWidth: plasmoid.configuration.width
          implicitHeight: 1.1
          color: lineColor
        }
        visible: showAboutThisComputer
      }

      ListDelegate {
        text: i18n("System Preferences...")
        highlight: delegateHighlight
        icon: "settings-configure"
        onClicked: executable.exec(systemPreferences)
        visible: showSystemPreferences
      }

      ListDelegate {
        text: i18n("App Store...")
        highlight: delegateHighlight
        icon: "update-none"
        onClicked: executable.exec(appStore)
        visible: showAppStore
      }

      MenuSeparator {
        padding: 0
        contentItem: Rectangle {
          implicitWidth: plasmoid.configuration.width
          implicitHeight: 1.1
          color: lineColor
        }
        visible: showSystemPreferences || showAppStore
      }

      ListDelegate {
        text: i18n("Force Quit...")
        highlight: delegateHighlight
        icon: "error"
        onClicked: executable.exec(forceQuit)
        visible: showForceQuit
      }

      MenuSeparator {
        padding: 0
        contentItem: Rectangle {
          implicitWidth: plasmoid.configuration.width
          implicitHeight: 1.1
          color: lineColor
        }
        visible: showForceQuit
      }

      ListDelegate {
        text: i18n("Sleep")
        highlight: delegateHighlight
        icon: "system-suspend"
        onClicked: executable.exec(sleep)
        visible: showSleep
      }

      ListDelegate {
        text: i18n("Hibernate")
        highlight: delegateHighlight
        icon: "system-hibernate"
        onClicked: executable.exec(hibernate)
        visible: showHibernate
      }

      ListDelegate {
        text: i18n("Restart...")
        highlight: delegateHighlight
        icon: "system-reboot"
        onClicked: executable.exec(restart)
        visible: showRestart
      }

      ListDelegate {
        text: i18n("Shut Down...")
        highlight: delegateHighlight
        icon: "system-shutdown"
        onClicked: executable.exec(shutDown)
        visible: showShutdown
      }

      MenuSeparator {
        padding: 0
        contentItem: Rectangle {
          implicitWidth: plasmoid.configuration.width
          implicitHeight: 1.1
          color: lineColor
        }
        visible: showSleep || showHibernate || showRestart || showShutdown
      }

      ListDelegate {
        text: i18n("Lock Screen")
        highlight: delegateHighlight
        icon: "system-lock-screen"
        onClicked: executable.exec(lockScreen)
        visible: showLockScreen
      }

      ListDelegate {
        text: i18n("Log Out")
        highlight: delegateHighlight
        icon: "system-log-out"
        onClicked: executable.exec(logOut)
        visible: showLogout
      }
    }
  }
}
