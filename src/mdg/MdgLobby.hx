package mdg;

import gmod.libs.DrawLib;
import gmod.libs.SurfaceLib;
import gmod.libs.UtilLib;
import gmod.Gmod;
import gmod.libs.TimerLib;
import gmod.libs.PlayerLib;
import gmod.gclass.CTakeDamageInfo;
import gmod.gclass.Entity;
import gmod.gclass.Player;
import gmod.gclass.Vector;

using mdg.extensions.PlayerExtensions;

class MdgLobby extends MdgState {
    #if server
    var spawns:SpawnManager = null;
    #end

    final minPlayers = 2;
    final lobbyTime = 5;
    var lobbyCountDown = false;

    public function new(manager:GameHooks) {
        super(manager);
    }

    override function create() {
        #if server
        // TODO: Replace with some sort of lazy eval
        if (spawns == null) {
            spawns = new SpawnManager(manager.mission.lobbyspawns.map(p -> new Vector(p.pos[0], p.pos[1], p.pos[2])), manager.playerHull);   
        }
        for (player in PlayerLib.GetAll()) {
            player.SetTeam(manager.TEAM_NONE);
            player.Spawn();
        }
        #end
    }

    override function think() {

    }

    override function destroy() {
        #if server
        TimerLib.Remove("fwuso.mdg.lobby.countdown");
        #end
    }

    #if server
    function checkLobbyPlayerCount() {
        if (PlayerLib.GetCount() >= minPlayers && !lobbyCountDown) {
            lobbyCountDown = true;
            var iterations = 0;
            TimerLib.Create("fwuso.mdg.lobby.countdown", 1, lobbyTime+1, function() {
                if (PlayerLib.GetCount() < minPlayers) {
                    lobbyCountDown = false;
                    TimerLib.Remove("fwuso.mdg.lobby.countdown");
                    return;
                }
                if (iterations == lobbyTime) {
                    lobbyCountDown = false;
                    TimerLib.Remove("fwuso.mdg.lobby.countdown");
                    startState(manager.battle);
                    return;
                }
                final secs = lobbyTime - iterations;
                manager.notifyAll('The game will start in ${secs} second${if (secs == 1) "" else "s"}.');
                iterations++;
            });
        }
    }
    #end

    // Hooks

    #if client
    override function hudDrawTargetId() {
        final tr = UtilLib.GetPlayerTrace(Gmod.LocalPlayer());
        final entity = UtilLib.TraceLine(tr).Entity;
        var text = "NO_LAD";
        final font = "TargetID";
        if (entity != null && entity.IsValid() && entity.IsPlayer()) {
            final player:Player = cast entity;
            text = player.Nick();
            final color = Gmod.Color(255, 255, 0);
            SurfaceLib.SetFont(font);
            final textWidth = SurfaceLib.GetTextSize(text).a;
            final x = (Gmod.ScrW() / 2) - (textWidth / 2);
            final y = (Gmod.ScrH() / 2) + 10;
            DrawLib.SimpleText(text, font, x+1, y+1, Gmod.Color( 0, 0, 0, 120 ));
            DrawLib.SimpleText(text, font, x+2, y+2, Gmod.Color( 0, 0, 0, 50 ));
            DrawLib.SimpleText(text, font, x, y, color);
        }
    }
    #end

    #if server
    override function playerSpawn(player:Player, transition:Bool) {
        player.init(spawns.next());
        checkLobbyPlayerCount();
    }

    override function doPlayerDeath(player:Player, attacker:Entity, damageInfo:CTakeDamageInfo) {

    }

    override function playerDeath(player:Player, inflictor:Entity, attacker:Entity) {
        final time = Gmod.CurTime();
        player.playerData().nextSpawnTime = time + 3;
    }

    override function playerDeathThink(player:Player):Bool {
        final spawnTime = player.playerData().nextSpawnTime;
        final time = Gmod.CurTime();
        if (spawnTime < time) {
            player.Spawn();
            return true;
        }
        return false;
    }

    override function playerJoined(player:Player) {

    }

    override function playerDisconnected(player:Player) {

    }

    override function canPlayerSuicide(player:Player):Bool {
        return true;
    }
    #end
}
