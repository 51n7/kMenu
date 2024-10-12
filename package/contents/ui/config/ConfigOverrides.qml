import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes // IconDialog

KCM.SimpleKCM {
  id: simpleKCM
  // property alias cfg_iconList: iconRepeater.model
  property var cfg_labelList: cfg_labelList
  property var cfg_cmdList: cfg_cmdList
  // property alias cfg_separatorList: separatorRepeater.model

  Component.onCompleted: {
    listView.model.clear();
    for (let i = 0; i < cfg_labelList.length; i++) {
      listView.model.append({
        label: cfg_labelList[i],
        command: cfg_cmdList[i]
      });
    }
  }
  
  Kirigami.FormLayout {
    id: formLayout
    width: parent.width
    height: parent.height
    
    ColumnLayout {
      Layout.fillWidth: true
      height: parent.height
      anchors.fill: parent

      Text {
        text: '* select checkbox to add menu separator'
        color: 'white'
        Layout.alignment: Qt.AlignTop
        anchors.bottomMargin: 10
      }

      QQC2.Button {
        text: "Add Menu Item"
        Layout.fillWidth: true
        onClicked: {
          print(cfg_labelList)
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        color: "transparent"

        ListView {
          id: listView
          anchors.fill: parent
          spacing: 2
          model: ListModel {}

          delegate: Item {
            width: listView.width
            height: 40
            // anchors.topMargin: 15

            MouseArea {
              id: dragArea
              property bool held: false

              anchors {
                left: parent?.left
                right: parent?.right
              }
              height: content.height
              width: content.width

              /*TO DRAG FULL ROW UNCOMMENT THIS*/

              // drag.target: held ? content : undefined
              // drag.axis: Drag.YAxis

              // onPressed: {
              //   held = true;
              //   parent.z = 999;
              // }

              // onReleased: {
              //   held = false;
              //   parent.z = 1;
              //   content.y = 0
              // }

              Rectangle {
                id: content
                Drag.active: dragArea.held
                Drag.source: dragArea
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                // color: dragArea.held ? "lightblue" : "lightgray"
                color: "transparent"
                height: parent.parent.height
                width: listView.width

                RowLayout {
                  anchors.fill: parent

                  QQC2.Button {
                    id: handle
                    icon.name: 'drag-handle-symbolic'
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                      id: dragHandle
                      anchors.fill: parent
                      cursorShape: Qt.OpenHandCursor
                      drag.target: content
                      drag.axis: Drag.YAxis
                      onPressed: {
                        dragArea.held = true;
                        dragArea.parent.z = 999;
                      }
                      onReleased: {
                        dragArea.held = false;
                        dragArea.parent.z = 1;
                        content.y = 0
                      }
                    }
                  }
                  QQC2.Button {
                    icon.name: 'arrow-left'
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                      print(handle.height)
                    }
                  }
                  QQC2.TextField {
                    placeholderText: 'label'
                    text: model.label
                    implicitHeight: handle.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    onTextChanged: {
                      if (text !== model.label) {
                        listView.model.setProperty(index, "label", text);
                        cfg_labelList[index] = text;
                        simpleKCM.cfg_labelList = cfg_labelList;
                      }
                    }
                  }
                  QQC2.TextField {
                    placeholderText: 'command'
                    text: model.command
                    implicitHeight: handle.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    onTextChanged: {
                      if (text !== model.command) {
                        listView.model.setProperty(index, "command", text);
                        cfg_cmdList[index] = text;
                        simpleKCM.cfg_cmdList = cfg_cmdList;
                      }
                    }
                  }
                  QQC2.Button {
                    icon.name: 'dialog-close'
                    Layout.alignment: Qt.AlignVCenter
                  }
                }

                Behavior on y {
                  NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                  }
                }
              }

              DropArea {
                anchors {
                  fill: parent
                  margins: 10
                }

                onEntered: (drag) => {
                  let sourceIndex = drag.source.DelegateModel.itemsIndex;
                  let targetIndex = dragArea.DelegateModel.itemsIndex;

                  listView.model.move(sourceIndex, targetIndex, 1);
                }
              }
            }
          }

          interactive: true // determines whether the user can interact with the ListView to scroll its contents.
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
