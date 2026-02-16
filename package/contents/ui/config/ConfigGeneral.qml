/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.draganddrop as DragDrop
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: configGeneral

    property string cfg_icon: plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage: plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage: plasmoid.configuration.customButtonImage

    property alias cfg_showIcons: showIcons.checked
    property alias cfg_menuWidth: menuWidthSpinBox.value
    property alias cfg_buttonHeight: buttonHeightSpinBox.value

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Icon:")

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2

            checkable: true
            checked: dropArea.containsAcceptableDrag

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            DragDrop.DropArea {
                id: dropArea

                property bool containsAcceptableDrag: false

                anchors.fill: parent

                onDragEnter: event => {
                    const urlString = event.mimeData.url.toString();
                    const extensions = [".png", ".xpm", ".svg", ".svgz"];
                    containsAcceptableDrag = urlString.startsWith("file:///")
                        && extensions.some(extension => urlString.endsWith(extension));

                    if (!containsAcceptableDrag) {
                        event.ignore();
                    }
                }
                onDragLeave: event => {
                    containsAcceptableDrag = false
                }

                onDrop: event => {
                    if (containsAcceptableDrag) {
                        iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                    }
                    containsAcceptableDrag = false;
                }
            }

            KIconThemes.IconDialog {
                id: iconDialog

                function setCustomButtonImage(image) {
                    configGeneral.cfg_customButtonImage = image || configGeneral.cfg_icon || "start-here-kde-symbolic"
                    configGeneral.cfg_useCustomButtonImage = true;
                }

                onIconNameChanged: (iconName) => {
                    if (iconName != "") {
                        setCustomButtonImage(iconName)
                    }
                }
            }

            KSvg.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: Kirigami.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: configGeneral.cfg_useCustomButtonImage ? configGeneral.cfg_customButtonImage : configGeneral.cfg_icon
                }
            }

            QQC2.Menu {
                id: iconMenu

                y: parent.height

                onClosed: iconButton.checked = false;

                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                    icon.name: "edit-clear"
                    onClicked: {
                        configGeneral.cfg_icon = "start-here-kde-symbolic"
                        configGeneral.cfg_customButtonImage = ""
                        configGeneral.cfg_useCustomButtonImage = false
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showIcons

            Kirigami.FormData.label: i18n("General:")
            text: i18n("Show icons in the menu")
        }

        RowLayout {
            spacing: 0
            Rectangle { Layout.bottomMargin: 20 }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Menu Width:")
            QQC2.SpinBox {
                id: menuWidthSpinBox
                from: 0
                // INT_MAX (2^31-1): max value for config Int type; effectively no upper limit for width
                to: 2147483647
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Button Height:")
            QQC2.SpinBox {
                id: buttonHeightSpinBox
                from: 0
                // INT_MAX (2^31-1): max value for config Int type; effectively no upper limit
                to: 2147483647
            }
        }
    }
}
