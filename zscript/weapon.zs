class WRWeapon : Weapon abstract {
    Array<WRModContainer> mods;
    Class<WRProj> proj; // What this thing fires.
    double projcountmin, projcountadd; // projectiles fired = projcountmin + frandom(0,projcountadd).
    // Note that partial amounts are effectively rounded up. TODO: decide if I wanna keep this behavior
    Property Projectile: proj;
    Property Shotcount: projcountmin, projcountadd;
    vector2 spread; // Base spread.
    vector2 spreadadd; // How much to add per projectile. 
    Property Spread: spread, spreadadd;
    // Note that this is calculated *PER PROJECTILE*, that is, the first proj has `spread` spread, the second has `spread+spreadadd`, the third has `spread+(2*spreadadd)`...
    // In other words, you can have a weapon with an extremely high base spread but very low additional spread per projectile, or vice versa.
    // Because these are both vectors, you can also have the weapon have different vertical and horizontal spread gain.

    default {
        WRWeapon.Spread (1,1), (0.1,0.2);
    }

    action void Fire(vector2 angofs = (0,0)) {
        if (invoker.DepleteAmmo(invoker.bALTFIRE)) {
            A_GunFlash();
            double shotcount = invoker.projcountmin + frandom(0,invoker.projcountadd); // TODO: allow mods to add projectile count.
            for (int i = 0; i < shotcount; i++) {
                double ang = invoker.spread.x + (i * frandom(-invoker.spreadadd.x,invoker.spreadadd.x)) + angofs.x;
                double pit = invoker.spread.y + (i * frandom(-invoker.spreadadd.y,invoker.spreadadd.y)) + angofs.y;
                Actor p1,p2;
                [p1,p2] = A_FireProjectile(invoker.proj.getclassname(),ang,false,pitch:pit);
                WRProj p = WRProj(p2);
                if (p) {
                    p.weapon = invoker; // Uses this to call on-hits.
                    invoker.CallOnFires(p);
                }
            }
        }
    }

    void CallOnFires(WRProj fired) {
        foreach (container : mods) {
            foreach (m : container.modlist) {
                m.OnFire(fired);
            }
        }
    }

    void CallOnHits(WRProj impact) {
        foreach (container : mods) {
            foreach (m : container.modlist) {
                if (impact.TriggeredOnHits.find(m.GetClassName()) == impact.TriggeredOnHits.size()) {
                    // This on-hit isn't blacklisted yet.
                    bool res = m.OnHit(impact,impact.tracer);
                    if (!res) {
                        impact.TriggeredOnHits.push(m.getclassname());
                        // This on-hit should not trigger again for this 'chain'.
                    }
                }
            }
        }
    }
}

class WRProj : FastProjectile abstract {
    // TODO: Set up flamethrower library.
    Array<String> TriggeredOnHits; // Contains any OnHits that should not trigger again for this projectile or for its children.

    WRWeapon weapon;
    Name fx;
    Property FX: fx; // What gets spawned when this thing goes poof.
    // Used to make sure OnHits gets called right away, even though we want pretty vfx.


    default {
        +HITTRACER;
    }

    // SpawnChildProj flags
    const SCP_NOSPEED = 1; // Don't use the spawned actor's speed property

    Actor SpawnChildProj(Name what, Vector3 spawnpos, Vector3 spawnvel, Vector2 spawnangs = (0,0), int flags = 0) {
        Actor it = Spawn(what,spawnpos);
        if (it) {
            // Successful spawn.
            WRProj wp = WRProj(it);
            it.master = self; // The projectile will use this to grab our TriggeredOnHits array.
            it.target = target;
            if (wp) {
                wp.weapon = weapon;
            }
            if (!(flags & SCP_NOSPEED)) {
                spawnvel *= it.speed;
            }
            it.vel = spawnvel;
            it.angle += spawnangs.x;
            it.pitch += spawnangs.y;
            return it;
        } else {
            return null; // Something went wrong...
        }
    }

