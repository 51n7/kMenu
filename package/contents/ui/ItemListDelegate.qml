import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents3

/**
 * ItemListDelegate - Delegate component that renders each individual menu item
 * 
 * This component is used by ItemListView to display each menu item. It:
 * 
 * 1. Renders the visual representation of menu items (icon, label, arrow for submenus)
 * 2. Handles separator rendering with a visible line between menu sections
 * 3. Executes commands when menu items are clicked
 * 4. Handles keyboard navigation (Enter/Return key presses)
 * 5. Manages hover states and visual feedback
 * 6. Shows submenu indicators (arrows) for items with children
 * 7. Provides accessibility roles and descriptions
 * 
 * Used in ItemListView.qml as the delegate property, which means one instance
 * of this component is created for each item in the menu model. Without this
 * component, menu items would not be displayed at all.
 */
PlasmaComponents3.ItemDelegate {
    id: item

    width: ListView.view.width

    // ListView uses itemSpacing between items (set by ItemListView)
    property int itemSpacing: Kirigami.Units.smallSpacing
    // 0 = no space (smallest), 0.1 = tiny, 0.25 = small, 0.5 = medium
    readonly property int separatorVerticalMargin: Math.max(0, Math.round(Kirigami.Units.smallSpacing * 0))

    // Text items: content height only. Separator: margin + line + margin
    height: actualIsSeparator && !showSeparators ? 0 : (actualIsSeparator ? (separatorVerticalMargin * 2 + 2) : (buttonHeight > 0 ? buttonHeight : implicitHeight))
    topPadding: 0
    bottomPadding: 0

    // if it's not disabled and is either a leaf node or a node with children
    enabled: !actualIsSeparator && !disabled && (!isParent || (isParent && actualHasChildren))

    required property int index
    required property bool isSeparator
    required property bool hasChildren
    required property bool isParent
    
    // Override isSeparator to read from source model if FunnelModel doesn't pass it through
    property bool actualIsSeparator: {
        // First try the model's isSeparator (works if FunnelModel passes it through)
        if (isSeparator) {
            return true;
        }
        // If not, try to get it from the source model directly
        const sourceModel = ListView.view ? (ListView.view.model.sourceModel || ListView.view.model) : null;
        if (sourceModel && sourceModel.get) {
            try {
                const modelItem = sourceModel.get(index);
                if (modelItem && modelItem.isSeparator) {
                    return modelItem.isSeparator;
                }
            } catch (e) {
                // Ignore errors
            }
        }
        return isSeparator; // Fallback to the original value
    }
    
    // Override hasChildren to read from source model if FunnelModel doesn't pass it through
    property bool actualHasChildren: {
        // First try the model's hasChildren (works if FunnelModel passes it through)
        if (hasChildren) {
            return true;
        }
        // If not, try to get it from the source model directly
        const sourceModel = ListView.view ? (ListView.view.model.sourceModel || ListView.view.model) : null;
        if (sourceModel && sourceModel.get) {
            try {
                const modelItem = sourceModel.get(index);
                if (modelItem && modelItem.hasChildren) {
                    return modelItem.hasChildren;
                }
            } catch (e) {
                // Ignore errors
            }
        }
        return hasChildren; // Fallback to the original value
    }
    required property bool disabled
    required property url url
    required property string description
    required property string decoration
    required property var model // for display, which would shadow ItemDelegate
    required property bool showIcons

    readonly property bool iconAndLabelsShouldlookSelected: pressed && !actualHasChildren

    property bool showSeparators: true
    /** When > 0, height of this menu item in pixels; set by ItemListView. 0 = use implicit height. */
    property int buttonHeight: 0
    property bool dialogDefaultRight: Application.layoutDirection !== Qt.RightToLeft

    signal interactionConcluded

    Accessible.role: actualIsSeparator ? Accessible.Separator : Accessible.ListItem
    Accessible.description: isParent
        ? i18nc("@action:inmenu accessible description for opening submenu", "Open category")
        : i18nc("@action:inmenu accessible description for opening app or file", "Launch")
    text: model.display
    icon.name: decoration

    onActualHasChildrenChanged: {
        if (!actualHasChildren && ListView.view.currentItem === item) {
            ListView.view.currentIndex = -1;
        }
    }
    
    onClicked: {
        if (!item.actualHasChildren) {
            // Try to get command from model and execute directly via executable
            const model = item.ListView.view ? item.ListView.view.model : null;
            
            if (model) {
                // Get sourceModel from FunnelModel if it exists
                const sourceModel = model.sourceModel || model;
                
                // Get the item from the sourceModel
                const modelItem = sourceModel && sourceModel.get ? sourceModel.get(index) : null;
                
                if (modelItem) {
                    const cmd = modelItem.command ? String(modelItem.command) : null;
                    
                    if (cmd) {
                        // Try to get executable from sourceModel and execute directly
                        if (sourceModel && sourceModel.executable && typeof sourceModel.executable.exec === 'function') {
                            sourceModel.executable.exec(cmd);
                            item.interactionConcluded();
                            return;
                        }
                        
                        // Fallback: try model's executable (FunnelModel)
                        if (model.executable && typeof model.executable.exec === 'function') {
                            model.executable.exec(cmd);
                            item.interactionConcluded();
                            return;
                        }
                    }
                }
            }
            
            // Fallback to trigger function
            if (item.ListView.view && item.ListView.view.model) {
                if (typeof item.ListView.view.model.trigger === 'function') {
                    const result = item.ListView.view.model.trigger(index, "", null);
                    if (result) {
                        item.interactionConcluded()
                    }
                } else {
                    item.interactionConcluded()
                }
            } else {
                item.interactionConcluded()
            }
        }
    }

    DragHandler {
        target: null
        onActiveChanged: {
            if (active && item.url) {
                // we need dragHelper and can't use attached Drag; submenus are destroyed too soon and Plasma crashes
                dragHelper.startDrag(kicker, item.url, item.decoration)
            }
        }
    }

    contentItem: RowLayout {
        id: row

        spacing: Kirigami.Units.smallSpacing * 2

        LayoutMirroring.enabled: (Application.layoutDirection === Qt.RightToLeft)

        Kirigami.Icon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth

            visible: item.showIcons & !item.actualIsSeparator

            animated: false
            selected: item.iconAndLabelsShouldlookSelected
            source: item.icon.name
        }

        PlasmaComponents3.Label {
            id: label

            enabled: !item.isParent || (item.isParent && item.actualHasChildren)
            LayoutMirroring.enabled: (Application.layoutDirection === Qt.RightToLeft)
            visible: !item.actualIsSeparator

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Kirigami.Units.smallSpacing

            verticalAlignment: Text.AlignVCenter

            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            color: item.iconAndLabelsShouldlookSelected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

            text: item.text
        }

        Kirigami.Icon {
            id: arrow

            Layout.alignment: Qt.AlignVCenter

            implicitWidth: visible ? Kirigami.Units.iconSizes.small : 0
            implicitHeight: implicitWidth

            visible: item.actualHasChildren && !item.actualIsSeparator
            opacity: (item.ListView.view.currentIndex === item.index) ? 1.0 : 0.4
            selected: item.iconAndLabelsShouldlookSelected
            source: item.dialogDefaultRight
                ? "go-next-symbolic"
                : "go-next-rtl-symbolic"
        }

    }

    // Separator line - outside RowLayout, directly in ItemDelegate
    Rectangle {
        id: separatorLine
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: (item.actualIsSeparator && item.showSeparators) ? 1.6 : 0
        visible: item.actualIsSeparator && item.showSeparators
        color: Qt.rgba(0, 0, 0, 0.10) // 12% opacity black like kMenu
        z: 10 // Above contentItem
    }

    Keys.onReturnPressed: item.clicked()
    Keys.onEnterPressed: Keys.returnPressed()
}
