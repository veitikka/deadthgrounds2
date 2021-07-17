package mdg;

import gmod.libs.MathLib;
import mdg.Utils.spawnSimfphys;
import gmod.helpers.TableTools;
import gmod.libs.EngineLib;
import gmod.gclass.IMaterial;
import gmod.libs.RenderLib;
import gmod.helpers.net.NET_Server;
import gmod.gclass.Color;
import gmod.libs.DrawLib;
import gmod.libs.SurfaceLib;
import gmod.libs.CamLib;
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

typedef RoundSituation = {
    finalePos: Vector,
    winner: Entity
}

class MdgBattle extends MdgState {
    #if client
    var sphereMaterial:IMaterial = Gmod.Material("mdg/sphere.vmt").a;
    final colorModify = Table.fromMap([
        "$pp_colour_addr" => Theme.rgbPercentage(Theme.sphereColor.r) * 0.35,
        "$pp_colour_addg" => Theme.rgbPercentage(Theme.sphereColor.g) * 0.35,
        "$pp_colour_addb" => Theme.rgbPercentage(Theme.sphereColor.b) * 0.35,
        "$pp_colour_brightness" => -0.05,
        "$pp_colour_contrast" => 1,
        "$pp_colour_colour" => 1,
        "$pp_colour_mulr" => Theme.rgbPercentage(Theme.sphereColor.r),
        "$pp_colour_mulg" => Theme.rgbPercentage(Theme.sphereColor.g),
        "$pp_colour_mulb" => Theme.rgbPercentage(Theme.sphereColor.b)
    ]);
    #end

    #if server
    var gameSpawns:SpawnManager = null;
    var spectatorSpawns:SpawnManager = null;
    #end

    final originalSphereRadius = 65536.0;
    var sphereRadius(get, set):Float;
    function get_sphereRadius():Float {
		return Gmod.GetGlobalFloat("mdg.globals.sphereradius", 0.0);
	}

	function set_sphereRadius(value:Float):Float {
        #if client
        Gmod.LocalPlayer().ChatPrint("NETWORK VAR SET ON CLIENT; DON'T DO THIS");
        return 0.0;
        #end
        #if server
        Gmod.SetGlobalFloat("mdg.globals.sphereradius", value);
        return value;
        #end
	}

    final roundNet = new NET_Server<"mdg_net_roundsituation", RoundSituation>();
    var roundSituation:RoundSituation = {
        finalePos: null,
        winner: null
    }

    var tickInterval = EngineLib.TickInterval();
    final shrinkRate = 45.0;
    final postRoundTime = 7;
    final droneRespawnTime = 30;

    public function new(manager:GameHooks) {
        super(manager);
        #if client
        roundNet.addReceiver("mdg.net.roundsituation.client", (data) -> {
            roundSituation = data;
        });
        #end
    }

    override function create() {
        tickInterval = EngineLib.TickInterval();
        // TODO: Replace with some sort of lazy eval
        #if server
        if (gameSpawns == null) {
            gameSpawns = new SpawnManager(manager.mission.gamespawns.map(p -> new Vector(p.pos[0], p.pos[1], p.pos[2])), manager.playerHull);
        }
        if (spectatorSpawns == null) {
            spectatorSpawns = new SpawnManager(manager.mission.dronespawns.map(p -> new Vector(p.pos[0], p.pos[1], p.pos[2])), manager.droneHull);
        }
        for (player in PlayerLib.GetAll()) {
            if (player.Alive()) {
                player.restore();
            } else {
                player.Spawn();
            }
            player.SetTeam(1);
            player.SetPos(gameSpawns.next());
        }
        spawnMissionEntities();
        final fpoint = getFinalePoint();
        sphereRadius = originalSphereRadius;
        roundSituation = { finalePos: fpoint, winner: null }
        roundNet.broadcast(roundSituation);

        final sphereDamage = Gmod.DamageInfo();
        sphereDamage.SetDamage(5);
        sphereDamage.SetDamageType(DMG_DISSOLVE);
        sphereDamage.SetReportedPosition(fpoint);
        TimerLib.Create("fwuso.mdg.timer.spheredamage", 3, 0, () -> {
            final finalePos = roundSituation.finalePos;
            final array:Array<Player> = Table.toArray(cast TeamLib.GetPlayers(manager.TEAM_PLAYERS));
            for (player in array) {
                final dist = player.GetPos().Distance(finalePos);
                if (dist > sphereRadius) {
                    // player.TakeDamageInfo(sphereDamage);
                }
            }
        });
        manager.notifyAll("Good Huntign,,,", 5);
        #end
    }

