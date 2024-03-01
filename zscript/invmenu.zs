class InvMenuHandler : WRZFHandler {
    // The model for the inventory menu contains:
    // - Methods for changing a weapon's slotnumber, so that you can equip weapons to different slots.
    // - Methods for adding a modcont to a weapon. (This is supported by a function on the weapon.)

    // - An array of weapons and an array of mods. This can be constructed when the menu opens.
    // The array of mods may change due to the player generating a new mod. 
    // The array of weapons *SHOULD* be static once it's generated.
    Array<WRWeapon> weapons;
    Array<WRModContainer> mods;
    // - While building the weapons array, check the slot numbers to fill out a 'currently equipped' list.
    Array<WRWeapon> equipped;

    // - A selector for the 'current' weapon and 'current' modcont.
    int sweapon;
    WRZFRadioController selweapon;
    int sequipped;
    WRZFRadioController selequipped;
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
        
        if (args[0] == "mod") {
            smod = args[1].toInt();
        }

        if (args[0] == "modpage") {
            pagemod += args[1].toInt();
            pagemod = clamp(pagemod,0,max(0,mods.size() - 10));
        }
    }

    void PopModList(Class filter, out Array<WRModContainer> items) {
        let plr = players[consoleplayer].mo;
        let inv = plr.inv;
        while (inv) {
            if(inv is filter) {
                items.push(WRModContainer(inv));
            }
            inv = inv.inv;
        }
    }

    void PopWepList(Class filter, out Array<WRWeapon> items, out Array<WRWeapon> equips) {
        let plr = players[consoleplayer].mo;
        let inv = plr.inv;
        while (inv) {
            if(inv is filter) {
                items.push(WRWeapon(inv));
                if (WRWeapon(inv).slotnumber) {
                    // This item is equipped.
                    equips.push(WRWeapon(inv));
                }
            }
            inv = inv.inv;
        }
    }

    void Init() {
        sweapon = -1; // -1 means no selection.
        smod = -1;
        sequipped = -1;
        selweapon = new("WRZFRadioController");
        selweapon.curVal = -1;
        selequipped = new("WRZFRadioController");
        selequipped.curVal = -1;
        selmod = new("WRZFRadioController");
        selmod.curVal = -1;
        pageweapon = 0;
        pagemod = 0;
        // Populate the weapon, mod, and equipped lists.
        PopModList("WRModContainer",mods);
        PopWepList("WRWeapon",weapons,equipped);

    }
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

    const padding = 2;
    const itemsizex = 480;
    const itemsizey = 64;

    InvMenuHandler handler;
    WRZFFrame modframe;

    override void Init( Menu parent ) {
        Super.Init(parent);
        handler = new ("InvMenuHandler");
        handler.view = self;
        handler.init();

        vector2 baseres = (1280,960);
        setBaseResolution(baseres);

        let btex = WRZFBoxTextures.CreateTexturePixels (
            "graphics/BBOX.png",
            (2,2),
            (6,6),
            false,
            false
        );

        let btex2 = WRZFBoxTextures.CreateTexturePixels (
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


        // Let's start simple: the list of mods in your inventory.
        int modlistlength = max(640,handler.mods.size() * (itemsizey + padding));
        modframe = WRZFListFrame.Create((4,4),(480,modlistlength),2.0);
        // modframe.setDontBlockMouse(true);
        modframe.pack(mainFrame);
        for (int i = 0; i < handler.mods.Size(); i++) {
            if (i >= handler.mods.Size()) { break; }
            WRZFFrame itemframe = WRZFFrame.Create((0,0),(itemsizex,itemsizey));
            // itemframe.setDontBlockMouse(true);
            itemframe.pack(modframe);
            let tx = TexMan.GetName(handler.mods[i].Icon);
            int sizex, sizey;
            [sizex,sizey] = TexMan.GetSize(handler.mods[i].Icon);
            vector2 size = (sizex,sizey);
            Vector2 btnsize = (itemsizex,itemsizey);
            Vector2 pos = (0,0);
            let ibtn = WRZFRadioToggleButton.Create (
                pos,
                btnsize,
                handler.selmod,
                i,
                inactive: btex2,
                hover: btex2,
                click: btex,
                disabled: btex,
                cmdHandler: handler,
                command: "mod;" .. i
            );

            ibtn.pack(itemframe);
            let modicon = WRZFImage.Create((12,24),size*2,tx,imageScale:(2,2));
            // modicon.setDontBlockMouse(true);
            modicon.pack(itemframe);
            let modname = WRZFLabel.Create((1,1),btnsize,text:String.Format("%s",handler.mods[i].GetTag()),autosize:true);
            // modname.setDontBlockMouse(true);
            modname.pack(itemframe);
            for (int j = 0; j < handler.mods[i].modlist.size(); j++) {
                let m = handler.mods[i].modlist[j];
                let affixdesc = WRZFLabel.Create((48,9 + (9 * j)),btnsize,text:m.GetTag(),autosize:true);
                // affixdesc.setDontBlockMouse(true);
                affixdesc.pack(itemframe);
            }
        }
        // Buttons for paging.
        WRZFButton.Create (
            (2,baseres.y - 32),
            (64,32),
            text: "<==",
            cmdHandler: handler,
            command: "modpage;-1",
            inactive:btex,
            hover:btex,
            click:btex2,
            textScale: 2
        ).pack(mainFrame);
        WRZFButton.Create (
            (480 - 64,baseres.y - 32),
            (64,32),
            text: "==>",
            cmdHandler: handler,
            command: "modpage;1",
            inactive:btex,
            hover:btex,
            click:btex2,
            textScale: 2
        ).pack(mainFrame);
    }

    override void ticker() {
        modframe.SetPosY(4 - ((itemsizey + padding) * handler.pagemod));
        super.Ticker();
    }
}

class WRZFRadioToggleButton : WRZFRadioButton {
    // Like a RadioButton, but you can click it again to unselect it.
    private bool click2; // WHY is EVERYTHING FUCKING PRIVATE
	private bool hover2;

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