class ExplosiveMod : WRMod {
    default {
        Tag "Once a second, causes an explosion on impact.";
    }

    double timer;
    override void Tick() {
        super.Tick();
        timer = max(0,timer - (1./35.));
    }
    override bool OnHit(WRProj proj, Actor target) {
        if (timer <= 0) {
            proj.SpawnChildProj("EModBlast",proj.pos,(0,0,0));
            timer = 1.0;
        }
        return true; // Not retriggering is handled by the timer.
    }

    override string GetAffix() {
        static const string Affixes[] = {
            "Boom ",
            "Blast-",
            "Exploding ",
            "Nitro ",
            "Krak "
        };
        return Affixes[random(0,Affixes.size()-1)];
    }
}

class EModBlast : Actor {
    // Explodes. That's it.
    default {
        +NOGRAVITY;
        Tag "Explosive Mod";
    }

    states {
        Spawn:
            MISL B 4 A_StartSound("weapons/rocklx");
            MISL C 4 A_Explode(128,128,0);
            MISL D 4;
            TNT1 A -1;
            Stop;
    }
}

class EModContainer : SingleModContainer {
    default {
        SingleModContainer.Mod "ExplosiveMod";
    }
}