    override function tick() {
        #if server
        if (sphereRadius > 64) {
            final speedMultiplier = (Math.sin(((3.14 / originalSphereRadius) * sphereRadius) + 1.57) * -1) + 1;
            // trace(speedMultiplier);
            sphereRadius -= shrinkRate * tickInterval * speedMultiplier;
        }
        #end
    }

    override function destroy() {
        #if server
        roundSituation = { finalePos: null, winner: null }
        // roundNet.broadcast(roundSituation);
        TimerLib.Remove("fwuso.mdg.timer.spheredamage");
        TimerLib.Remove("fwuso.mdg.timer.postround");
        #end
        GameLib.CleanUpMap(null, Table.fromArray(["env_fire", "entityflame", "_firesmoke"]));
    }

    #if server
    function checkBattleDeath(killed:Player) {
        final aliveCount = TeamLib.NumPlayers(manager.TEAM_PLAYERS);
        final players:Array<Player> = Table.toArray(cast TeamLib.GetPlayers(manager.TEAM_PLAYERS));
        manager.notifyAll('${killed.Nick()} died!', 2);
        trace('alive: ${aliveCount}');
        if (aliveCount == 1) {
            final winner = players[0];
            manager.announceWinner(winner);
            TimerLib.Create("fwuso.mdg.timer.postround", postRoundTime, 1, function() {
                startState(manager.lobby);
            });
        } else if (aliveCount == 2) {
            final candidate1 = players[0].Nick();
            final candidate2 = players[1].Nick();
            manager.notifyAll('${candidate1} vs ${candidate2}', 2);
        } else {
            manager.notifyAll('${aliveCount} combatants remaining');
        }
    }

    function spawnMissionEntities() {
        // TODO: Make most entities sleep ~5 seconds after spawning
    }

    function getFinalePoint(): Vector {
        final finale = Random.fromArray(manager.mission.finales);
        return new Vector(finale.pos[0], finale.pos[1], finale.pos[2]);
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
    override function hudPaintBackground() {
        final finalePos = roundSituation.finalePos;
        if (finalePos != null) {
            final playerPos = Gmod.LocalPlayer().GetPos();
            final dist = finalePos.Distance(playerPos);
            final text = 'Finale - ${Math.round(dist * 0.0190625)}m';
            final textPos = finalePos.ToScreen();
            SurfaceLib.SetFont("Default");
            final width = SurfaceLib.GetTextSize(text).a;
            DrawLib.SimpleTextOutlined(text, "Default", (-width / 2) + textPos.x, textPos.y, Gmod.Color(255, 255, 255), null, null, 2,
            Theme.textShadow);
        }
    }

    override function postDrawOpaqueRenderables(bDrawingDepth:Bool, bDrawingSkybox:Bool) {
        if (bDrawingSkybox) {
            return;
        }
        final finalePos = roundSituation.finalePos;
        final dist = finalePos.Distance(Gmod.LocalPlayer().GetPos());
        final diff = sphereRadius - dist;
        final alphaMultiplier = 1-MathLib.Remap(MathLib.Clamp(diff, 1024, 1536), 1024, 1536, 0, 1);
        final alpha = Gmod.Lerp(alphaMultiplier, 0, 127);
        final red = Theme.sphereColor.r;
        final green = Theme.sphereColor.g;
        final blue = Theme.sphereColor.b;
        if (finalePos != null) {
            RenderLib.SetMaterial(sphereMaterial);
            RenderLib.DrawSphere(finalePos, sphereRadius, 32, 32, Gmod.Color(red, green, blue, alpha));
        }
    }

    override function renderScreenspaceEffects() {
        final finalePos = roundSituation.finalePos;
        // TODO: Remove the hack
        final player = Gmod.LocalPlayer();
        var huutis = false;
        final a:Array<Player> = Table.toArray(cast TeamLib.GetPlayers(manager.TEAM_PLAYERS));
        for (i in a) {
            if (i.UserID() == player.UserID()) {
                huutis = true;
            }
        }
        if (finalePos != null && huutis) {
            final dist = finalePos.Distance(player.GetPos());
            if (dist > sphereRadius) {
                Gmod.DrawColorModify(colorModify);
            }
        }
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
