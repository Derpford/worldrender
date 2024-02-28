class SpreadMod : WRMod {
    override void OnFire(WRProj proj) {
        vector3 nvel = proj.vel;
        nvel.xy = RotateVector(proj.vel.xy,-5);
        proj.SpawnChildProj(proj.GetClassName(),proj.pos,nvel.unit());
        nvel.xy = RotateVector(proj.vel.xy,5);
        proj.SpawnChildProj(proj.GetClassName(),proj.pos,nvel.unit());
    }
}

class SpreadModContainer : SingleModContainer  {
    default {
        SingleModContainer.Mod "SpreadMod";
    }
}