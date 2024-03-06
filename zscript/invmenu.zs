class InvMenuHandler : WRZFHandler {
    // The model for the inventory menu contains:
    // - Methods for changing a weapon's slotnumber, so that you can equip weapons to different slots.
    // - Methods for adding a modcont to a weapon. (This is supported by a function on the weapon.)

    // - A selector for the 'current' weapon and 'current' modcont.
    int sweapon;
    int sequipped;
    int smod;
    WRZFRadioController selmod;
    // - Page selectors for the weapon/modcont lists. You should be able to view 10 of these at a time, I think.
    int pageweapon;
    int pagemod;

    InvMenuView view;

    override void buttonClickCommand(WRZFButton caller, Name cmd) {
        ParseCommand(cmd);
    }

    void ParseCommand(String cmd) {
        console.printf("Received command %s",cmd);
        Array<String> args;
        cmd.split(args,";");
        if (args[0] == "weapon") {
            sweapon = args[1].toInt();
        }
        
        if (args[0] == "modpage") {
            pagemod += args[1].toInt();
            // pagemod = clamp(pagemod,0,max(0,mods.size() - 10));
        }
        if (args[0] == "weppage") {
            pageweapon += args[1].toInt();
            // pageweapon = clamp(pagemod,0,max(0,mods.size() - 10));
        }

        if (args[0] == "modequip") {
            // TODO: Mod swapping.
            EventHandler.SendNetworkEvent("modequip",sweapon,selmod.curval,args[1].toInt());
            view.dirty = true;
        }
        if (args[0] == "modremove") {
            EventHandler.SendNetworkEvent("modremove",sweapon,args[1].toInt());
            view.dirty = true;
        }
    }

    void Init() {
        sweapon = -1; // -1 means no selection.
        smod = -1;
        sequipped = -1;
        selmod = new("WRZFRadioController");
        selmod.curVal = -1;
        pageweapon = 0;
        pagemod = 0;
        // Populate the weapon, mod, and equipped lists.
        // PopModList("WRModContainer",mods);
        // PopWepList("WRWeapon",weapons,equipped);
        // We use the inv handler instead.
    }
}

class InvEventHandler : EventHandler {
    // Parses netevents to move items around, because you're not allowed to do that in UI scope.
    override void NetworkProcess(ConsoleEvent e) {
        // TODO: move mod equip/dequip logic here.
        if (e.name == "invmenustart") {
            console.printf("Received invmenustart");
            let plr = players[e.player].mo;
            InvManager im = InvManager(plr.FindInventory("InvManager"));
            im.poplists();
        }
        if (e.name == "modequip") {
            console.printf("Received modequip");
            let plr = players[e.player].mo;
            InvManager im = InvManager(plr.FindInventory("InvManager"));
            im.EquipModToWeapon(e.args[0],e.args[1],e.args[2]);
        }
        if (e.name == "modremove") {
            console.printf("Received modremove");
            let plr = players[e.player].mo;
            InvManager im = InvManager(plr.FindInventory("InvManager"));
            im.RemoveModFromWeapon(e.args[0],e.args[1]);
        }
    }
}

class InvManager : Inventory {
    // Thank you to Jarewill's DWELLING SIN and its inventory implementation for this idea.
    Array<WRWeapon> weapons;
    Array<WRWeapon> equipped;
    Array<WRModContainer> mods;

    void PopLists() {
        weapons.clear();
        equipped.clear();
        let inv = owner.inv;
        console.printf("-- INIT INVMANAGER --");
        while (inv) {
            console.printf(inv.GetTag());
            if (inv.amount > 0) {
                if (inv is "WRWeapon") weapons.push(WRWeapon(inv));
            }
            inv = inv.inv;
        }
    }

    void DeleteMod(int index) {
        // Remove a mod from the list.
        WRModContainer m = mods[index];
        mods.delete(index);
        // m.amount = 0; // Gross hax: mods are never actually removed from the inventory, their amount is just set to zero
    }

    void AddMod(WRModContainer mod) {
        // Adds a mod to the list, presumably because it was unequipped from a weapon.
        // Also adds that mod into the player's inventory. 
        // TODO: decide if I even want the mods to go into the regular player inventory.
        mod.CallTryPickup(owner);
        // mods.push(mod);
    }

    override bool HandlePickup(Inventory item) {
        // When mods are added to the inventory, add them to the list!
        if (item is "WRModContainer") {
            mods.push(WRModContainer(item.CreateCopy(owner))); // No idea why THIS is what works.
        }

        return super.HandlePickup(item);
    }

    void EquipModToWeapon(int sweapon, int smod, int modslot) {
        // Check if the weapon can accept a mod at the given slot.
        // Then, delete the selected mod from the modlist, and insert it into that weapon's mod slot.
        if (smod < 0) { return; } // No mod selected.
        if (sweapon < 0) { return; } // No weapon selected.
        if (modslot < 0 || modslot > 2) { return; } // Weapons only have 3 mod slots.
        console.printf("Called EquipModToWeapon(%d,%d,%d)",sweapon,smod,modslot);
        WRWeapon wep = weapons[sweapon];
        WRModContainer mod = mods[smod];
        if (wep.EquipMod(mod,modslot)) {
            Deletemod(smod);
        }
    }

