class WRPlayer : DoomPlayer {
    // Starts with 50% of all ammo types.

    default {
        player.StartItem "Pulse", 50000;
        player.StartItem "Slag", 50000;
        player.StartItem "Shard", 50000;
        player.StartItem "InvManager";
    }
}