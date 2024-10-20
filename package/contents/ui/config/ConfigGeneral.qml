import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kquickcontrolsaddons as KQuickAddons
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes // IconDialog
import org.kde.ksvg as KSvg

KCM.SimpleKCM {
  id: iconField
  
  property alias cfg_width: widthSpinBox.value
  property alias cfg_buttonHeight: buttonHeightSpinBox.value
  property alias cfg_icon: textField.text
  property alias value: textField.text
  property alias placeholderValue: textField.placeholderText
  property alias cfg_showIcons: showIcons.checked

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
    
    ColumnLayout {

      QQC2.Label {
        text: i18n('Toolbar Icon:')
      }

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
      Rectangle { Layout.bottomMargin: 20 }
    }

    RowLayout {
      QQC2.CheckBox {
        id: showIcons
        text: i18n('Show List Icons')
      }
    }

    RowLayout {
      spacing: 0
      Rectangle { Layout.bottomMargin: 20 }
    }

    RowLayout {
      Kirigami.FormData.label: i18n("Menu Width:")
      QQC2.SpinBox {
        id: widthSpinBox
        from: 0
        to: 2147483647 // 2^31-1
      }
    }

    RowLayout {
      Kirigami.FormData.label: i18n("Button Height:")
      QQC2.SpinBox {
        id: buttonHeightSpinBox
        from: 0
        to: 2147483647 // 2^31-1
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
