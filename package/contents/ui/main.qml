pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: kicker

    anchors.fill: parent

    signal reset
    signal modelRefreshed

    switchWidth: !fullRepresentationItem ? 0 : fullRepresentationItem.Layout.minimumWidth
    switchHeight: !fullRepresentationItem ? 0 : fullRepresentationItem.Layout.minimumHeight

    fullRepresentation: menuRepresentationComponent

    readonly property Component itemListDialogComponent: Component {
        ItemListDialog {}
    }

    property Item dragSource: null

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    Component {
        id: menuRepresentationComponent
        MenuRepresentation {
            rootModel: rootModel
            itemListDialogComponent: kicker.itemListDialogComponent
            onInteractionConcluded: kicker.expanded = false
        }
    }

    JsonMenuModel {
        id: rootModel

        jsonData: Plasmoid.configuration.menuJson || ""
        sorted: false
        executable: executable

        onRefreshed: {
            kicker.modelRefreshed();
        }
    }

    Connections {
        target: Plasmoid.configuration

        function onMenuJsonChanged() {
            rootModel.jsonData = Plasmoid.configuration.menuJson;
        }
    }

    Kicker.DragHelper {
        id: dragHelper

        dragIconSize: Kirigami.Units.iconSizes.medium
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName) => disconnectSource(sourceName)

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }

    Kicker.WindowSystem { // only for X11; TODO Plasma 6.8: remove (also from plasma-workspace)
        id: windowSystem
    }

    Connections {
        target: kicker

        function onExpandedChanged(expanded) {
            if (!expanded) {
                kicker.reset();
            }
        }
    }

    function resetDragSource() {
        dragSource = null;
    }

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true
        }

        rootModel.refreshed.connect(modelRefreshed);

        dragHelper.dropped.connect(resetDragSource);
    }
}

