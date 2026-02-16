pragma ComponentBehavior: Bound

import QtQuick
import QtQml

import org.kde.plasma.private.kicker as Kicker

/**
 * JsonMenuModel - Data model that converts JSON menu configuration into a ListModel
 * 
 * This component is the core data layer for the JSON-based menu system. It:
 * 
 * 1. Parses the JSON menu data from Plasmoid.configuration.menuJson
 * 2. Converts the JSON into a ListModel that ItemListView can display
 * 3. Handles nested submenus by creating child models dynamically
 * 4. Executes commands when menu items are clicked (via the trigger function)
 * 5. Manages separators, icons, and other menu item properties
 * 6. Menu order follows the JSON order (no alphabetical sorting)
 * 
 * Used in main.qml as rootModel, which is passed to MenuRepresentation and then
 * to ItemListView to display the menu. Without this component, the menu would
 * not work - it's the bridge between JSON configuration and the UI.
 */
ListModel {
    id: root

    property string jsonData: ""
    property bool sorted: false
    property var executable: null
    property var _submenuCache: ({}) // Cache submenu items by index

    signal refreshed()

    function refresh() {
        root.clear();
        root._submenuCache = {}; // Clear cache
        if (!jsonData || jsonData === "") {
            refreshed();
            return;
        }

        try {
            const menuItems = JSON.parse(jsonData);
            populateModel(menuItems, root);
            refreshed();
        } catch (e) {
            console.error("JsonMenuModel: Error parsing menu JSON:", e);
            refreshed();
        }
    }

    function populateModel(items, parentModel) {
        if (!Array.isArray(items)) {
            return;
        }
        if (!parentModel) {
            return;
        }

        items.forEach((item, index) => {
            if (item.separator) {
                parentModel.append({
                    display: "",
                    decoration: "",
                    url: "",
                    isSeparator: true,
                    hasChildren: false,
                    isParent: false,
                    disabled: false,
                    description: "",
                    model: {}
                });
            } else {
                const hasSubmenu = item.submenu && Array.isArray(item.submenu) && item.submenu.length > 0;
                const command = item.command || "";
                const url = command ? ("file://" + command) : "";
                const submenuItems = item.submenu || [];
                
                // Store submenu items in cache for later retrieval
                if (parentModel === root && hasSubmenu) {
                    root._submenuCache[parentModel.count] = submenuItems;
                }
                
                parentModel.append({
                    display: item.name || "",
                    decoration: item.icon || "",
                    url: url,
                    isSeparator: false,
                    hasChildren: hasSubmenu,
                    isParent: hasSubmenu,
                    disabled: item.disabled || false,
                    description: item.description || item.name || "",
                    command: command,
                    submenuItems: submenuItems, // Store in model item too (might not be accessible)
                    model: {
                        display: item.name || "",
                        description: item.description || item.name || ""
                    }
                });
            }
        });
    }

    // Helper function to execute commands - accessible from submenu models via root
    function executeCommand(cmd) {
        if (executable && typeof executable.exec === 'function') {
            executable.exec(String(cmd));
            return true;
        }
        console.error("JsonMenuModel.executeCommand: executable not available");
        return false;
    }

    function createSubMenuModel(submenuItems, parentExecutable) {
        // Create a cache for this submodel's submenu items
        const submenuCache = {};
        
        const subModel = Qt.createQmlObject(`
            import QtQuick
            import QtQml
            ListModel {
                property var executable: null
                property bool sorted: false
                property var _submenuCache: ({})
                
                function trigger(index, actionId, actionArgument) {
                    if (index < 0 || index >= count) {
                        return false;
                    }
                    const item = get(index);
                    if (item.isSeparator || item.disabled || item.hasChildren) {
                        return false;
                    }
                    if (item.command && executable && typeof executable.exec === 'function') {
                        executable.exec(String(item.command));
                        return true;
                    }
                    return false;
                }
                
                function modelForRow(index) {
                    if (index < 0 || index >= count) {
                        return null;
                    }
                    const item = get(index);
                    if (!item.hasChildren) {
                        return null;
                    }
                    // Get submenuItems from cache first, then try item directly
                    let submenuItems = _submenuCache[index];
                    if (!submenuItems) {
                        submenuItems = item.submenuItems;
                    }
                    if (!submenuItems || !Array.isArray(submenuItems) || submenuItems.length === 0) {
                        return null;
                    }
                    // For nested submenus, recursively call the parent's createSubMenuModel
                    const execToPass = executable || (root && root.executable ? root.executable : null);
                    if (root && root.createSubMenuModel) {
                        return root.createSubMenuModel(submenuItems, execToPass);
                    }
                    return null;
                }
            }
        `, root);
        
        // Set properties with error handling
        // Assign executable property
        try {
            if (parentExecutable) {
                subModel.executable = parentExecutable;
            } else if (root.executable) {
                subModel.executable = root.executable;
            }
        } catch (e) {
            console.error("JsonMenuModel.createSubMenuModel: Cannot assign executable:", e);
        }
        try {
            subModel.sorted = root.sorted;
        } catch (e) {
            console.error("JsonMenuModel.createSubMenuModel: Cannot assign sorted:", e);
        }
        
        // Populate the model directly in the createSubMenuModel function
        if (Array.isArray(submenuItems)) {
            submenuItems.forEach((item, index) => {
                if (item.separator) {
                    subModel.append({
                        display: "",
                        decoration: "",
                        url: "",
                        isSeparator: true,
                        hasChildren: false,
                        isParent: false,
                        disabled: false,
                        description: "",
                        model: {}
                    });
                } else {
                    const hasSubmenu = item.submenu && Array.isArray(item.submenu) && item.submenu.length > 0;
                    const command = item.command || "";
                    const url = command ? ("file://" + command) : "";
                    const itemSubmenuItems = item.submenu || [];
                    
                    // Store submenu items in cache for later retrieval
                    if (hasSubmenu) {
                        submenuCache[subModel.count] = itemSubmenuItems;
                    }
                    
                    // Ensure hasChildren is explicitly a boolean
                    const hasChildrenValue = Boolean(hasSubmenu);
                    const isParentValue = Boolean(hasSubmenu);
                    
                    subModel.append({
                        display: item.name || "",
                        decoration: item.icon || "",
                        url: url,
                        isSeparator: false,
                        hasChildren: hasChildrenValue,
                        isParent: isParentValue,
                        disabled: Boolean(item.disabled || false),
                        description: item.description || item.name || "",
                        command: command,
                        submenuItems: itemSubmenuItems, // Store in model item too (might not be accessible)
                        model: {
                            display: item.name || "",
                            description: item.description || item.name || ""
                        }
                    });
                }
            });
        }
        
        // Assign the cache to the submodel
        try {
            subModel._submenuCache = submenuCache;
        } catch (e) {
            console.error("JsonMenuModel.createSubMenuModel: Cannot assign _submenuCache:", e);
        }
        
        return subModel;
    }

    function modelForRow(index) {
        if (index < 0 || index >= root.count) {
            return null;
        }

        const item = root.get(index);
        
        if (!item.hasChildren) {
            return null;
        }

        // Get submenuItems from cache (since ListModel might not preserve arbitrary properties)
        let submenuItems = root._submenuCache[index];
        if (!submenuItems) {
            // Fallback: try to get from item directly
            if (item.submenuItems) {
                submenuItems = item.submenuItems;
            } else {
                // Last resort: parse JSON again to get submenu items
                try {
                    const menuItems = JSON.parse(root.jsonData);
                    if (Array.isArray(menuItems) && index < menuItems.length) {
                        const jsonItem = menuItems[index];
                        if (jsonItem && jsonItem.submenu) {
                            submenuItems = jsonItem.submenu;
                        }
                    }
                } catch (e) {
                    console.error("JsonMenuModel.modelForRow: Error parsing JSON:", e);
                }
            }
        }
        
        if (!submenuItems || !Array.isArray(submenuItems) || submenuItems.length === 0) {
            return null;
        }

        const subModel = createSubMenuModel(submenuItems, executable);
        
        return subModel;
    }

    function trigger(index, actionId, actionArgument) {
        if (index < 0 || index >= root.count) {
            return false;
        }

        const item = root.get(index);
        if (item.isSeparator || item.disabled) {
            return false;
        }

        if (item.hasChildren) {
            // Has submenu, don't close
            return false;
        }

        if (item.command && executable) {
            executable.exec(String(item.command));
            return true;
        }

        return false;
    }

    function labelForRow(index) {
        if (index < 0 || index >= root.count) {
            return "";
        }
        return root.get(index).display;
    }

    onJsonDataChanged: {
        refresh();
    }

    Component.onCompleted: {
        refresh();
    }
}

