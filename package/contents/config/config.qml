import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
         name: i18n("General")
         icon: "preferences-desktop-plasma"
         source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
         name: i18n("Edit Menu")
         icon: "application-menu"
         source: "config/ConfigMenuJson.qml"
    }
    ConfigCategory {
         name: i18n("Edit JSON")
         icon: "code-context"
         source: "config/ConfigEditJson.qml"
    }
}

