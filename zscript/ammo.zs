// All ammo types use the same numbers under the hood. Weapons then use differing amounts of each type.

const AMMOMAX = 100000; // One hundred thousand--or, in other words, 100 with 3 decimal places.
const AMMOSMALL = 100; // A small unit of ammo is 0.1% of the max amount. This should be worth a couple shots.
const AMMOMED = 10000; // Medium ammo units are 10% of your maximum.
const AMMOLARGE = 25000; // Large ammo units are 25% of your maximum.
// Not sure what to do with backpacks.

class Slag : Ammo {
    // Containers filled with raw minerals, to be shaped into projectiles by integrated pulse-forges.
    default {
        Inventory.Amount AMMOSMALL;
        Inventory.MaxAmount AMMOMAX; 
    }
}

class Shard : Ammo {
    // Slivers of Force Crystal, a material that is normally used in forcefields. 
    default {
        Inventory.Amount AMMOSMALL;
        Inventory.MaxAmount AMMOMAX;
    }
}

class Pulse : Ammo {
    // Batteries for high-intensity Pulse formation. Noncombat applications of Pulsetech don't require this much power, so they can run off of integrated reactors.
    default {
        Inventory.Amount AMMOSMALL;
        Inventory.MaxAmount AMMOMAX;
    }
}