import QtQuick
import org.kde.plasma.configuration

ConfigModel {
  ConfigCategory {
    name: "General"
    icon: "configure"
    source: "config/ConfigGeneral.qml"
  }

  ConfigCategory {
    name: "Overrides"
    icon: "configure"
    source: "config/ConfigOverrides.qml"
  }
}
