package mdg;

import mdg.structs.Hull;
import gmod.gclass.Player;
import gmod.Gmod;
import gmod.libs.EntsLib;
import gmod.gclass.Vector;
import Random;

class SpawnManager {
    var spawnsAvailable:Array<Vector>;
    var spawnsUnavailable:Array<Vector>;
    final hull:Null<Hull>;
    final count:Int;

    public function new(spawns:Array<Vector>, ?requiredArea:Null<Hull>) {
        this.spawnsAvailable = Random.shuffle(spawns.copy());
        this.spawnsUnavailable = [];
        this.hull = requiredArea;
        this.count = spawns.length;
    }

    public function next(): Vector {
        for (i in 0...count) {
            if (spawnsAvailable.length == 0) {
                spawnsAvailable = Random.shuffle(spawnsUnavailable);
                spawnsUnavailable = [];
            }
            final chosen = spawnsAvailable.pop();
            spawnsUnavailable.push(chosen);
            if (isClear(chosen, i == count-1)) {
                return chosen;
            }
        }
        return null;
    }

    public function reset() {
        for (position in spawnsUnavailable) {
            spawnsAvailable.push(position);
        }
        spawnsUnavailable = [];
        Random.shuffle(spawnsAvailable);
    }

    private function isClear(position:Vector, force:Bool):Bool {
        if (hull == null) {
            return true;
        }
        final entities = EntsLib.FindInBox(position + hull.mins, position + hull.maxs);
        var blockers = 0;
        for (entity in entities.iterator()) {
            if (Gmod.IsValid(entity) && entity.IsPlayer()) {
                final blockingPlayer:Player = cast entity;
                if (blockingPlayer.Alive()) {
                    if (force) {
                        blockingPlayer.Kill();
                    } else {
                        blockers += 1;
                    }
                }
            }
        }
        return blockers == 0;
    }
}
