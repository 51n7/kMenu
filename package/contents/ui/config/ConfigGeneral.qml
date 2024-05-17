import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kquickcontrolsaddons as KQuickAddons
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes // IconDialog
import org.kde.ksvg as KSvg

Item {
  id: iconField

  property alias cfg_showAboutThisComputer: showAboutThisComputer.checked
  property alias cfg_showSystemPreferences: showSystemPreferences.checked
  property alias cfg_showAppStore: showAppStore.checked
  property alias cfg_showForceQuit: showForceQuit.checked
  property alias cfg_showSleep: showSleep.checked
  property alias cfg_showRestart: showRestart.checked
  property alias cfg_showShutdown: showShutdown.checked
  property alias cfg_showLockScreen: showLockScreen.checked
  property alias cfg_showLogout: showLogout.checked
  property alias cfg_showIcons: showIcons.checked

  property alias cfg_width: widthSpinBox.value
  property alias cfg_height: heightSpinBox.value
  property alias cfg_icon: textField.text
  property alias value: textField.text
  property alias placeholderValue: textField.placeholderText

  property string configKey: ''
  property string defaultValue: 'start-here-kde'
  property int previewIconSize: Kirigami.Units.iconSizes.medium
  readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ""
  
  onConfigValueChanged: {
    if (!textField.focus && value != configValue) {
      value = configValue
    }
  }

  Kirigami.FormLayout {

    QQC2.Label {
      text: i18n('Toolbar Icon:')
    }

    RowLayout {
      QQC2.Button {
        id: iconButton
        padding: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignTop

        implicitWidth: leftPadding + contentItem.implicitWidth + rightPadding
        implicitHeight: topPadding + contentItem.implicitHeight + bottomPadding

        onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()
        
        contentItem: KSvg.FrameSvgItem {
          id: previewFrame
          imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
              ? "widgets/panel-background" : "widgets/background"
          implicitWidth: fixedMargins.left + previewIconSize + fixedMargins.right
          implicitHeight: fixedMargins.top + previewIconSize + fixedMargins.bottom

          Kirigami.Icon {
            anchors.fill: parent
            anchors.leftMargin: previewFrame.fixedMargins.left
            anchors.topMargin: previewFrame.fixedMargins.top
            anchors.rightMargin: previewFrame.fixedMargins.right
            anchors.bottomMargin: previewFrame.fixedMargins.bottom
            source: iconField.value || iconField.placeholderValue
            active: iconButton.hovered
          }
        }
      }

      QQC2.Menu {
        id: iconMenu
        y: +parent.height

        QQC2.MenuItem {
          text: i18n('Choose...')
          icon.name: "document-open"
          onClicked: dialogLoader.active = true
        }
        QQC2.MenuItem {
          text: i18n('Clear Icon...')
          icon.name: "edit-clear"
          onClicked: iconField.value = iconField.defaultValue
        }
      }

      QQC2.TextField {
        id: textField
        Layout.fillWidth: true
        visible: false

        text: iconField.configValue
        rightPadding: clearButton.width + Kirigami.Units.smallSpacing
        onTextChanged: serializeTimer.restart()

        QQC2.ToolButton {
          id: clearButton
          visible: iconField.configValue != iconField.defaultValue
          icon.name: iconField.defaultValue === "" ? "edit-clear" : "edit-undo"
          onClicked: iconField.value = iconField.defaultValue

          anchors.top: parent.top
          anchors.right: parent.right
          anchors.bottom: parent.bottom

          width: height
        }
      }
    }

    RowLayout {
      spacing: 0
      Rectangle { Layout.bottomMargin: 5 }
    }

    RowLayout {
      QQC2.CheckBox {
        id: showIcons
        text: i18n('Show List Icons')
      }
    }

    Column {
      QQC2.Label {
        text: i18n('Show Menu Items:')
      }
      QQC2.CheckBox {
        id: showAboutThisComputer
        text: i18n('About This Computer')
      }
      QQC2.CheckBox {
        id: showSystemPreferences
        text: i18n('System Preferences')
      }
      QQC2.CheckBox {
        id: showAppStore
        text: i18n('App Store')
      }
      QQC2.CheckBox {
        id: showForceQuit
        text: i18n('Force Quit')
      }
      QQC2.CheckBox {
        id: showSleep
        text: i18n('Sleep')
      }
      QQC2.CheckBox {
        id: showRestart
        text: i18n('Restart')
      }
      QQC2.CheckBox {
        id: showShutdown
        text: i18n('Shut Down')
      }
      QQC2.CheckBox {
        id: showLockScreen
        text: i18n('Lock Screen')
      }
      QQC2.CheckBox {
        id: showLogout
        text: i18n('Log Out')
      }
      
      Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
          Kirigami.FormData.label: i18n("Size:")
          QQC2.SpinBox {
            id: widthSpinBox
            from: 0
            to: 2147483647 // 2^31-1
          }
          QQC2.Label {
            text: " x "
          }
          QQC2.SpinBox {
            id: heightSpinBox
            from: 0
            to: 2147483647 // 2^31-1
          }
        }
      }
    }
  }

  Loader {
    id: dialogLoader
    active: false
    sourceComponent: KIconThemes.IconDialog {
      id: dialog
      visible: true
      modality: Qt.WindowModal
      onIconNameChanged: (iconName) => {
        iconField.value = iconName
      }
      onVisibleChanged: {
        if (!visible) {
          dialogLoader.active = false
        }
      }
    }
  }

  Timer { // throttle
    id: serializeTimer
    interval: 300
    onTriggered: {
      if (configKey) {
        plasmoid.configuration[configKey] = iconField.value
      }
    }
  }
}
