class InvMenuHandler : WRZFHandler {
    // The model for the inventory menu contains:
    // - An array of weapons and an array of mods. This can be constructed when the menu opens.
    // The array of mods may change due to the player generating a new mod. 
    // The array of weapons *SHOULD* be static once it's generated.
    // - Page selectors for the weapon/modcont lists. You should be able to view 10 of these at a time, I think.
    // - While building the weapons array, check the slot numbers to fill out a 'currently equipped' list.
    // - Methods for changing a weapon's slotnumber, so that you can equip weapons to different slots.
    // - Methods for adding a modcont to a weapon. (This is supported by a function on the weapon.)
    // - A selector for the 'current' weapon and 'current' modcont.

    Array<WRWeapon> weapons;
    Array<WRModContainer> mods;
}

class InvMenuView : WRZFGenericMenu {
    // The view for the inventory menu contains:
    // - A list of weapons.
    // - A list of mods.
    // - A list of weapons that are currently equipped.
    // - Clicking on a weapon should select it, displaying its mods.
    // - Clicking on a mod should select it.
    // - With a weapon and a mod selected, the weapon's mod slots should then appear.
    // - Empty slots become buttons to install the mod.
    // - Filled slots become buttons to start removing the mod. Clicking reveals the actual remove button under the cursor.
}