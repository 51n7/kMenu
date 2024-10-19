import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes // IconDialog

KCM.SimpleKCM {
  id: simpleKCM
  property var cfg_iconList: cfg_iconList
  property var cfg_labelList: cfg_labelList
  property var cfg_cmdList: cfg_cmdList
  property var cfg_separatorList: cfg_separatorList

  function addMenuItem(icon, label, command, separator) {

    listView.model.append({
      icon: icon,
      label: label,
      command: command,
      separator: separator
    });
    
    cfg_iconList.push(icon);
    cfg_labelList.push(label);
    cfg_cmdList.push(command);
    cfg_separatorList.push(separator);
    
    simpleKCM.cfg_iconList = cfg_iconList;
    simpleKCM.cfg_labelList = cfg_labelList;
    simpleKCM.cfg_cmdList = cfg_cmdList;
    simpleKCM.cfg_separatorList = cfg_separatorList;
  }

  Component.onCompleted: {
    listView.model.clear();
    for (let i = 0; i < cfg_labelList.length; i++) {
      listView.model.append({
        icon: cfg_iconList[i],
        label: cfg_labelList[i],
        command: cfg_cmdList[i],
        separator: cfg_separatorList[i]
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

      RowLayout {
        QQC2.Button {
          text: "Add Menu Item"
          Layout.fillWidth: true
          onClicked: {
            addMenuItem('', '', '', 'false');
          }
        }

        QQC2.Button {
          text: "Add Separator"
          Layout.fillWidth: true
          onClicked: {
            addMenuItem('filename-dash-amarok', 'separator', 'separator', 'true');
          }
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

            MouseArea {
              id: dragArea
              property bool held: false

              anchors {
                left: parent?.left
                right: parent?.right
              }
              height: content.height
              width: content.width

              /* TO CLICK AND DRAG FULL ROW UNCOMMENT THIS */

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

                color: "transparent" // dragArea.held ? "lightblue" : "lightgray"
                height: parent.parent.height
                width: listView.width

                RowLayout {
                  anchors.fill: parent

                  QQC2.Button {
                    id: handle
                    icon.name: model.separator === 'false' ? 'labplot-transform-move' : ''
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: model.separator === 'true'
                    flat: model.separator === 'true'
                    hoverEnabled: model.separator === 'false'

                    QQC2.Button {
                      width: parent.width
                      height: 2
                      hoverEnabled: false
                      anchors.verticalCenter: parent.verticalCenter
                      visible: model.separator === 'true'
                    }

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
                    icon.name: model.icon
                    Layout.alignment: Qt.AlignVCenter
                    visible: model.separator === 'false'
                    onClicked: {
                      dialogLoader.active = true
                      dialogLoader.row = index
                    }
                  }

                  QQC2.CheckBox {
                    id: menuSeparator
                    visible: false
                    checked: model.separator === 'true'
                    onCheckedChanged: {
                      if (String(checked) !== model.separator) {
                        listView.model.setProperty(index, "separator", String(checked));
                        cfg_separatorList[index] = String(checked);
                        simpleKCM.cfg_separatorList = cfg_separatorList;
                      }
                    }
                  }

                  QQC2.TextField {
                    placeholderText: 'label'
                    text: model.label
                    implicitHeight: handle.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    visible: model.separator === 'false'
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
                    visible: model.separator === 'false'
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
                    onClicked: {
                      cfg_iconList.splice(index, 1);
                      cfg_labelList.splice(index, 1);
                      cfg_cmdList.splice(index, 1);
                      cfg_separatorList.splice(index, 1);
                      
                      listView.model.remove(index);
                      
                      simpleKCM.cfg_iconList = cfg_iconList;
                      simpleKCM.cfg_labelList = cfg_labelList;
                      simpleKCM.cfg_cmdList = cfg_cmdList;
                      simpleKCM.cfg_separatorList = cfg_separatorList;
                    }
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

                  // swap items in arrays
                  [cfg_iconList[sourceIndex], cfg_iconList[targetIndex]] = [cfg_iconList[targetIndex], cfg_iconList[sourceIndex]];
                  [cfg_labelList[sourceIndex], cfg_labelList[targetIndex]] = [cfg_labelList[targetIndex], cfg_labelList[sourceIndex]];
                  [cfg_cmdList[sourceIndex], cfg_cmdList[targetIndex]] = [cfg_cmdList[targetIndex], cfg_cmdList[sourceIndex]];
                  [cfg_separatorList[sourceIndex], cfg_separatorList[targetIndex]] = [cfg_separatorList[targetIndex], cfg_separatorList[sourceIndex]];

                  // save updated arrays
                  simpleKCM.cfg_iconList = cfg_iconList;
                  simpleKCM.cfg_labelList = cfg_labelList;
                  simpleKCM.cfg_cmdList = cfg_cmdList;
                  simpleKCM.cfg_separatorList = cfg_separatorList;
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
        listView.model.setProperty(row, "icon", iconName);
        cfg_iconList[row] = iconName;
        simpleKCM.cfg_iconList = cfg_iconList;
      }
      onVisibleChanged: {
        if (!visible) {
          dialogLoader.active = false
        }
      }
    }
  }
}
