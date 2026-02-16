/*
    SPDX-FileCopyrightText: 2024

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

/**
 * TreeItemDelegate - Delegate for individual items in the menu tree view
 * 
 * Displays a menu item in the hierarchical tree with:
 * - Expand/collapse indicator for items with children
 * - Visual tree lines (vertical and horizontal connectors)
 * - Indentation based on nesting level
 * - Selection highlighting
 * - Icon and name display (or separator indicator)
 */
Rectangle {
    id: delegate

    // Accept either itemModel (for backwards compatibility) or direct properties
    property var itemModel: null
    // Direct properties - these override itemModel if set
    property var itemData: null
    property int level: 0
    property bool hasChildren: false
    property bool isExpanded: false
    property bool isSelected: false
    property bool isLastChild: false  // Whether this is the last child at its level
    property bool isFirstTopLevel: false  // Whether this is the first top-level item
    property var parentPaths: []  // Array of parent paths to determine tree line drawing
    
    // Resolve itemData - use direct property if set (check for undefined too), otherwise use itemModel
    readonly property var resolvedItemData: (itemData !== null && itemData !== undefined) ? itemData : (itemModel ? itemModel.itemData : null)
    readonly property int resolvedLevel: (itemData !== null && itemData !== undefined) ? level : (itemModel ? itemModel.level : 0)
    readonly property bool resolvedHasChildren: (itemData !== null && itemData !== undefined) ? hasChildren : (itemModel ? itemModel.hasChildren : false)
    readonly property bool resolvedIsExpanded: (itemData !== null && itemData !== undefined) ? isExpanded : (itemModel ? itemModel.isExpanded : false)
    readonly property bool resolvedIsLastChild: (itemData !== null && itemData !== undefined) ? isLastChild : (itemModel ? itemModel.isLastChild : false)
    readonly property bool isSeparator: resolvedItemData ? resolvedItemData.separator : false

    signal selected()
    signal toggleExpanded()

    height: isSeparator ? (Kirigami.Units.gridUnit * 0.75) : (Kirigami.Units.gridUnit * 2)
    // Darker selection background so text (highlightedTextColor) is easier to read
    color: isSelected ? Qt.darker(Kirigami.Theme.highlightColor, 2) : (mouseArea.containsMouse ? Kirigami.Theme.alternateBackgroundColor : "transparent")
    
    // Draw tree lines - make them clearly visible
    // Vertical lines for each parent level (these connect siblings at that level)
    // Children draw lines for levels 0 to resolvedLevel-1 (all their parent levels)
    Repeater {
        model: resolvedLevel
        delegate: Rectangle {
            // Position at the center of the expand button for this level
            x: {
                // All vertical lines should be evenly spaced gridUnit apart from base position
                // Base position: smallSpacing + iconSize/2
                // modelData represents the parent level
                // modelData === 0: parent is level 0, so draw at level 0 chevron center (base + gridUnit)
                // modelData === 1: parent is level 1, so draw at level 1 chevron center (base + 2*gridUnit)
                // modelData === 2: parent is level 2, so draw at level 2 chevron center (base + 3*gridUnit)
                // etc.
                var baseX = Kirigami.Units.smallSpacing + (Kirigami.Units.iconSizes.small / 2);
                // Parent level is modelData, so parent's chevron center is at base + (modelData + 1) * gridUnit
                return baseX + ((modelData + 1) * Kirigami.Units.gridUnit) - 0.5;
            }
            y: 0
            width: 1
            // If this is the last child at its immediate parent level, only draw to middle; otherwise full height
            // However, if this item has children, the line for the immediate parent level should continue through full height
            height: {
                if (resolvedIsLastChild && modelData === resolvedLevel - 1) {
                    // Last child at immediate parent level: draw to middle, unless this item has children (then full height)
                    return resolvedHasChildren ? parent.height : (parent.height / 2);
                } else {
                    // Not last child: full height
                    return parent.height;
                }
            }
            // Use a visible gray color
            color: "#888888"
            z: 0
        }
    }
    
    // Vertical line for top-level items (level 0) - connects siblings at root level
    // Also drawn for all descendants of top-level items (level > 0) to continue the line
    Rectangle {
        // Draw for level 0 items and all their descendants (level > 0)
        visible: true  // Draw for all items to continue the top-level line
        // Top-level vertical line at base position (left edge)
        x: Kirigami.Units.smallSpacing + (Kirigami.Units.iconSizes.small / 2) - 0.5
        y: isFirstTopLevel ? ((parent.height / 2) - 1) : 0  // Start from middle minus 1px for first item, top for others
        width: 1
        // For level 0: draw full height for all top-level items except last (if no children)
        // For first top-level item: start from middle minus 1px, so height is half plus 1px
        // For level > 0: always draw full height to continue the line through all descendants
        height: {
            if (resolvedLevel === 0) {
                if (isFirstTopLevel) {
                    // First top-level item: start from middle minus 1px, so draw half height plus 1px
                    return (parent.height / 2) + 1;
                } else {
                    // Level 0: only stop at middle for the very last top-level item (if it has no children)
                    return (resolvedIsLastChild && !resolvedHasChildren) ? (parent.height / 2) : parent.height;
                }
            } else {
                // Level > 0: always full height to continue the top-level line through all nested descendants
                return parent.height;
            }
        }
        color: "#888888"
        z: 0
    }
    
    // Horizontal line for top-level items (level 0) - connects from vertical line to item
    Rectangle {
        visible: resolvedLevel === 0 && !isSeparator
        // Start from the top-level vertical line position
        x: Kirigami.Units.smallSpacing + (Kirigami.Units.iconSizes.small / 2)
        y: parent.height / 2 - 0.5
        // Extend from vertical line to just before chevron
        // For items with icons: shorter line to avoid touching
        // For submenus with arrows: longer line (original width)
        width: resolvedHasChildren 
            ? (Kirigami.Units.gridUnit - (Kirigami.Units.iconSizes.small / 2))  // Submenu with arrow: original width
            : (Kirigami.Units.gridUnit - (Kirigami.Units.iconSizes.small / 2) - Kirigami.Units.smallSpacing)  // Item with icon: shorter
        height: 1
        color: "#888888"
        z: 0
    }
    
    // Vertical line for this item's own level (if it has children and is expanded)
    // This creates the consistent line that extends from this item through all its children
    // For level 0 items with children, this draws the vertical line at the base position (continuing from main vertical line)
    // For level 1+ items, this draws the vertical line at their indented position
    // This line starts from the chevron (middle) and extends down, not above the chevron
    Rectangle {
        visible: resolvedHasChildren && resolvedIsExpanded
        x: {
            // Align with chevron center
            // Content leftMargin: smallSpacing + (level + 1) * gridUnit
            // Chevron center: leftMargin + iconSize/2
            // = smallSpacing + (level + 1) * gridUnit + iconSize/2
            var leftMargin = Kirigami.Units.smallSpacing + ((resolvedLevel + 1) * Kirigami.Units.gridUnit);
            return leftMargin + (Kirigami.Units.iconSizes.small / 2) - 0.5;
        }
        y: parent.height / 2  // Start from middle (where chevron is), not from top
        width: 1
        height: parent.height / 2  // Extend to bottom of item
        // This line will be continued by children drawing their portion for this level
        color: "#888888"
        z: 0
    }
    
    // Horizontal line connecting this item to its parent's vertical line (omit for separators)
    Rectangle {
        visible: resolvedLevel > 0 && !isSeparator
        // Start from parent's vertical line (at base position for level 0 parents, indented for level 1+ parents)
        x: {
            // Connect from parent's vertical line
            // Parent's vertical line is at: base + (parentLevel + 1) * gridUnit
            // Parent level is resolvedLevel - 1
            var baseX = Kirigami.Units.smallSpacing + (Kirigami.Units.iconSizes.small / 2);
            var parentLevel = resolvedLevel - 1;
            return baseX + ((parentLevel + 1) * Kirigami.Units.gridUnit);
        }
        y: parent.height / 2 - 0.5
        // Extend to this item's indented content position (same width whether has children or not)
        // The line should stop well before the icon/chevron area to avoid hitting icons
        width: {
            // Extend from parent's vertical line to just before chevron
            // Parent's vertical line: base + (parentLevel + 1) * gridUnit
            // This item's leftMargin: smallSpacing + (level + 1) * gridUnit
            // Chevron center: leftMargin + iconSize/2 = smallSpacing + (level + 1) * gridUnit + iconSize/2
            // Parent's vertical line: base + (parentLevel + 1) * gridUnit = smallSpacing + iconSize/2 + (parentLevel + 1) * gridUnit
            // Distance: (level + 1) * gridUnit + iconSize/2 - (parentLevel + 1) * gridUnit - iconSize/2
            // = (level - parentLevel) * gridUnit = gridUnit (since level = parentLevel + 1)
            // For items with icons: shorter line to avoid touching
            // For submenus with arrows: longer line (original width)
            return resolvedHasChildren
                ? (Kirigami.Units.gridUnit - (Kirigami.Units.iconSizes.small / 2))  // Submenu with arrow: original width
                : (Kirigami.Units.gridUnit - (Kirigami.Units.iconSizes.small / 2) - Kirigami.Units.smallSpacing);  // Item with icon: shorter
        }
        height: 1
        color: "#888888"
        z: 0
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            delegate.selected();
        }
    }

    RowLayout {
        anchors.fill: parent
        // Indent all items to make space for the top-level vertical line
        anchors.leftMargin: {
            // Align chevrons with vertical lines
            // Vertical lines are at: base + (level + 1) * gridUnit
            // Chevron center should be at vertical line position
            // So leftMargin = vertical line position - iconSize/2
            // = smallSpacing + iconSize/2 + (level + 1) * gridUnit - iconSize/2
            // = smallSpacing + (level + 1) * gridUnit
            return Kirigami.Units.smallSpacing + ((resolvedLevel + 1) * Kirigami.Units.gridUnit);
        }
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        z: 2  // Ensure content is above tree lines

        // Expand/collapse button with background to prevent lines from touching
        Rectangle {
            visible: resolvedHasChildren
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            // Always use theme background to create visible spacing from tree lines
            color: Kirigami.Theme.backgroundColor
            radius: 2
            z: 1  // Ensure it's above the tree lines
            
            PlasmaComponents3.ToolButton {
                anchors.fill: parent
                icon.name: resolvedIsExpanded ? "arrow-down" : "arrow-right"
                onClicked: {
                    delegate.toggleExpanded();
                }
            }
        }

        // Icon (positioned where chevron would be for alignment, hidden for parent items with children)
        Kirigami.Icon {
            source: isSeparator ? "" : (resolvedItemData ? (resolvedItemData.icon || "application-x-executable") : "application-x-executable")
            Layout.preferredWidth: isSeparator ? 0 : Kirigami.Units.iconSizes.small
            Layout.preferredHeight: isSeparator ? 0 : Kirigami.Units.iconSizes.small
            visible: !isSeparator && !resolvedHasChildren
        }

        // Name label (for regular items)
        PlasmaComponents3.Label {
            visible: !isSeparator
            Layout.fillWidth: true
            text: resolvedItemData ? (resolvedItemData.name || i18n("Unnamed")) : i18n("Unnamed")
            elide: Text.ElideRight
            color: isSelected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        }
        
    }
    
    // Separator line (for separator items) - start at vertical tree line so there is no gap
    Rectangle {
        visible: isSeparator
        // Align left edge with the vertical line that runs down the left of this item's group.
        // Level 0: top-level vertical line at baseX - 0.5.
        // Level L>0: that line is the parent's vertical (Repeater modelData 0..L-1); the left edge
        // for our group is at baseX + L*gridUnit - 0.5 (same as Repeater with modelData = L-1).
        x: Kirigami.Units.smallSpacing + (Kirigami.Units.iconSizes.small / 2) + (resolvedLevel * Kirigami.Units.gridUnit) - 0.5
        width: parent.width - x - Kirigami.Units.smallSpacing
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Kirigami.Theme.separatorColor || "#888888"
        z: 2  // Above tree lines
    }
}

