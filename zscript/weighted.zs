mixin class WeightedRandom {
    int WeightedRandom(Array<Double> weights) {
        double sum;
        for (int i = 0; i < weights.size(); i++) {
            sum += weights[i];
        }

        // And now we roll.
        double roll = frandom(0,sum);
        for (int i = 0; i < weights.size(); i++) {
            if (roll < weights[i]) {
                return i;
            } else {
                roll -= weights[i];
            }
        }
        // If we reach this point, something went wrong.
        return -1;
    }

    Name WeightedFromMap(Map<Name,Double> items) {
        Array<Name> ks;
        Array<Double> vs;
        MapIterator<Name,Double> it;
        it.init(items);
        while(it.Next() && it.valid()) {
            ks.push(it.GetKey());
            vs.push(it.GetValue());
        }

        int select = WeightedRandom(vs);
        return ks[select];
    }

    int ModsFromDeck(Map<Name,Double> items, int num, out Array<Name> results) {
        if (items.CountUsed() < num) { num = items.CountUsed(); } // Can't have more draws than there are cards.
        while (results.size() < num) {
            Name draw = WeightedFromMap(items);
            items.remove(draw);
            results.push(draw);
        }

        return results.size();
    }
}