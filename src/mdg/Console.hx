package mdg;

import gmod.Gmod;

class Console {
    #if server
    public static function createVar(name: String, defaultValue: String, help: String, ?flag: Null<gmod.enums.FCVAR>, ?min: Null<Float>, ?max: Null<Float>) {
        if (!Gmod.ConVarExists(name)) {
            Gmod.CreateConVar(name, defaultValue, flag, help, min, max);
        }
    }

    public static function getVarInt(name: String, defaultValue: Int):Int {
        return Math.floor(Gmod.GetConVar(name).GetInt());
    }
    #end
}
