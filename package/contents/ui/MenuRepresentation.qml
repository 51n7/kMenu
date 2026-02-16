pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/**
 * MenuRepresentation - Main UI component that displays the menu
 * 
 * This component is the primary visual representation of the menu. It:
 * 
 * 1. Wraps the menu in a ScrollView for scrolling when content exceeds available space
 * 2. Contains the main ItemListView that displays menu items from the JsonMenuModel
 * 3. Handles keyboard focus and navigation
 * 4. Manages hover blocking to prevent accidental hover activation when using keyboard
 * 5. Connects signals between the model and the view (interactionConcluded, reset, etc.)
 * 6. Handles layout and sizing constraints
 * 
 * Used in main.qml as the fullRepresentation component, which displays when the
 * plasmoid button is clicked. This is the main entry point for the menu UI.
 */
PlasmaComponents3.ScrollView {
    id: root

    required property var rootModel
    required property Component itemListDialogComponent

    signal interactionConcluded

    focus: true

    Layout.minimumWidth: Math.min(mainRow.width, mainRow.implicitWidth, Screen.width - Kirigami.Units.largeSpacing * 4)
    Layout.maximumWidth: Layout.minimumWidth

    contentWidth: mainRow.implicitWidth

    Layout.minimumHeight: rootList.implicitHeight
    Layout.maximumHeight: Layout.minimumHeight

    function reset() {
        rootList.currentIndex = -1;
        hoverBlock.reset();
    }

    RowLayout {
        id: mainRow

        anchors.fill: parent

        spacing: Kirigami.Units.smallSpacing

        LayoutMirroring.enabled: ((Plasmoid.location === PlasmaCore.Types.RightEdge)
            || (Application.layoutDirection === Qt.RightToLeft && Plasmoid.location !== PlasmaCore.Types.LeftEdge))

        ItemListView {
            id: rootList

            Layout.alignment: Qt.AlignTop
            Layout.fillHeight: true
            Layout.fillWidth: true
            menuWidth: Plasmoid.configuration.menuWidth || 0
            buttonHeight: Plasmoid.configuration.buttonHeight || 0

            visible: true

            iconsEnabled: Plasmoid.configuration.showIcons

            hoverEnabled: !hoverBlock.enabled

            itemListDialogComponent: root.itemListDialogComponent

            model: root.rootModel

            LayoutMirroring.enabled: mainRow.LayoutMirroring.enabled

            showSeparators: true // keep even if sorted, the one between recents and categories works

            onInteractionConcluded: root.interactionConcluded()

            Component.onCompleted: {
                rootList.exited.connect(root.reset);
            }
        }
    }

    Component.onCompleted: {
        kicker.modelRefreshed.connect(() => {
            root.reset()
        });
        kicker.reset.connect(reset)

        rootModel.refresh();

        // Give list focus when menu opens so keyboard navigation works without hovering first
        if (root.visible) {
            Qt.callLater(() => rootList.forceActiveFocus(Qt.PopupFocusReason));
        }
    }

    Connections {
        target: root
        function onVisibleChanged() {
            if (root.visible) {
                Qt.callLater(() => rootList.forceActiveFocus(Qt.PopupFocusReason));
            }
        }
    }

    MouseArea {
        id: hoverBlock  // don't hover-activate until mouse is moved to not interfere with keyboard use
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true // clicking should still work if hovering is blocked

        property bool mouseMoved: false

        function reset() {
            mouseMoved = false
            enabled = true
        }

        onPositionChanged: if (!mouseMoved) {
            mouseMoved = true
        } else {
            enabled = false // this immediately triggers other hover events when bound to their hoverEnabled
        }
    }
}
