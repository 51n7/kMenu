pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker

/**
 * ItemListDialog - Component that creates submenus (nested menus) for items with children
 * 
 * This component is used to display nested submenus when a menu item has children.
 * It:
 * 
 * 1. Wraps an ItemListView in a Kicker.SubMenu to create a floating submenu dialog
 * 2. Handles the model for nested menu items via FunnelModel
 * 3. Manages submenu positioning and layout mirroring (RTL support)
 * 4. Propagates interaction signals (interactionConcluded) to close the entire menu
 * 5. Handles window deactivation to close submenus when clicking outside
 * 6. Maintains a reference to the parent ItemListView for signal propagation
 * 
 * Used in ItemListView.qml via the itemListDialogComponent property. When a menu
 * item with children is hovered or selected, ItemListView creates an instance of
 * this component to display the submenu. Without this component, nested menus
 * would not work.
 */
Kicker.SubMenu {
    id: itemDialog

    property alias model: funnelModel.sourceModel
    property Component itemListDialogComponent: null

    property int index: -1
    property bool aboutToBeDestroyed: false
    property ItemListView parentItemListView: null

    property alias mainSearchField: itemListView.mainSearchField

    signal interactionConcluded

    visible: true
    location: PlasmaCore.Types.Floating
    offset: Kirigami.Units.smallSpacing
    LayoutMirroring.enabled: dialogMirrored

    onInteractionConcluded: itemDialog.interactionConcluded()
    onWindowDeactivated: {
        if (!aboutToBeDestroyed) {
            interactionConcluded()
        }
    }

    mainItem: ItemListView {
        id: itemListView
        height: implicitHeight
        width: Math.min(Math.max(Layout.minimumWidth, implicitWidth), Layout.maximumWidth)

        iconsEnabled: itemDialog.parentItemListView ? itemDialog.parentItemListView.iconsEnabled : false
        buttonHeight: itemDialog.parentItemListView ? itemDialog.parentItemListView.buttonHeight : 0
        itemSpacing: itemDialog.parentItemListView ? itemDialog.parentItemListView.itemSpacing : Kirigami.Units.smallSpacing
        LayoutMirroring.enabled: itemDialog.LayoutMirroring.enabled

        dialog: itemDialog
        itemListDialogComponent: itemDialog.itemListDialogComponent

        model: funnelModel

        onInteractionConcluded: itemDialog.interactionConcluded()

        Kicker.FunnelModel {
            id: funnelModel

            property bool sorted: sourceModel?.sorted ?? false

            Component.onCompleted: {
                // kicker.reset is not available in this context, skip connection
                // funnelModel.reset will be called automatically when needed
            }

            onCountChanged: {
                if (sourceModel && count === 0) {
                    itemDialog.delayedDestroy();
                }
            }

            onSourceModelChanged: {
                itemListView.currentIndex = -1;
                itemListView.resetDelegateSizing();
            }
        }
    }

    function delayedDestroy() {
        aboutToBeDestroyed = true;

        Qt.callLater(() => itemDialog.destroy());
    }
}