    override void PostBeginPlay() {
        WRProj m = WRProj(master);
        if (m) {
            TriggeredOnHits.copy(m.TriggeredOnHits);
        }
        super.PostBeginPlay();
    }

    action void OnHits() {
        if (invoker.weapon) {
            invoker.weapon.CallOnHits(invoker);
        }
    }

    action void SpawnFX() {
        A_SpawnItemEX(invoker.fx);
    }

    states {
        Spawn:
            TNT1 A -1; // Use trails for visuals.

        Death:
            TNT1 A 0 SpawnFX();
            TNT1 A 0 OnHits();
            Stop;
    }

}

class WRMod : Inventory abstract {

    virtual bool OnHit(WRProj proj, Actor target = null) { return true; }
        // Called when a projectile hits a target. 
        // Returning false means that this effect should be flagged as 'triggered' (meaning it won't be checked for this projectile, or children of this projectile).
    
    virtual void OnFire(WRProj proj) {}
        // Called when firing the projectile.

    virtual String GetAffix() {
        return "Placeholder "; // WRModContainers use this to set up their tags.
        // Affixes should include their trailing space or dash.
    }
}

class WRModContainer : Inventory abstract {
    mixin WeightedRandom;
    Array<WRMod> modlist; // Contains one or more mods.
    Map<Name, Double> modrates; // Which mods can be dropped on this item?
    int minmods, maxmods; // How many mods can be put in this one?
    Property ModRange: minmods,maxmods;

    bool sprite; // Workaround for setting up the sprite *apparently* not working in PostBeginPlay

    static const string SpriteList[] = {
        "GEMBA0",
        "GEMBB0",
        "GEMBC0",
        "GEMBD0",
        "GEMBE0",
        "GEMMA0",
        "GEMMB0",
        "GEMMC0",
        "GEMMD0",
        "GEMME0",
        "GEMSA0",
        "GEMSB0",
        "GEMSC0",
        "GEMSD0",
        "GEMSE0"
    };

    default {
        WRModContainer.ModRange 1,3; // By default, can have up to 3.
    }

    override bool HandlePickup(Inventory item) {
        return false; // All WRModContainers are treated as new.
        // They don't stack, because different WRMCs of the same type can have different mods in them.
    }

    override string PickupMessage() {
        return String.Format("Weapon Mod: %s",GetTag());
    }

    virtual void SetupModRates() {}
        // Append mod classname and a weight to modrates to add it to the drop table.

    override void PostBeginPlay() {
        SetupModRates();
        // Once that's done...
        maxmods = min(maxmods, modrates.CountUsed()); // Can only have as many mods as there are in the drop table.
        minmods = min(maxmods,minmods); // Likewise, if max is below min, that's how many mods you can have.

        int modgen = random(minmods,maxmods); // TODO: Some kind of weighting to make high modcounts rarer.
        Array<Name> draws;
        ModsFromDeck(modrates,modgen,draws);
        String t;
        foreach (m : draws) {
            WRMod mod = WRMod(Spawn(m));
            mod.BecomeItem();
            t = t .. mod.GetAffix();
            modlist.push(mod);
        }
        SetTag(t .. "Mod");
    }

    void SetupSprite() {
        int spritesel = random(0,SpriteList.size()-1);
        picnum = TexMan.CheckForTexture(SpriteList[spritesel]);
        icon = picnum;
    }

    override void Tick() {
        if (!sprite) {
            SetupSprite();
            sprite = true;
        }
        super.Tick();
    }
}

class SingleModContainer : WRModContainer {
    // For simplicity's sake.
    Name mod;
    Property Mod: mod;

    override void PostBeginPlay() {
        // Only one mod.
        WRMod m = WRMod(Spawn(mod)); m.BecomeItem();
        modlist.push(m);
    }
}