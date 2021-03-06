package mdg.extensions;

import mdg.panels.ScoreBoardPlayer;
import gmod.gclass.Player;
import gmod.gclass.Vector;
import Math;
import Std;

class PlayerExtensions {
    static final dataMap = new Map<Player, PlayerData>();

    #if server
    public static function init(player:Player, position:Vector) {
        final modelList = ["01", "02", "03", "04", "05", "06", "07", "09", "11"];
        final modelInex = modelList[Std.random(modelList.length)];
        player.StripWeapons();
        player.StripAmmo();
        player.SetModel('models/jessev92/hl2/conscripts/m${modelInex}_ply.mdl');
        player.UnSpectate();
        player.SetupHands(null);
        player.AllowFlashlight(false);
        player.SetCanZoom(false);
        player.SetWalkSpeed(130);
        player.SetRunSpeed(250);
        player.SetCrouchedWalkSpeed(0.65);
        player.SetNoCollideWithTeammates(false);
        restore(player);
        // Skin - random
        player.SetSkin(Std.random(Math.floor(player.SkinCount())));
        // Vest - none
        player.SetBodygroup(1, 0);
        // Hands - random
        final handGroup = Std.random(3);
        player.SetBodygroup(2, handGroup);
        player.SetBodygroup(3, handGroup);
        // Headgear - none
        player.SetBodygroup(4, 7);
        player.SetPos(position);
    }

    public static function restore(player:Player) {
        player.SetMaxHealth(100);
        player.SetHealth(100);
        player.SetArmor(0);
    }

    public static function addWins(player:Player, num:Int) {

    }

    #end
    public static function getWins(player:Player):Int {
        return 0;
    }

    public static function playerData(player:Player): PlayerData {
        final data = dataMap.get(player);
        if (data != null) {
            return data;
        }
        final newData = {
            #if server
            nextSpawnTime: 0.0,
            #end
            #if client
            scoreBoardEntry: null,
            #end
        };
        dataMap.set(player, newData);
        return newData;
    }
}

typedef PlayerData = {
    #if server
    nextSpawnTime: Float,
    #end
    #if client
    scoreBoardEntry: Null<ScoreBoardPlayer>,
    #end
}
