class SpreadMod : WRMod {
    default {
        Tag "Fires 2 additional shots with a 10 degree spread.";
    }

    override void OnFire(WRProj proj) {
        vector3 nvel = proj.vel;
        nvel.xy = RotateVector(proj.vel.xy,-5);
        proj.SpawnChildProj(proj.GetClassName(),proj.pos,nvel.unit());
        nvel.xy = RotateVector(proj.vel.xy,5);
        proj.SpawnChildProj(proj.GetClassName(),proj.pos,nvel.unit());
    }

    override string GetAffix() {
        static const string Affixes[] = {
            "Triplet ",
            "Spread-",
            "Wide ",
            "Tri-barrel ",
            "Dakka "
        };
        return Affixes[random(0,Affixes.size()-1)];
    }
}

class SpreadModContainer : SingleModContainer  {
    default {
        SingleModContainer.Mod "SpreadMod";
        Tag "Spread Mod";
    }
}