    void RemoveModFromWeapon(int sweapon, int modslot) {
        if (sweapon < 0) { return; } // No weapon selected.
        if (modslot < 0 || modslot > 2) { return; } // Weapons only have 3 mod slots.
        // Check if the weapon has a mod in that slot.
        console.printf("Called RemoveModFromWeapon(%d,%d)",sweapon,modslot);
        WRWeapon wep = weapons[sweapon];
        // Then, remove the mod from that slot--replacing that slot with null
        WRModContainer mod = wep.RemoveMod(modslot);
        if (mod) {
            // Add the mod into the player's inventory.
            AddMod(mod);
        }
    }

    void GenerateMod(Class<WRModContainer> type) {
        // Creates and adds a mod of the given type.
    }
}

class InvMenuView : WRZFGenericMenu {
    // The view for the inventory menu contains:
    // - Clicking on a weapon should select it, displaying its mods.
    // - Clicking on a mod should select it.
    // - With a weapon and a mod selected, the weapon's mod slots should then appear.
    // - Empty slots become buttons to install the mod.
    // - Filled slots become buttons to start removing the mod. Clicking reveals the actual remove button under the cursor.

    const padding = 2;
    const itemsizex = 480;
    const itemsizey = 64;
    vector2 baseres;

    InvMenuHandler handler;
    InvManager manager;
    WRZFFrame modframe;
    WRZFFrame wepframe;
    WRZFFrame modequipframe;
    Array<WRZFImage> modequipicons; // Kinda gross, but...
    Array<WRZFButton> modequipbtns;
    WRZFBoxTextures btex;
    WRZFBoxTextures btex2;

    bool dirty; // if true: init the mod and weapon lists again.

    void CreateItemList(in Array<Object> list,WRZFFrame listframe,ItemUIBuilder builder) {
        for (int i = 0; i < list.size(); i++) {
            console.printf(list[i].getclassname());
            builder.Build(Actor(list[i]),listframe,handler,i,btex2,btex2,btex,btex);
        }
    }

    void SetupListFrame(in out WRZFFrame listframe, in Array<Object> list, WRZFFrame parent,Vector2 pos, String pageprefix) {
        int listlen = max(640,list.size() * (itemsizey + padding));
        listframe = WRZFListFrame.Create(pos,(itemsizex,listlen),2.0);
        listframe.pack(parent);
        // Page buttons.
        WRZFButton.Create (
            (pos.x+itemsizex+(2 * padding),pos.y + padding),
            (16,32),
            text: "^",
            cmdHandler: handler,
            command: pageprefix .. "page;-1",
            inactive:btex,
            hover:btex,
            click:btex2,
            textScale: 2
        ).pack(mainFrame);
        WRZFButton.Create (
            (pos.x+itemsizex+(2 * padding),baseres.y - (32 + padding)),
            (16,32),
            text: "V",
            cmdHandler: handler,
            command: pageprefix .. "page;1",
            inactive:btex,
            hover:btex,
            click:btex2,
            textScale: 2
        ).pack(mainFrame);
    }

    void InitModList() {
        // May have to be called again because the mod list changed.
        Array<Object> temp;
        foreach (i : manager.mods) {
            temp.push(i);
        }
        SetupListFrame(modframe,temp,mainframe,(4,4),"mod");
        CreateItemList(temp ,modframe,new("ModUIBuilder"));
    }

    void InitWeaponList() {
        Array<object> weapons;
        foreach (i : manager.weapons) {
            weapons.push(i);
        }
        SetupListFrame(wepframe,weapons,mainframe,(512,4),"wep");
        CreateItemList(weapons ,wepframe,new("WeaponUIBuilder"));
        // Also add a hidden-by-default frame for mods on a weapon.
        modequipframe = WRZFFrame.Create((0,itemsizey * 0.5),(itemsizex,itemsizey * 0.5));
        modequipframe.setHidden(true);
        modequipframe.setDisabled(true);
        modequipframe.pack(wepframe);
        // Inside modequipframe, there are three buttons.
        for (int i = 0; i < 3; i++) {
            vector2 btnpos = (itemsizex * 0.25 + (itemsizex * 0.25 * i),itemsizey * 0.25);
            vector2 btnsize = (itemsizey * 0.25,itemsizey * 0.25);
            WRZFButton modbutton = WRZFButton.Create(
                btnpos, btnsize,
                "+",
                cmdHandler: handler,
                command: "modequip;" .. i,
                inactive: btex2,
                hover: btex,
                click: btex2,
                disabled: btex
            );
            modbutton.pack(modequipframe);
            WRZFImage modimg = WRZFImage.Create(btnpos,btnsize); // Empty until we know what mods are in it.
            modimg.pack(modequipframe);
            modequipicons.push(modimg);
            modequipbtns.push(modbutton);
        }
    }

