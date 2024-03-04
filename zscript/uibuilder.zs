class ItemUIBuilder {
    // Builds a Frame for an actor.
    // Generally speaking, you should be inheriting from this and creating a more specific version.
    virtual ui void Build(Actor item, WRZFFrame parent, WRZFHandler handler, int ival,
        WRZFBoxTextures inactive = null,WRZFBoxTextures hover = null,
        WRZFBoxTextures click = null,WRZFBoxTextures disabled = null
    ) {}
    // This function should build a frame, packing it into parent, using details of item.
}

class ModUIBuilder : ItemUIBuilder {
    const itemsizex = 480;
    const itemsizey = 64;
    override void Build(Actor item, WRZFFrame parent, WRZFHandler handler, int ival,
        WRZFBoxTextures inactive,WRZFBoxTextures hover,
        WRZFBoxTextures click,WRZFBoxTextures disabled
    ) {
        WRModContainer container = WRModContainer(item);
        if (!container) { return; }
        InvMenuHandler h = InvMenuHandler(handler);
        if (!h) { return; } // H!
        WRZFFrame itemframe = WRZFFrame.Create((0,0),(itemsizex,itemsizey));
        itemframe.pack(parent);
        let tx = TexMan.GetName(container.Icon);
        int sizex, sizey;
        [sizex,sizey] = TexMan.GetSize(container.Icon);
        vector2 size = (sizex,sizey);
        Vector2 btnsize = (itemsizex,itemsizey);
        Vector2 pos = (0,0);
        let ibtn = WRZFRadioToggleButton.Create (
            pos,
            btnsize,
            h.selmod,
            ival,
            inactive: inactive,
            hover: hover,
            click: click,
            disabled: disabled,
            cmdHandler: h,
            command: "mod;" .. ival
        );

        ibtn.pack(itemframe);
        let modicon = WRZFImage.Create((12,24),size*2,tx,imageScale:(2,2));
        modicon.setDontBlockMouse(true);
        modicon.pack(itemframe);
        let modname = WRZFLabel.Create((1,1),btnsize,text:String.Format("%s",item.GetTag()),autosize:true);
        modname.setDontBlockMouse(true);
        modname.pack(itemframe);
        for (int j = 0; j < container.modlist.size(); j++) {
            let m = container.modlist[j];
            let affixdesc = WRZFLabel.Create((48,9 + (9 * j)),btnsize,text:m.GetTag(),autosize:true);
            affixdesc.setDontBlockMouse(true);
            affixdesc.pack(itemframe);
        }
    }
}

class WeaponUIBuilder : ItemUIBuilder {
    const itemsizex = 480;
    const itemsizey = 64;
    override void Build (Actor item, WRZFFrame parent, WRZFHandler handler, int ival,
        WRZFBoxTextures inactive,WRZFBoxTextures hover,
        WRZFBoxTextures click,WRZFBoxTextures disabled
    ) {
        // For now, these are regular buttons.
        WRWeapon wep = WRWeapon(item);
        if (!wep) { return; }
        InvMenuHandler h = InvMenuHandler(handler);
        if (!h) { return; } // H!
        WRZFFrame itemframe = WRZFFrame.Create((0,0),(itemsizex,itemsizey));
        itemframe.pack(parent);
        let tx = TexMan.GetName(wep.Icon);
        int sizex, sizey;
        [sizex,sizey] = TexMan.GetSize(wep.Icon);
        vector2 size = (sizex,sizey);
        Vector2 btnsize = (itemsizex,itemsizey);
        Vector2 pos = (0,0);
        let ibtn = WRZFButton.Create (
            pos,
            btnsize,
            cmdHandler: h,
            command: "weapon;" .. ival,
            inactive: inactive,
            hover: hover,
            click: click,
            disabled: disabled
        );
        ibtn.pack(itemframe);
        let wepicon = WRZFImage.Create((12,24),size*2,tx,imageScale:(2,2));
        wepicon.setDontBlockMouse(true);
        wepicon.pack(itemframe);
        let wepname = WRZFLabel.Create((1,1),btnsize,text:String.Format("%s",item.GetTag()),autosize:true);
        wepname.setDontBlockMouse(true);
        wepname.pack(itemframe);
    }
}