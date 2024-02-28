class ExplosiveMod : WRMod {
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
}

class EModBlast : Actor {
    // Explodes. That's it.
    default {
        +NOGRAVITY;
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