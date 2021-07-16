package mdg;

import gmod.stringtypes.Hook.GMHook;
import mdg.structs.Mission;
import gmod.libs.GameLib;
import gmod.Gmod;
import gmod.libs.TeamLib;
import gmod.libs.UtilLib;
import mdg.MdgState;
import mdg.structs.Hull;
import gmod.libs.NetLib;
import gmod.gclass.CTakeDamageInfo;
import gmod.gclass.Entity;
import gmod.gclass.Vector;
import gmod.gclass.Player;
import gmod.helpers.gamemode.GMBuild;

using mdg.extensions.PlayerExtensions;

// mdg_minplayers -- Minimum player count to start a match
// mdg_lobbytime -- Amount of time to spend in lobby
// mdg_postroundtime -- Amount of time to wait at the end of the match
// mdg_drone_respawntime -- Amount of time it takes for drone players to respawn
class GameHooks extends gmod.helpers.gamemode.GMBuild<gmod.gamemode.GM> {
    var gameState:MdgState = null;

    public var defaultState:MdgDefaultState = null;
    public var lobby:MdgLobby = null;
    public var battle:MdgBattle = null;
    public final TEAM_NONE = 1001;
    public final TEAM_PLAYERS = 1;
    public final TEAM_SPECTATORS = 2;
    public var mission:Mission = null;
    public var mapList:Array<String> = [];

    public final playerHull:Hull = {
        mins: new Vector(-17, -17, -1),
        maxs: new Vector(17, 17, 73)
    };

    public final droneHull:Hull = {
        mins: new Vector(-17, -17, -1),
        maxs: new Vector(17, 17, 73)
    };

    public function setUp() {
        defaultState = new MdgDefaultState(this);
        lobby = new MdgLobby(this);
        battle = new MdgBattle(this);

        #if server
        Console.createVar("mdg_minplayers", "2", "", FCVAR_NOTIFY);
        Console.createVar("mdg_maxrounds", "10", "", FCVAR_NOTIFY);
        Console.createVar("mdg_lobbytime", "15", "", FCVAR_NOTIFY);
        Console.createVar("mdg_postroundtime", "10", "", FCVAR_NOTIFY);
        Console.createVar("mdg_deathtime", "7", "Seconds it takes for a player to spawn as a drone for the first time after death", FCVAR_NOTIFY);
        Console.createVar("mdg_drone_respawntime", "30", "Seconds it takes for a drone to respawn", FCVAR_NOTIFY);

        UtilLib.AddNetworkString("mdg.net.syncstate");
        UtilLib.AddNetworkString("mdg.net.changestate");
        UtilLib.AddNetworkString("mdg.net.clientinit");
        NetLib.Receive("mdg.net.clientinit", playerJoined);
        #end

        #if client
        NetLib.Receive("mdg.net.syncstate", function(length, player) {
            gameState = intToState(NetLib.ReadUInt(2));
        });

        NetLib.Receive("mdg.net.changestate", function(length, player) {
            gameState.destroy();
            gameState = intToState(NetLib.ReadUInt(2));
            gameState.create();
        });
        #end
    }

    override function CreateTeams() {
        TeamLib.SetUp(TEAM_PLAYERS, "Players", Gmod.Color(255, 255, 0));
        TeamLib.SetUp(TEAM_SPECTATORS, "Spectators", Gmod.Color(160, 160, 200));
    }

    override function Initialize() {
        gameState = defaultState;
        gameState.create();

        #if server
        final missionManager = new MissionManager("deadthgrounds2/missions/", print);
        mapList = missionManager.init();
        mission = missionManager.getMapMission(GameLib.GetMap());

        if (mission != null) {
            for (i in [
                {l: mission.lobbyspawns, s: "lobby spawns"},
                {l: mission.gamespawns, s: "game spawns"},
                {l: mission.dronespawns, s: "drone spawns"}
            ]) {
                if (i.l.length == 0) {
                    mission = null;
                    print('ERROR: Mission has 0 ${i.s}.');
                }
            }
        }

        if (mission != null) {
            gameState.startState(lobby);
        } else {
            final castedState:MdgDefaultState = cast gameState;
            castedState.errorMessage = "This map is not compatible with the gamemode. Please select another map. See console for details.";
        }
        #end
    }

    override function Think() {
        gameState.think();
    }

    #if client
    override function HUDDrawTargetID() {
        gameState.hudDrawTargetId();
    }

    override function HUDPaintBackground() {
        gameState.hudPaintBackground();
    }

    override function PostDrawOpaqueRenderables(bDrawingDepth:Bool, bDrawingSkybox:Bool) {
        gameState.postDrawOpaqueRenderables(bDrawingDepth, bDrawingSkybox);   
    }

    @:gmodHook(GMHook.InitPostEntity)
    static function initPost() {
        NetLib.Start("mdg.net.clientinit");
        NetLib.SendToServer();
    }
    #end

    #if server
    override function PlayerSpawn(player:Player, transition:Bool) {
        gameState.playerSpawn(player, transition);
    }

    override function DoPlayerDeath(player:Player, attacker:Entity, damageInfo:CTakeDamageInfo) {
        if (damageInfo.IsExplosionDamage()) {
            trace("gib 'em");
            // EntsLib.CreateClientProp("");
        }
        player.CreateRagdoll();
        gameState.doPlayerDeath(player, attacker, damageInfo);
    }

    override function PlayerDeath(player:Player, inflictor:Entity, attacker:Entity) {
        gameState.playerDeath(player, inflictor, attacker);
    }

    override function PlayerDeathThink(player:Player):Bool {
        return gameState.playerDeathThink(player);
    }

    override function PlayerDisconnected(player:Player) {
        gameState.playerDisconnected(player);
    }

    // Disable HEV beeping
    override function PlayerDeathSound():Bool {
        return true;
    }

    override function CanPlayerSuicide(player:Player):Bool {
        return gameState.canPlayerSuicide(player);
    }

    override function GetFallDamage(player:Player, speed:Float):Float {
        return (speed - 526.5) * (100 / 396);
    }

    function playerJoined(_:Int, player:Player) {
        NetLib.Start("mdg.net.syncstate");
        final value = stateToInt(gameState);
        NetLib.WriteUInt(value, 2);
        NetLib.Send(player);
        gameState.playerJoined(player);
    }

    public function notifyAll(message:String) {
        Gmod.PrintMessage(HUD_PRINTTALK, message);
    }

    public function print(message:String) {
        Gmod.MsgC(Gmod.Color(219, 113, 82), '[Deadthgrounds 2] ${message}\n');
    }

    public function setGameState(state:MdgState) {
        gameState = state;
        NetLib.Start("mdg.net.changestate");
        final value = stateToInt(state);
        NetLib.WriteUInt(value, 2);
        NetLib.Broadcast();
    }
    #end

    function stateToInt(state:MdgState):Int {
        return switch state {
            case v if (Std.isOfType(v, MdgLobby)): 1;
            case v if (Std.isOfType(v, MdgBattle)): 2;
            case v if (Std.isOfType(v, MdgDefaultState)): 3;
            default: 0;
        }
    }

    function intToState(num:Int):MdgState {
        return switch num {
            case 1: lobby;
            case 2: battle;
            case 3: defaultState;
            default: null;
        }
    }
}
