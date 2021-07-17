package mdg;

import gmod.gclass.Entity;
import gmod.gclass.CTakeDamageInfo;
import gmod.gclass.Player;

class MdgState {
    final manager:GameHooks;

    public function new(manager:GameHooks) {
        this.manager = manager;
    }

    public function create() {

    }

    public function think() {

    }

    public function tick() {}

    public function destroy() {

    }

    // TODO: Send net message to call both on client too
    #if server
    public function startState(state:MdgState) {
        this.destroy();
        manager.setGameState(state);
        state.create();
    }
    #end

    // Hooks

    #if client
    public function hudDrawTargetId() {

    }

    public function hudPaintBackground() {}

    public function postDrawOpaqueRenderables(bDrawingDepth:Bool, bDrawingSkybox:Bool) {}

    public function renderScreenspaceEffects() {}
    #end

    #if server
    public function playerSpawn(player:Player, transition:Bool) {
        
    }

    public function doPlayerDeath(player:Player, attacker:Entity, damageInfo:CTakeDamageInfo) {

    }

    public function playerDeath(player:Player, inflictor:Entity, attacker:Entity) {

    }

    public function playerDeathThink(player:Player):Bool {
        return false;
    }

    public function playerJoined(player:Player) {

    }

    public function playerDisconnected(player:Player) {

    }

    public function canPlayerSuicide(player:Player):Bool {
        return false;
    }
    #end
}
