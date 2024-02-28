class VorpalMod : WRMod {
    override bool OnHit(WRProj proj, Actor tgt) {
        if (!tgt) {return true;}
        if (frandom(0,1) > 0.2) { return true; } // 20% chance to not trigger.

        tgt.DamageMobj(proj,proj.target,proj.GetMissileDamage(0,1),"Vorpal"); // None of our projectiles should use randomized damage anyway.
        return false; // Can only trigger once in the chain.
    }
}