class PressTheAttack : WRMod {

    default {
        Tag "Every 3rd hit on an enemy triggers a burst of damage.";
    }

    override bool OnHit(WRProj proj, Actor tgt) {
        if (!tgt) { return true; } // PTA does not trigger unless there's a target.
        tgt.GiveInventory("PTAStack",1);
        if (tgt.CountInv("PTAStack") >= 3) {
            // Trigger a burst of damage.
            proj.SpawnChildProj("PTABurst",proj.pos,-proj.vel);
            tgt.DamageMobj(proj,proj.target,50,"PressTheAttack");
            tgt.TakeInventory("PTAStack",3);
        }

        return false; // each projectile triggers just one PTA stack
    }

    override string GetAffix() {
        static const string Affixes[] = {
            "Three-hit ",
            "Overbearing ",
            "Triple-Tap ",
            "Focused ",
            "Burst-fire "
        };
        return Affixes[random(0,Affixes.size()-1)];
    }

}

class PTAStack : Inventory {
    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 3;
    }
}

class PTABurst : Actor {
    default {
        +NOINTERACTION;
        Scale 2.5;
    }

    states {
        Spawn:
            APLS ABCDE 3;
            Stop;
    }
}

class PTAModContainer : SingleModContainer {
    default {
        SingleModContainer.Mod "PressTheAttack";
        Tag "Press The Attack Mod";
    }
}