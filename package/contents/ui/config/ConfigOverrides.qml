import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes // IconDialog

KCM.SimpleKCM {
  id: simpleKCM
  property alias cfg_iconList: iconRepeater.model
  property alias cfg_labelList: inputRepeater.model
  property alias cfg_cmdList: commandRepeater.model
  property alias cfg_separatorList: separatorRepeater.model

  property int focusedIndex: -1 // Store the index of the focused item
  
  Kirigami.FormLayout {
    id: formLayout
    width: parent.width

    Text {
      text: '* select checkbox to add menu separator'
      color: 'white'
      anchors.top: parent.top
      anchors.bottomMargin: 10
    }

    QQC2.Button {
      text: "Add Menu Item"
      Layout.fillWidth: true
      onClicked: {
        iconRepeater.model.push('');
        inputRepeater.model.push('');
        commandRepeater.model.push('');
        separatorRepeater.model.push('');
        simpleKCM.focusedIndex = inputRepeater.count - 1; // Set focus to the newly added item
      }
    }

    RowLayout {

      ColumnLayout {
        Repeater {
          id: separatorRepeater
          model: separatorList

          Rectangle {
            // height: separatorRepeater.model[index] === 'true' ? 42 : 32;
            height: 32;
            color: 'white'
            Layout.leftMargin: -25

            QQC2.CheckBox {
              id: menuSeparator
              anchors.top: parent.top
              anchors.topMargin: 5
              checked: modelData === 'true'
              onCheckedChanged: {
                separatorRepeater.model[index] = checked;
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.leftMargin: -5
        Repeater {
          id: iconRepeater
          model: iconRepeater.model

          ColumnLayout {
            QQC2.Button {
              icon.name: modelData
              onClicked: {
                dialogLoader.active = true
                dialogLoader.row = index
              }
            }

            // QQC2.MenuSeparator {
            //   visible: separatorRepeater.model[index] === 'true'
            //   contentItem: Rectangle {
            //     implicitWidth: parent.width
            //     implicitHeight: separatorRepeater.model[index] === 'true' ? 1 : 0;
            //     color: 'white'
            //   }
            // }
          }
        }
      }

      ColumnLayout {
        // Layout.leftMargin: -5
        Repeater {
          id: inputRepeater
          model: labelList

          ColumnLayout {
            QQC2.TextField {
              placeholderText: "Label"
              text: i18n(modelData)
              onTextChanged: {
                inputRepeater.model[index] = text;
              }
              onFocusChanged: {
                if (focus) {
                  simpleKCM.focusedIndex = index;
                }
              }
              focus: simpleKCM.focusedIndex === index; // Set focus explicitly
            }

            // QQC2.MenuSeparator {
            //   visible: separatorRepeater.model[index] === 'true'
            //   contentItem: Rectangle {
            //     implicitWidth: parent.width
            //     implicitHeight: 1
            //     color: 'white'
            //   }
            // }
          }
        }
      }
      
      ColumnLayout {
        Repeater {
          id: commandRepeater
          model: cmdList

          ColumnLayout {
            QQC2.TextField {
              placeholderText: "Command"
              text: i18n(modelData)
              onTextChanged: {
                commandRepeater.model[index] = text;
              }
              onFocusChanged: {
                if (focus) {
                  simpleKCM.focusedIndex = index;
                }
              }
              focus: simpleKCM.focusedIndex === index; // Set focus explicitly
            }

            // QQC2.MenuSeparator {
            //   visible: separatorRepeater.model[index] === 'true'
            //   contentItem: Rectangle {
            //     implicitWidth: parent.width
            //     implicitHeight: separatorRepeater.model[index] === 'true' ? 1 : -10;
            //     color: 'white'
            //   }
            // }
          }
        }
      }

      ColumnLayout {
        Repeater {
          id: deleteRepeater
          model: separatorRepeater.model

          ColumnLayout {
            QQC2.Button {
              icon.name: 'dialog-close'
              onClicked: {
                iconRepeater.model.splice(index, 1);
                inputRepeater.model.splice(index, 1);
                commandRepeater.model.splice(index, 1);
                separatorRepeater.model.splice(index, 1);
              }
            }

            // QQC2.MenuSeparator {
            //   visible: separatorRepeater.model[index] === 'true'
            //   contentItem: Rectangle {
            //     implicitWidth: parent.width
            //     implicitHeight: separatorRepeater.model[index] === 'true' ? 1 : 0;
            //     color: 'white'
            //   }
            // }
          }
        }
      }
    }
  }

  Loader {
    id: dialogLoader
    property int row
    active: false
    sourceComponent: KIconThemes.IconDialog {
      id: dialog
      visible: true
      modality: Qt.WindowModal
      onIconNameChanged: (iconName) => {
        iconRepeater.model[row] = iconName;
      }
      onVisibleChanged: {
        if (!visible) {
          dialogLoader.active = false
        }
      }
    }
  }
}
