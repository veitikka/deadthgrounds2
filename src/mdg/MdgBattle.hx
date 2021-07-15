package mdg;

import gmod.libs.TimerLib;
import gmod.libs.EntsLib;
import gmod.Gmod;
import gmod.libs.TeamLib;
import gmod.libs.GameLib;
import lua.Table;
import gmod.libs.PlayerLib;
import gmod.gclass.CTakeDamageInfo;
import gmod.gclass.Entity;
import gmod.gclass.Player;
import gmod.gclass.Vector;

using mdg.extensions.PlayerExtensions;

class MdgBattle extends MdgState {
    #if server
    var gameSpawns:SpawnManager = null;
    var spectatorSpawns:SpawnManager = null;
    #end

    final postRoundTime = 7;
    final droneRespawnTime = 30;

    public function new(manager:GameHooks) {
        super(manager);
    }

    override function create() {
        // TODO: Replace with some sort of lazy eval
        #if server
        if (gameSpawns == null) {
            gameSpawns = new SpawnManager(manager.mission.gamespawns.map(p -> new Vector(p.pos[0], p.pos[1], p.pos[2])), manager.playerHull);
        }
        if (spectatorSpawns == null) {
            spectatorSpawns = new SpawnManager(manager.mission.dronespawns.map(p -> new Vector(p.pos[0], p.pos[1], p.pos[2])), manager.droneHull);
        }
        #end
        for (player in PlayerLib.GetAll()) {
            #if server
            if (player.Alive()) {
                player.restore();
            } else {
                player.Spawn();
            }
            player.SetTeam(1);
            player.SetPos(gameSpawns.next());
            player.Give("weapon_357");
            player.Give("weapon_slam");
            #end
        }

        #if server
        spawnMissionEntities();
        #end
    }

    override function think() {

    }

    override function destroy() {
        #if server
        TimerLib.Remove("fwuso.mdg.timer.postround");
        #end
        GameLib.CleanUpMap(null, Table.fromArray(["env_fire", "entityflame", "_firesmoke"]));
    }

    #if server
    function checkBattleDeath(killed:Player) {
        final aliveCount = TeamLib.NumPlayers(manager.TEAM_PLAYERS);
        trace('alive: ${aliveCount}');
        if (aliveCount == 1) {
            final table:Table<Int, Player> = cast TeamLib.GetPlayers(manager.TEAM_PLAYERS);
            final winner = Table.toArray(table)[0];
            manager.notifyAll('${winner.Nick()} Wins!');
            TimerLib.Create("fwuso.mdg.timer.postround", postRoundTime, 1, function() {
                startState(manager.lobby);
            });
        }
    }

    function spawnMissionEntities() {
        // TODO: Make most entities sleep ~5 seconds after spawning
    }

    function createDrone(player:Player) {
        final ent:Entity = EntsLib.Create("prop_physics");
        ent.SetModel("models/hunter/misc/sphere025x025.mdl");
        ent.SetPos(player.GetPos());
        ent.Spawn();

        player.Spectate(OBS_MODE_CHASE);
        player.SpectateEntity(ent);
    }

    function droneDestroyed(player:Player) {
        final time = Gmod.CurTime();
        player.KillSilent();
        player.playerData().nextSpawnTime = time + droneRespawnTime;
    }
    #end

    // Hooks

    #if client
    override function hudDrawTargetId() {

    }
    #end

    #if server
    override function playerSpawn(player:Player, transition:Bool) {
        player.init(spectatorSpawns.next());
        createDrone(player);
    }

    override function doPlayerDeath(player:Player, attacker:Entity, damageInfo:CTakeDamageInfo) {
        player.AddDeaths(1);
        if (attacker.IsValid() && player.IsValid()) {
            final frags = if (player == attacker) -1 else 1;
            (cast attacker).AddFrags(frags);
        }
    }

    override function playerDeath(player:Player, inflictor:Entity, attacker:Entity) {
        final time = Gmod.CurTime();
        player.playerData().nextSpawnTime = time + 10;
        player.SetTeam(manager.TEAM_SPECTATORS);
        checkBattleDeath(player);
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
        player.SetTeam(manager.TEAM_NONE);
        trace('${player.Nick()} disconnected');
        checkBattleDeath(player);
    }

    override function canPlayerSuicide(player:Player):Bool {
        return false;
    }
    #end
}
