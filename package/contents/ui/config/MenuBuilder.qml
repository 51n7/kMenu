/*
    SPDX-FileCopyrightText: 2024

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.iconthemes as KIconThemes

/**
 * MenuBuilder - Visual menu editor with hierarchical tree view and property editor
 * 
 * This component provides a KDE Menu Editor-like interface for editing the JSON menu structure.
 * It features:
 * - Left pane: Hierarchical tree view with expandable/collapsible items
 * - Right pane: Property editor for the selected menu item
 * - Toolbar: Add, Delete, Move Up/Down buttons
 * - Real-time JSON generation from the edited structure
 */
Item {
    id: root

    property var menuData: []
    property string jsonOutput: ""

    function loadFromJson(jsonString) {
        try {
            if (!jsonString || jsonString.trim() === "" || jsonString === "[]") {
                // Use default menu from main.xml
                jsonString = '[{"name":"About This Computer","icon":"help-hint","command":"kinfocenter"},{"separator":true},{"name":"System Preferences...","icon":"settings-configure","command":"systemsettings"},{"name":"App Store...","icon":"update-none","command":"plasma-discover"},{"separator":true},{"name":"Force Quit...","icon":"error","command":"xkill"},{"separator":true},{"name":"Sleep","icon":"system-suspend","command":"systemctl suspend"},{"name":"Restart...","icon":"system-reboot","command":"qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptReboot"},{"name":"Shut Down...","icon":"system-shutdown","command":"qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptShutDown"},{"separator":true},{"name":"Lock Screen","icon":"system-lock-screen","command":"qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock"},{"name":"Log Out","icon":"system-log-out","command":"qdbus6 org.kde.LogoutPrompt /LogoutPrompt promptLogout"}]';
            }
            const parsed = JSON.parse(jsonString);
            menuData = Array.isArray(parsed) ? parsed : [];
            expandedPaths = [];
            rebuildTreeModel();
            jsonOutput = JSON.stringify(menuData, null, 2);
        } catch (e) {
            console.error("MenuBuilder: Failed to parse JSON:", e);
            menuData = [];
            expandedPaths = [];
            treeModel.clear();
        }
    }

    function buildTreeModel(items, parentItem, level) {
        if (level === undefined) level = 0;
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            // An item has children if it has a submenu property (even if empty)
            // This allows empty submenus to show the expand/collapse chevron
            const hasChildren = !!(item.submenu && Array.isArray(item.submenu));
            const modelItem = {
                itemData: item,
                itemIndex: i,
                parentItem: parentItem,
                isExpanded: false,
                level: level,
                hasChildren: hasChildren,
                parentArray: parentItem ? parentItem.itemData.submenu : menuData
            };
            treeModel.append(modelItem);
            
            // Recursively add children if parent is expanded (but initially all collapsed)
            // We'll rebuild when expanding
        }
    }

    function rebuildTreeModel() {
        treeModel.clear();
        if (!menuData || menuData.length === 0) {
            return;
        }
        buildTreeModelRecursive(menuData, null, 0, "");
    }

    function buildTreeModelRecursive(items, parentItem, level, parentPath) {
        if (!items || items.length === 0) return;
        if (parentPath === undefined) parentPath = "";
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (!item) continue;
            // An item has children if it has a submenu property (even if empty)
            // This allows empty submenus to show the expand/collapse chevron
            const hasChildren = !!(item.submenu && Array.isArray(item.submenu));
            const isLastChild = (i === items.length - 1);
            const currentPath = parentPath === "" ? String(i) : parentPath + "/" + i;
            const isExpanded = root.isItemExpanded(item, currentPath);
            treeModel.append({
                itemData: item,
                itemIndex: i,
                parentItem: parentItem,
                isExpanded: isExpanded,
                level: level,
                hasChildren: hasChildren,
                isLastChild: isLastChild,
                parentArray: parentItem ? parentItem.itemData.submenu : menuData,
                path: currentPath
            });
            
            // Add children if this item is expanded and has children
            if (hasChildren && isExpanded && item.submenu.length > 0) {
                const currentModelItem = treeModel.get(treeModel.count - 1);
                buildTreeModelRecursive(item.submenu, currentModelItem, level + 1, currentPath);
            }
        }
    }

    property var expandedPaths: []  // Store paths instead of object references
    property var collapsedPaths: []  // Store paths of explicitly collapsed items
    property string selectedPath: ""
    
    function isItemExpanded(itemData, path) {
        // Use path to check if expanded, since object references change after rebuild
        if (path === undefined || path === "") return false;
        // If explicitly collapsed, return false
        if (collapsedPaths.indexOf(path) >= 0) return false;
        // By default, expand all items that have children
        if (itemData && itemData.submenu && Array.isArray(itemData.submenu) && itemData.submenu.length > 0) {
            return true;
        }
        // Otherwise check if explicitly in expandedPaths (for backwards compatibility)
        return expandedPaths.indexOf(path) >= 0;
    }
    
    function setItemExpanded(itemData, expanded, path) {
        if (path === undefined || path === "") return;
        if (expanded) {
            // Remove from collapsedPaths if present
            const collapsedIndex = collapsedPaths.indexOf(path);
            if (collapsedIndex >= 0) {
                collapsedPaths.splice(collapsedIndex, 1);
                // Force property change notification
                collapsedPaths = collapsedPaths.slice();
            }
            // Add to expandedPaths if not present (for backwards compatibility)
            const expandedIndex = expandedPaths.indexOf(path);
            if (expandedIndex < 0) {
                expandedPaths.push(path);
                // Force property change notification
                expandedPaths = expandedPaths.slice();
            }
        } else {
            // Add to collapsedPaths if not present
            const collapsedIndex = collapsedPaths.indexOf(path);
            if (collapsedIndex < 0) {
                collapsedPaths.push(path);
                // Force property change notification
                collapsedPaths = collapsedPaths.slice();
            }
            // Remove from expandedPaths if present (for backwards compatibility)
            const expandedIndex = expandedPaths.indexOf(path);
            if (expandedIndex >= 0) {
                expandedPaths.splice(expandedIndex, 1);
                // Force property change notification
                expandedPaths = expandedPaths.slice();
            }
        }
    }

    function updateJson() {
        jsonOutput = JSON.stringify(menuData, null, 2);
    }

    function findItemByPath(path) {
        if (path === "" || path === "/") return null;
        const parts = path.split("/").filter(p => p !== "");
        let current = menuData;
        for (let i = 0; i < parts.length; i++) {
            const index = parseInt(parts[i]);
            if (current && current[index]) {
                if (i === parts.length - 1) {
                    return current[index];
                } else {
                    current = current[index].submenu || [];
                }
            } else {
                return null;
            }
        }
        return null;
    }

    function updateItemInMenuData(path, property, value) {
        if (path === "" || path === "/") return;
        const parts = path.split("/").filter(p => p !== "");
        let current = menuData;
        for (let i = 0; i < parts.length; i++) {
            const index = parseInt(parts[i]);
            if (current && current[index]) {
                if (i === parts.length - 1) {
                    // Found the item, update it
                    current[index][property] = value;
                    return;
                } else {
                    current = current[index].submenu || [];
                }
            } else {
                return;
            }
        }
    }

    function findItemInData(itemData, parentArray) {
        if (!parentArray) parentArray = menuData;
        for (let i = 0; i < parentArray.length; i++) {
            if (parentArray[i] === itemData) {
                return { array: parentArray, index: i };
            }
            if (parentArray[i].submenu) {
                const found = findItemInData(itemData, parentArray[i].submenu);
                if (found) return found;
            }
        }
        return null;
    }
    
    function getPathForItem(itemData, parentArray, parentPath) {
        if (!parentArray) parentArray = menuData;
        if (parentPath === undefined) parentPath = "";
        for (let i = 0; i < parentArray.length; i++) {
            const currentPath = parentPath === "" ? String(i) : parentPath + "/" + i;
            if (parentArray[i] === itemData) {
                return currentPath;
            }
            if (parentArray[i].submenu) {
                const found = getPathForItem(itemData, parentArray[i].submenu, currentPath);
                if (found) return found;
            }
        }
        return null;
    }

    function addItem(parentItemData, afterIndex) {
        const newItem = {
            name: "New Item",
            icon: "",
            command: ""
        };
        
        if (parentItemData && parentItemData.submenu) {
            // Add to parent's submenu
            const insertIndex = afterIndex !== undefined && afterIndex >= 0 ? afterIndex + 1 : parentItemData.submenu.length;
            parentItemData.submenu.splice(insertIndex, 0, newItem);
        } else if (parentItemData) {
            // Parent exists but no submenu - create it
            parentItemData.submenu = [newItem];
        } else {
            // Add to root level
            const insertIndex = afterIndex !== undefined && afterIndex >= 0 ? afterIndex + 1 : menuData.length;
            menuData.splice(insertIndex, 0, newItem);
        }
        
        rebuildTreeModel();
        updateJson();
    }

    function deleteItem(itemData) {
        if (!selectedPath || selectedPath === "") return;
        const parts = selectedPath.split("/").filter(p => p !== "");
        if (parts.length === 1) {
            // Root level item
            menuData.splice(parseInt(parts[0]), 1);
        } else {
            // Nested item: navigate to the parent array (same logic as moveItem)
            let current = menuData;
            for (let i = 0; i < parts.length - 1; i++) {
                const index = parseInt(parts[i]);
                if (current && current[index] && current[index].submenu) {
                    current = current[index].submenu;
                } else {
                    return; // Invalid path
                }
            }
            const targetIndex = parseInt(parts[parts.length - 1]);
            current.splice(targetIndex, 1);
        }
        selectedItem = null;
        selectedPath = "";
        rebuildTreeModel();
        updateJson();
    }

    function moveItem(itemData, direction) {
        if (!selectedPath || selectedPath === "") return;
        
        const parts = selectedPath.split("/").filter(p => p !== "");
        let current = menuData;
        let targetArray = menuData;
        let currentIndex = 0;
        
        // Navigate to the parent array containing the item
        if (parts.length === 1) {
            // Root level item
            targetArray = menuData;
            currentIndex = parseInt(parts[0]);
        } else {
            // Nested item - navigate to parent
            for (let i = 0; i < parts.length - 1; i++) {
                const index = parseInt(parts[i]);
                if (current && current[index] && current[index].submenu) {
                    current = current[index].submenu;
                } else {
                    return; // Invalid path
                }
            }
            targetArray = current;
            currentIndex = parseInt(parts[parts.length - 1]);
        }
        
        // Calculate new index
        const newIndex = direction === "up" ? currentIndex - 1 : currentIndex + 1;
        if (newIndex < 0 || newIndex >= targetArray.length) return;
        
        // Move the item
        const item = targetArray.splice(currentIndex, 1)[0];
        targetArray.splice(newIndex, 0, item);
        
        // Force update to trigger change detection (same as other functions)
        menuData = JSON.parse(JSON.stringify(menuData));
        
        // Rebuild the tree model
        rebuildTreeModel();
        updateJson();
        
        // Calculate new path after move
        const newPathParts = parts.slice();
        newPathParts[newPathParts.length - 1] = String(newIndex);
        const newPath = newPathParts.join("/");
        
        // Restore selection after rebuild
        Qt.callLater(() => {
            const restoredItem = findItemByPath(newPath);
            if (restoredItem) {
                selectedItem = restoredItem;
                selectedPath = newPath;
            }
        });
    }

    property var selectedItem: null  // Direct reference to item in menuData
    
    // Computed property to check if selected item is a parent (has submenu)
    // This needs to be reactive to changes in selectedItem and its submenu property
    readonly property bool selectedItemIsParent: {
        if (!selectedItem) return false;
        // Check if submenu property exists and is an array (even if empty)
        const hasSubmenu = selectedItem.hasOwnProperty('submenu') && 
                          selectedItem.submenu !== undefined && 
                          selectedItem.submenu !== null && 
                          Array.isArray(selectedItem.submenu);
        return hasSubmenu;
    }
    
    // Helper function to get array and index from path
    function getArrayAndIndexFromPath(path) {
        if (!path || path === "") return null;
        const parts = path.split("/").filter(p => p !== "");
        let current = menuData;
        for (let i = 0; i < parts.length - 1; i++) {
            const index = parseInt(parts[i]);
            if (current && current[index] && current[index].submenu) {
                current = current[index].submenu;
            } else {
                return null;
            }
        }
        const lastIndex = parseInt(parts[parts.length - 1]);
        return { array: current, index: lastIndex };
    }
    
    // Computed property to check if selected item can be moved up
    readonly property bool canMoveUp: {
        if (!selectedItem || !selectedPath) return false;
        const info = getArrayAndIndexFromPath(selectedPath);
        if (!info) return false;
        return info.index > 0;
    }
    
    // Computed property to check if selected item can be moved down
    readonly property bool canMoveDown: {
        if (!selectedItem || !selectedPath) return false;
        const info = getArrayAndIndexFromPath(selectedPath);
        if (!info) return false;
        return info.index < info.array.length - 1;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.mediumSpacing

            QQC2.Button {
                icon.name: "list-add"
                text: i18n("Add Item")
                onClicked: {
                    const newItem = {
                        name: "New Item",
                        icon: "",
                        command: ""
                    };
                    
                    // Save current selection path before making changes
                    const savedPath = selectedPath;
                    
                    if (selectedItem && selectedPath) {
                        // Find the item in menuData using the path (not the stale reference)
                        const currentItem = root.findItemByPath(selectedPath);
                        if (currentItem) {
                            // Check if selected item is a parent (has submenu property)
                            // Even if submenu is empty, it's still a parent
                            if (currentItem.submenu !== undefined && Array.isArray(currentItem.submenu)) {
                                // Add as child of the parent
                                // Ensure submenu exists (create if it doesn't)
                                if (!currentItem.submenu) {
                                    currentItem.submenu = [];
                                }
                                currentItem.submenu.push(newItem);
                                root.setItemExpanded(currentItem, true, selectedPath);
                            } else {
                                // Add as sibling after selected item
                                const found = root.findItemInData(currentItem);
                                if (found) {
                                    found.array.splice(found.index + 1, 0, newItem);
                                } else {
                                    menuData.push(newItem);
                                }
                            }
                        } else {
                            menuData.push(newItem);
                        }
                    } else {
                        // No item selected, add to root level
                        menuData.push(newItem);
                    }
                    
                    // Force update to trigger change detection
                    root.menuData = JSON.parse(JSON.stringify(menuData));
                    
                    // Restore selection after menuData update
                    if (savedPath) {
                        const restoredItem = root.findItemByPath(savedPath);
                        if (restoredItem) {
                            root.selectedItem = restoredItem;
                            root.selectedPath = savedPath;
                        }
                    }
                    
                    root.rebuildTreeModel();
                    root.updateJson();
                    
                    // Select the new item
                    Qt.callLater(() => {
                        const newItemPath = root.getPathForItem(newItem);
                        if (newItemPath) {
                            root.selectedItem = newItem;
                            root.selectedPath = newItemPath;
                        }
                    });
                }
            }

            QQC2.Button {
                icon.name: "folder-new"
                text: i18n("Add Folder")
                onClicked: {
                    const newItem = {
                        name: "New Folder",
                        icon: "folder",
                        submenu: []
                    };
                    
                    // Save current selection path before making changes
                    const savedPath = selectedPath;
                    
                    if (selectedItem && selectedPath) {
                        // Find the item in menuData using the path (not the stale reference)
                        const currentItem = root.findItemByPath(selectedPath);
                        if (currentItem) {
                            // Check if selected item is a parent (has submenu property)
                            // Even if submenu is empty, it's still a parent
                            if (currentItem.submenu !== undefined && Array.isArray(currentItem.submenu)) {
                                // Add as child of the parent
                                currentItem.submenu.push(newItem);
                                root.setItemExpanded(currentItem, true, selectedPath);
                            } else {
                                // Add as sibling after selected item
                                const found = root.findItemInData(currentItem);
                                if (found) {
                                    found.array.splice(found.index + 1, 0, newItem);
                                } else {
                                    menuData.push(newItem);
                                }
                            }
                        } else {
                            menuData.push(newItem);
                        }
                    } else {
                        // No item selected, add to root level
                        menuData.push(newItem);
                    }
                    
                    // Force update to trigger change detection
                    root.menuData = JSON.parse(JSON.stringify(menuData));
                    
                    // Restore selection after menuData update
                    if (savedPath) {
                        const restoredItem = root.findItemByPath(savedPath);
                        if (restoredItem) {
                            root.selectedItem = restoredItem;
                            root.selectedPath = savedPath;
                        }
                    }
                    
                    root.rebuildTreeModel();
                    root.updateJson();
                    
                    // Select and expand the new submenu item
                    Qt.callLater(() => {
                        const newItemPath = root.getPathForItem(newItem);
                        if (newItemPath) {
                            root.selectedItem = newItem;
                            root.selectedPath = newItemPath;
                            root.setItemExpanded(newItem, true, newItemPath);
                            root.rebuildTreeModel();
                            // Restore selection after rebuild
                            Qt.callLater(() => {
                                const restoredItem = root.findItemByPath(newItemPath);
                                if (restoredItem) {
                                    root.selectedItem = restoredItem;
                                    root.selectedPath = newItemPath;
                                }
                            });
                        }
                    });
                }
            }

            QQC2.Button {
                icon.name: "insert-horizontal-rule"
                text: i18n("Add Separator")
                onClicked: {
                    const newItem = {
                        separator: true
                    };
                    
                    // Use path (like Add Item) so we insert below selection, not at end
                    const savedPath = selectedPath;
                    const info = savedPath ? root.getArrayAndIndexFromPath(savedPath) : null;
                    if (info) {
                        info.array.splice(info.index + 1, 0, newItem);
                    } else {
                        // No selection: add to root level at end
                        menuData.push(newItem);
                    }
                    
                    root.menuData = JSON.parse(JSON.stringify(menuData));
                    if (savedPath) {
                        const restoredItem = root.findItemByPath(savedPath);
                        if (restoredItem) {
                            root.selectedItem = restoredItem;
                            root.selectedPath = savedPath;
                        }
                    }
                    root.rebuildTreeModel();
                    root.updateJson();
                }
            }

            QQC2.Button {
                icon.name: "go-up"
                // text: i18n("Move Up")
                enabled: root.canMoveUp
                onClicked: {
                    if (selectedItem) {
                        root.moveItem(selectedItem, "up");
                    }
                }
            }

            QQC2.Button {
                icon.name: "go-down"
                // text: i18n("Move Down")
                enabled: root.canMoveDown
                onClicked: {
                    if (selectedItem) {
                        root.moveItem(selectedItem, "down");
                    }
                }
            }

            QQC2.Button {
                icon.name: "edit-delete"
                // text: i18n("Delete")
                enabled: selectedItem !== null
                onClicked: {
                    if (selectedItem) {
                        root.deleteItem(selectedItem);
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Main content area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            // Left pane: Tree view
            QQC2.Frame {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                Layout.minimumWidth: Kirigami.Units.gridUnit * 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 0

                    // Tree view using ListView (TreeView requires C++ models)
                    QQC2.ScrollView {
                        id: treeScrollView
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: treeView
                            width: treeScrollView.availableWidth
                            implicitHeight: contentHeight
                            model: treeModel
                            clip: true
                            
                            // Draw tree lines in the background
                            // This is a workaround since TreeView requires C++ models
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                z: 0
                                
                                // We'll draw lines in each delegate instead
                                // This rectangle is just a placeholder
                            }

                            delegate: TreeItemDelegate {
                                id: delegate
                                width: treeView.width
                                
                                // Access ListModel properties directly - they're available in delegate scope
                                property var modelRow: treeModel.get(index)
                                
                                // Pass them to TreeItemDelegate properties using the model row
                                itemData: modelRow ? modelRow.itemData : null
                                level: modelRow ? modelRow.level : 0
                                hasChildren: modelRow ? modelRow.hasChildren : false
                                isExpanded: modelRow ? modelRow.isExpanded : false
                                isLastChild: modelRow ? modelRow.isLastChild : false
                                isSelected: root.selectedPath && modelRow && root.selectedPath === modelRow.path
                                // Check if this is the first top-level item (path === "0")
                                isFirstTopLevel: modelRow && modelRow.level === 0 && modelRow.path === "0"
                                onSelected: {
                                    // Store direct reference to item in menuData and path
                                    if (modelRow && modelRow.itemData) {
                                        root.selectedItem = modelRow.itemData;
                                        root.selectedPath = modelRow.path || "";
                                    }
                                }
                                onToggleExpanded: {
                                    if (modelRow && modelRow.itemData && modelRow.path) {
                                        // Use the model row's isExpanded property directly
                                        const currentExpanded = modelRow.isExpanded;
                                        root.setItemExpanded(modelRow.itemData, !currentExpanded, modelRow.path);
                                        root.rebuildTreeModel();
                                        // Restore selection after rebuild
                                        if (root.selectedPath) {
                                            Qt.callLater(() => {
                                                const restoredItem = root.findItemByPath(root.selectedPath);
                                                if (restoredItem) {
                                                    root.selectedItem = restoredItem;
                                                }
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Right pane: Editor
            QQC2.Frame {
                Layout.fillHeight: true
                Layout.fillWidth: true

                QQC2.ScrollView {
                    id: scrollView
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    anchors.topMargin: Kirigami.Units.mediumSpacing

                    Kirigami.FormLayout {
                        id: formLayout
                        width: scrollView.contentItem ? scrollView.contentItem.width : parent.width
                        enabled: root.selectedItem !== null

                        QQC2.Label {
                            text: i18n("No item selected")
                            visible: root.selectedItem === null
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        QQC2.Label {
                            text: i18n("Separator selected")
                            visible: root.selectedItem !== null && root.selectedItem.hasOwnProperty("separator") && root.selectedItem.separator === true
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        RowLayout {
                            Kirigami.FormData.label: i18n("Name:")
                            Layout.fillWidth: true
                            visible: root.selectedItem !== null && !root.selectedItem.separator
                            enabled: root.selectedItem !== null && !root.selectedItem.separator
                            
                            QQC2.TextField {
                                id: nameField
                                Layout.fillWidth: true
                                
                                Component.onCompleted: updateText()
                                
                                function updateText() {
                                    if (root.selectedItem && !root.selectedItem.separator) {
                                        text = root.selectedItem.name || "";
                                    } else {
                                        text = "";
                                    }
                                }
                                
                                onTextChanged: {
                                    if (root.selectedItem && root.selectedPath && text !== (root.selectedItem.name || "")) {
                                        root.selectedItem.name = text;
                                        root.updateItemInMenuData(root.selectedPath, "name", text);
                                        root.updateJson();
                                        // Refresh tree to show updated name
                                        const savedPath = root.selectedPath;
                                        Qt.callLater(() => {
                                            root.rebuildTreeModel();
                                            // Restore selection after rebuild
                                            if (savedPath) {
                                                const restoredItem = root.findItemByPath(savedPath);
                                                if (restoredItem) {
                                                    root.selectedItem = restoredItem;
                                                    root.selectedPath = savedPath;
                                                    nameField.updateText();
                                                }
                                            }
                                        });
                                    }
                                }
                                
                                Connections {
                                    target: root
                                    function onSelectedItemChanged() {
                                        nameField.updateText();
                                    }
                                }
                            }

                            QQC2.Button {
                                id: iconButton
                                Layout.alignment: Qt.AlignVCenter
                                
                                implicitWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
                                height: nameField.height
                                
                                checkable: true
                                
                                onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()
                                
                                icon.name: {
                                    if (root.selectedItem && !root.selectedItem.separator) {
                                        return root.selectedItem.icon || "";
                                    }
                                    return "";
                                }
                                
                                KIconThemes.IconDialog {
                                    id: iconDialog
                                    
                                    onIconNameChanged: (iconName) => {
                                        if (iconName != "" && root.selectedItem && root.selectedPath) {
                                            root.selectedItem.icon = iconName;
                                            root.updateItemInMenuData(root.selectedPath, "icon", iconName);
                                            root.updateJson();
                                            // Refresh tree to show updated icon
                                            const savedPath = root.selectedPath;
                                            Qt.callLater(() => {
                                                root.rebuildTreeModel();
                                                // Restore selection after rebuild
                                                if (savedPath) {
                                                    const restoredItem = root.findItemByPath(savedPath);
                                                    if (restoredItem) {
                                                        root.selectedItem = restoredItem;
                                                        root.selectedPath = savedPath;
                                                    }
                                                }
                                            });
                                        }
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
                                            if (root.selectedItem && root.selectedPath) {
                                                root.selectedItem.icon = "";
                                                root.updateItemInMenuData(root.selectedPath, "icon", "");
                                                root.updateJson();
                                                // Refresh tree to show updated icon
                                                const savedPath = root.selectedPath;
                                                Qt.callLater(() => {
                                                    root.rebuildTreeModel();
                                                    // Restore selection after rebuild
                                                    if (savedPath) {
                                                        const restoredItem = root.findItemByPath(savedPath);
                                                        if (restoredItem) {
                                                            root.selectedItem = restoredItem;
                                                            root.selectedPath = savedPath;
                                                        }
                                                    }
                                                });
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            id: commandFieldContainer
                            Kirigami.FormData.label: i18n("Command:")
                            Layout.fillWidth: true
                            
                            // Get fresh reference to selected item to ensure submenu property is available
                            property var currentItem: root.selectedPath ? root.findItemByPath(root.selectedPath) : null
                            
                            property bool isParent: {
                                if (!currentItem) return false;
                                const hasSubmenu = currentItem.hasOwnProperty('submenu') && 
                                                  currentItem.submenu !== undefined && 
                                                  currentItem.submenu !== null && 
                                                  Array.isArray(currentItem.submenu);
                                return hasSubmenu;
                            }
                            
                            visible: {
                                if (!root.selectedItem || !root.selectedPath) return false;
                                if (currentItem && currentItem.separator === true) return false;
                                return !isParent;
                            }
                            enabled: visible
                            
                            implicitWidth: Kirigami.Units.gridUnit * 25
                            implicitHeight: Kirigami.Units.gridUnit * 6
                            height: implicitHeight
                            
                            QQC2.ScrollView {
                                anchors.fill: parent
                                clip: true
                                
                                QQC2.TextArea {
                                    id: commandField
                                    width: commandFieldContainer.width
                                    
                                    wrapMode: TextArea.Wrap
                                    selectByMouse: true
                                    
                                    onTextChanged: {
                                        if (commandFieldContainer.currentItem && root.selectedPath && text !== (commandFieldContainer.currentItem.command || "")) {
                                            // Only update if not a parent item
                                            if (!commandFieldContainer.isParent) {
                                                commandFieldContainer.currentItem.command = text;
                                                root.updateItemInMenuData(root.selectedPath, "command", text);
                                                root.updateJson();
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Component.onCompleted: updateText()
                            
                            function updateText() {
                                if (currentItem && !currentItem.separator && !isParent) {
                                    commandField.text = currentItem.command || "";
                                } else {
                                    commandField.text = "";
                                }
                            }
                            
                            Connections {
                                target: root
                                function onSelectedItemChanged() {
                                    commandFieldContainer.updateText();
                                }
                                function onSelectedPathChanged() {
                                    commandFieldContainer.updateText();
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    ListModel {
        id: treeModel
    }

}

