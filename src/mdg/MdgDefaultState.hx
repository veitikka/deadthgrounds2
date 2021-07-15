package mdg;

import gmod.gclass.Player;

class MdgDefaultState extends MdgState {
    #if server
    public var errorMessage = "";

    override function playerSpawn(player:Player, transition:Bool) {
        if (errorMessage.length > 0) {
            manager.notifyAll(errorMessage);
        }
    }
    #end
}
