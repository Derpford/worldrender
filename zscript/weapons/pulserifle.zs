class PulseRifle : WRWeapon {
    // Burst-firing workhorse of the Terran Worlds.
    default {
        WRWeapon.Spread (0,0), (0.2,0.2);
        WRWeapon.Shotcount 1.0, 0;
        WRWeapon.Projectile "PulseRifleBlast";
        Weapon.AmmoType1 "Pulse";
        Weapon.AmmoUse1 100;
        Weapon.AmmoGive1 100000;
    }
    
    override void PostBeginPlay() {
        // For testing purposes...
        WRModContainer rapid = WRModContainer(Spawn("RapidModContainer")); rapid.BecomeItem();
        WRModContainer exp = WRModContainer(Spawn("EModContainer")); exp.BecomeItem();
        mods.push(exp);
        mods.push(rapid);
        super.PostBeginPlay();
    }

    states {
        Spawn:
            PLAS A -1;
            Stop;
        
        Select:
            PLSG B 1 A_Raise(18);
            Loop;
        DeSelect:
            PLSG B 1 A_Lower(18);
            Loop;
        
        Ready:
            PLSG A 1 A_WeaponReady();
            Loop;
        
        Fire:
            PLSG A 1 Fire();
            PLSG A 2;
            PLSG A 1 Fire((0,-0.75));
            PLSG A 2;
            PLSG A 1 Fire((0,-1.5));
            PLSG A 10;
            Goto Ready;
        
        Flash:
            PLSF AB Random(0,2) A_Light1();
            Stop;
    }
}

class PulseRifleBlast : WRProj {
    // Fast, decently powerful.
    default {
        Speed 90;
        DamageFunction (20); // 1-shots zombiemen. Two bursts kills an unarmored player.
        Radius 8;
        Height 8;
        MissileType "PulseTrail";
        SeeSound "weapons/plasmaf";
        DeathSound "weapons/plasmax";
        WRProj.FX "PulseFX";
    }

}

class PulseFX : Actor {
    default {
        +NOINTERACTION;
        RenderStyle "Add";
    }

    states {
        Spawn:
            PLSE ABCDE 3 Bright;
            Stop;
    }
}

class PulseTrail : Actor {
    default {
        +NOINTERACTION;
        RenderStyle "Add";
    }

    states {
        Spawn:
            PLSS AB 2 A_FadeOut(0.3);
            Loop;
    }
}