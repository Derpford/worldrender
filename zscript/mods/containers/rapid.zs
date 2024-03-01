class RapidModContainer : WRModContainer {
    // Voted most likely to hold down the trigger.
    default {
        WRModContainer.ModRange 1,4;
    }

    override void SetupModRates() {
        modrates.insert("PressTheAttack",1.0);
        modrates.insert("SpreadMod",1.0);
        modrates.insert("VorpalMod",1.0);
    }
}