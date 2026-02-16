/*
    SPDX-FileCopyrightText: 2024

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configEditJson

    property string cfg_menuJson: plasmoid.configuration.menuJson || "[]"

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        QQC2.Label {
            text: i18n("Edit the menu structure as JSON. Each item can have: name, icon, command, submenu (array of items), or separator (true).")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        QQC2.TextArea {
            id: jsonField
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: configEditJson.cfg_menuJson
            placeholderText: "[]"
            wrapMode: TextArea.NoWrap
            selectByMouse: true
            font.family: "monospace"

            onTextChanged: {
                if (text !== configEditJson.cfg_menuJson) {
                    configEditJson.cfg_menuJson = text;
                }
            }
        }
    }
}
