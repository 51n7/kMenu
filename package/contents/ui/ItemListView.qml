pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker

PlasmaComponents3.ScrollView {
    id: itemList

    signal exited
    signal keyNavigationAtListEnd
    signal navigateLeftRequested
    signal navigateRightRequested
    signal interactionConcluded
    
    function propagateInteractionConcludedToRoot() {
        // Find the root ItemListView and call interactionConcluded on it
        let root = itemList;
        while (root.dialog && root.dialog.parentItemListView) {
            root = root.dialog.parentItemListView;
        }
        root.interactionConcluded();
    }

    readonly property var actualScrollBarWidth: (itemList.contentHeight > itemList.height ? PlasmaComponents3.ScrollBar.vertical.width : 0)
    property Item mainSearchField: null
    property Kicker.SubMenu dialog: null
    property Kicker.SubMenu childDialog: null
    property bool iconsEnabled: false
    property Component itemListDialogComponent: null

    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias keyNavigationWraps: listView.keyNavigationWraps
    property alias model: listView.model
    property alias count: listView.count
    property alias resetOnExitDelay: resetIndexTimer.interval
    property alias showSeparators: listView.showSeparators
    property alias listView: listView
    /** When > 0, fixed width for the menu in pixels; 0 = use default width. */
    property int menuWidth: 0
    /** When > 0, height of each menu item (button) in pixels; 0 = use default (implicit) height. */
    property int buttonHeight: 0
    /** Vertical gap between every menu item (and around separators); one value for consistent spacing. */
    property int itemSpacing: Kirigami.Units.smallSpacing

    implicitWidth: listView.implicitWidth + actualScrollBarWidth
    implicitHeight: listView.contentHeight

    readonly property int _defaultMinWidth: Kirigami.Units.gridUnit * 14
    Layout.minimumWidth: menuWidth > 0 ? menuWidth : _defaultMinWidth
    Layout.maximumWidth: menuWidth > 0 ? menuWidth : Math.round(_defaultMinWidth * 1.5)
    Layout.maximumHeight: contentHeight

    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    function resetDelegateSizing() { // only needed when submenus are reused, called from ItemListDialog
        listView.maxDelegateImplicitWidth = 0
    }


    function subMenuForCurrentItem(focusOnSpawn=false) {
        // Menu is always expanded when shown, so we don't need to check kicker.expanded
        if (!itemList.model || listView.currentIndex === -1) {
            return;
        }
        const currentItem = listView.currentItem as ItemListDelegate;
        if (!currentItem) {
            return;
        }
        if (!currentItem.actualHasChildren) {
            clearChildDialog();
            return;
        }
        if (!itemList.childDialog) {
            // Get the source model from FunnelModel if it exists, otherwise use model directly
            const sourceModel = (model && model.sourceModel) ? model.sourceModel : model;
            if (!sourceModel) {
                return;
            }
            if (!sourceModel.modelForRow) {
                return;
            }
            
            let subModel = null;
            try {
                subModel = sourceModel.modelForRow(listView.currentIndex);
            } catch (e) {
                return;
            }
            
            if (!subModel) {
                return;
            }
            if (!itemList.itemListDialogComponent) {
                return;
            }
            
            if (!subModel || typeof subModel.count === 'undefined' || subModel.count === 0) {
                return;
            }
            
            // Create the dialog with the submenu model
            // Kicker.SubMenu with Floating should be parented to null (top-level)
            const dialog = itemList.itemListDialogComponent.createObject(null, {
                visualParent: listView.currentItem,
                model: subModel,
                visible: true,
                dialogMirrored: itemList.LayoutMirroring.enabled,
                itemListDialogComponent: itemList.itemListDialogComponent
            });
            
            if (dialog) {
                itemList.childDialog = dialog;
                dialog.index = listView.currentIndex;
                dialog.visible = true;
                dialog.parentItemListView = itemList;
                
                // Connect child dialog's interactionConcluded to propagate to root
                // This ensures commands in child dialogs close the entire menu
                dialog.interactionConcluded.connect(() => {
                    if (dialog.parentItemListView) {
                        dialog.parentItemListView.propagateInteractionConcludedToRoot();
                    }
                });
                
                if (focusOnSpawn && dialog.mainItem) {
                    const childListView = dialog.mainItem as ItemListView;
                    childListView.currentIndex = 0;
                    // Use Qt.callLater to ensure the dialog is fully initialized before setting focus
                    Qt.callLater(() => {
                        if (childListView && childListView.listView) {
                            childListView.forceActiveFocus(Qt.TabFocusReason);
                            // Also ensure the ListView inside gets focus
                            childListView.listView.forceActiveFocus(Qt.TabFocusReason);
                        }
                    });
                }
            }
        } else {
            const sourceModel = (model && model.sourceModel) ? model.sourceModel : model;
            const subModel = (sourceModel && sourceModel.modelForRow) ? sourceModel.modelForRow(itemList.currentIndex) : null;
            if (subModel) {
                itemList.childDialog.model = subModel;
                itemList.childDialog.visualParent = listView.currentItem;
                itemList.childDialog.index = listView.currentIndex;
            }
        }
    }

    function clearChildDialog() {
        if (childDialog) {
            childDialog.delayedDestroy();
            childDialog = null;
        }
    }

    Keys.priority: Keys.AfterItem
    Keys.forwardTo: [itemList.mainSearchField]

    onHoveredChanged: {
        if (hovered) {
            resetIndexTimer.stop();
        } else if (itemList.childDialog && listView.currentIndex != itemList.childDialog?.index) {
            listView.currentIndex = childDialog.index
        } else if ((!itemList.childDialog || !itemList.dialog)
            && (!itemList.currentItem || !(itemList.currentItem as ItemListDelegate).menu.opened)) {
            resetIndexTimer.start();
        }
    }

    ListView {
        id: listView

        width: itemList.availableWidth
        implicitHeight: contentHeight
        implicitWidth: itemList.Layout.minimumWidth

        property int maxDelegateImplicitWidth: 0 // used to set implicitWidth
        property bool showSeparators: !model.sorted // separators are mostly useless when sorted

        Binding on implicitWidth {
            value: listView.maxDelegateImplicitWidth
            delayed: true // only resize once all delegates are loaded
            when: listView.maxDelegateImplicitWidth > 0
        }

        currentIndex: -1
        focus: true

        clip: height < contentHeight + topMargin + bottomMargin
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
        // Same gap between every item (text and separator) for consistent margin
        spacing: itemList.itemSpacing
        keyNavigationEnabled: false
        cacheBuffer: 10000 // try to load all delegates for sizing; krunner won't return too many anyway

        Accessible.name: itemList.Accessible.name
        Accessible.role: Accessible.List

        function updateImplicitWidth () {
            implicitWidth = maxDelegateImplicitWidth
        }

        delegate: ItemListDelegate {
            showSeparators: listView.showSeparators
            showIcons: itemList.iconsEnabled
            buttonHeight: itemList.buttonHeight
            itemSpacing: itemList.itemSpacing
            dialogDefaultRight: !itemList.LayoutMirroring.enabled
            hoverEnabled: itemList.hoverEnabled
            onInteractionConcluded: {
                // If we're in a submenu, propagate directly to root to ensure menu closes
                if (itemList.dialog && itemList.dialog.parentItemListView) {
                    itemList.propagateInteractionConcludedToRoot();
                } else {
                    // At root level, emit normally
                    itemList.interactionConcluded();
                }
            }
            onHoveredChanged: {
                if (hovered & !actualIsSeparator) {
                    listView.currentIndex = index
                    itemList.forceActiveFocus()
                    dialogSpawnTimer.restart()
                } else if (listView.currentIndex === index) {
                    dialogSpawnTimer.stop()
                }
            }

            Connections {
                target: itemList.mainSearchField

                function onTextChanged() {
                    listView.maxDelegateImplicitWidth = 0
                }
            }
            onImplicitWidthChanged: {
                listView.maxDelegateImplicitWidth = Math.max(listView.maxDelegateImplicitWidth, implicitWidth)
            }
        }

        highlight: PlasmaExtras.Highlight {
            width: listView.width
            visible: !(listView.currentItem as ItemListDelegate)?.actualIsSeparator
            pressed: !!((listView.currentItem as ItemListDelegate)?.pressed && (listView.currentItem as ItemListDelegate)?.actualHasChildren)
            active: !!(listView.currentItem as ItemListDelegate)?.hovered
        }

        highlightMoveDuration: 0

        onCountChanged: {
            if (currentIndex == 0 && !itemList.mainSearchField.activeFocus) {
                currentItem?.forceActiveFocus();
            } else {
                currentIndex = -1;
            }
        }

        onCurrentIndexChanged: {
            if (currentIndex === itemList.childDialog?.index) {
                return;
            }
            const delegate = currentItem as ItemListDelegate;
            if (currentIndex === -1 || (delegate && !delegate.actualHasChildren)) {
                dialogSpawnTimer.stop();
                itemList.clearChildDialog();
            } else if (delegate && delegate.actualHasChildren) {
                // Item has children, restart timer to show submenu
                // Don't restart timer here - let the hover handler do it
                // The timer will fire and call subMenuForCurrentItem
            }
        }

        Connections {
            target: (listView.currentItem as ItemListDelegate)?.menu ?? null
            function onClosed() {
                resetIndexTimer.restart()
            }
        }

        function handleLeftRightArrowEnter(event: KeyEvent) : void {
            let backArrowKey = (event.key === Qt.Key_Left && !itemList.LayoutMirroring.enabled) ||
                (event.key === Qt.Key_Right && itemList.LayoutMirroring.enabled)
            let forwardArrowKey = (event.key === Qt.Key_Right && !itemList.LayoutMirroring.enabled) ||
                (event.key === Qt.Key_Left && itemList.LayoutMirroring.enabled)

            if (backArrowKey) {
                if (itemList.dialog != null) {
                    itemList.dialog.destroy();
                } else {
                    itemList.navigateLeftRequested();
                }
            } else if (forwardArrowKey || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (listView.currentItem !== null && (listView.currentItem as ItemListDelegate).actualHasChildren) {
                    if (itemList.childDialog === null) {
                        itemList.subMenuForCurrentItem(true);
                    } else {
                        const childListView = itemList.childDialog.mainItem as ItemListView;
                        if (childListView) {
                            childListView.forceActiveFocus(Qt.TabFocusReason);
                            // Ensure the ListView inside gets focus for keyboard navigation
                            if (childListView.listView) {
                                childListView.listView.forceActiveFocus(Qt.TabFocusReason);
                            }
                            childListView.currentIndex = 0;
                        }
                    }
                } else if (forwardArrowKey) {
                    itemList.navigateRightRequested();
                } else {
                    event.accepted = false;
                }
            }
        }

        function handleUpDownArrow(event: KeyEvent) : void {
            let moveIndex = (event.key === Qt.Key_Up) ? listView.decrementCurrentIndex : listView.incrementCurrentIndex

            if (!listView.keyNavigationWraps && ((event.key === Qt.Key_Up && listView.currentIndex == 0) ||
                                                 (event.key === Qt.Key_Down && listView.currentIndex == listView.count - 1))) {
                itemList.keyNavigationAtListEnd();
            } else {
                moveIndex();

                if (listView.currentItem !== null) {
                    if ((listView.currentItem as ItemListDelegate).actualIsSeparator) {
                        moveIndex();
                    }
                    listView.currentItem.forceActiveFocus(Qt.TabFocusReason);
                }
            }
        }

        Keys.onLeftPressed: event => handleLeftRightArrowEnter(event)
        Keys.onRightPressed: event => handleLeftRightArrowEnter(event)
        Keys.onEnterPressed: event => handleLeftRightArrowEnter(event)
        Keys.onReturnPressed: event => handleLeftRightArrowEnter(event)
        Keys.onUpPressed: event => handleUpDownArrow(event)
        Keys.onDownPressed: event => handleUpDownArrow(event)
        Keys.onEscapePressed: {
            // If we're in a child dialog, propagate to root by traversing parent chain
            if (itemList.dialog && itemList.dialog.parentItemListView) {
                // We're in a child dialog, find root and call it
                let root = itemList.dialog.parentItemListView;
                while (root.dialog && root.dialog.parentItemListView) {
                    root = root.dialog.parentItemListView;
                }
                root.interactionConcluded();
            } else {
                // We're at root level, just emit the signal
                itemList.interactionConcluded();
            }
        }
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Tab && event.text !== "") {
                itemList.mainSearchField?.forceActiveFocus(Qt.ShortcutFocusReason);
            }
        }

        Timer {
            id: dialogSpawnTimer

            interval: 100
            repeat: false

            onTriggered: {
                itemList.subMenuForCurrentItem();
            }
        }

        Timer {
            id: resetIndexTimer

            interval: (itemList.dialog != null) ? 50 : 150
            repeat: false

            onTriggered: {
                if (itemList.focus && !(itemList.childDialog?.mainItem as ItemListView)?.hovered) {
                    itemList.currentIndex = -1;
                    itemList.exited();
                }
            }
        }
    }
}