    override void Init( Menu parent ) {
        Super.Init(parent);
        handler = new ("InvMenuHandler");
        handler.view = self;
        handler.init();

        manager = InvManager(players[consoleplayer].mo.FindInventory("InvManager"));
        EventHandler.SendNetworkEvent("invmenustart"); // Because we're not allowed to just call shit directly...

        baseres = (1280,960);
        setBaseResolution(baseres);

        btex = WRZFBoxTextures.CreateTexturePixels (
            "graphics/BBOX.png",
            (2,2),
            (6,6),
            false,
            false
        );

        btex2 = WRZFBoxTextures.CreateTexturePixels (
            "graphics/BBOX2.png",
            (2,2),
            (6,6),
            false,
            false
        );

        // Background.
        int padding = 4;
        vector2 bgpos = (padding/2,padding/2);
        vector2 bgsize = (baseres.x-padding,baseres.y-padding);

        let bg = WRZFBoxImage.Create (
            bgpos,
            bgsize,
            btex,
            (1,1)
        );

        bg.setDontBlockMouse(true);
        bg.pack(mainFrame);
        dirty = true;
    }

    override void ticker() {
        if (dirty) {
            InitModList();
            InitWeaponList();
            dirty = false;
        }
        // Move the different list frames according to their page.
        modframe.SetPosY(4 - ((itemsizey + padding) * handler.pagemod));
        wepframe.SetPosY(4 - ((itemsizey + padding) * handler.pageweapon));
        // Is a weapon currently selected?
        if (handler.sweapon >= 0) {
            // Move the modequipframe to the correct position.
            modequipframe.SetPosY((itemsizey * 0.25) + (itemsizey * handler.sweapon));
            // Unhide it.
            modequipframe.SetHidden(false);
            modequipframe.SetDisabled(false);
            // Set up the images.
            let w = WRWeapon(manager.weapons[handler.sweapon]);
            if (!w) { console.printf("Non-WRWeapon in weapons!"); return; }
            for(int i = 0; i < w.mods.size(); i++) {
                if (!w.mods[i]) { continue; }
                if (w.mods[i].icon) {
                    let tx = TexMan.GetName(w.mods[i].Icon);
                    modequipicons[i].SetImage(tx);
                    modequipbtns[i].SetCommand("modremove;" .. i);
                }
            }
        } else {
            modequipframe.SetHidden(true);
            modequipframe.SetDisabled(true);
        }
        super.Ticker();
    }
}

class WRZFRadioToggleButton : WRZFRadioButton {
    // Like a RadioButton, but you can click it again to unselect it.
    private bool click2; // WHY is EVERYTHING FUCKING PRIVATE
	private bool hover2;

	static WRZFRadioToggleButton create(
		Vector2 pos, Vector2 size,
		WRZFRadioController variable, int value,
		WRZFBoxTextures inactive = NULL, WRZFBoxTextures hover = NULL,
		WRZFBoxTextures click = NULL, WRZFBoxTextures disabled = NULL,
		string text = "", Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, WRZFHandler cmdHandler = NULL, Name command = ''
	) {
		let ret = new('WRZFRadioToggleButton');

		ret.config(variable, value, inactive, hover, click, disabled, text, fnt, textScale, textColor, alignment, cmdHandler, command);
		ret.setBox(pos, size);

		return ret;
	}

    override void Activate() {
        if (getVariable().curVal != getValue()) {
            console.printf("Turning on.");
            super.Activate();
        } else {
            // Deselect this item.
            getVariable().curVal = -1;
            console.printf("Turning off.");
            if (cmdHandler != NULL) {
                cmdHandler.radioButtonChanged(self, command, getVariable());
            }
        }
    }

	override bool onNavEvent(WRZFNavEventType type, bool fromController) {
        if (getVariable().curVal != getValue()) {
            console.printf("Turning on.");
            super.OnNavEvent(type,fromController);
            return true;
        } else {
            // Deselect this item.
            getVariable().curVal = -1;
            console.printf("Turning off.");
            if (cmdHandler != NULL) {
                cmdHandler.radioButtonChanged(self, command, getVariable());
            }
            return true;
        }
        return false;
    }

    override bool onUIEvent(WRZFUiEvent ev) {
		// if the player's clicked, and their mouse is in the right place, set the state accordingly
		if (ev.type == UIEvent.Type_LButtonDown) {
			let mousePos = getGlobalStore().mousePos;
			WRZFAABB screenBox; boxToScreen(screenBox);
			if (!mouseBlock && isEnabled() && screenBox.pointCollides(mousePos)) {
				click2 = true;
				setHoverBlock(self);
			}
		}
		// if the player's releasing, check if their mouse is still in the correct range and trigger method if it was
		else if (ev.type == UIEvent.Type_LButtonUp) {
			if (isEnabled()) {
				let mousePos = getGlobalStore().mousePos;
				WRZFAABB screenBox; boxToScreen(screenBox);
				if (screenBox.pointCollides(mousePos) && click2) {
                    Activate();
				}
				click2 = false;
				setHoverBlock(NULL);
			}
		}
		// if the player's mouse has moved, update the tracked position and do a quick hover check
		return false;
	}
}