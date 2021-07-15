package mdg;

import mdg.structs.Mission;
import haxe.Json;
import haxe.Exception;
import gmod.libs.GameLib;
import lua.Table;
import gmod.libs.FileLib;

class MissionManager {
    final missionDir:String;
    final output:String -> Void;
    public function new(missionDir: String, output: String -> Void) {
        if (missionDir.charAt(missionDir.length-1) != "/") {
            missionDir = '${missionDir}/';
        }
        this.missionDir = missionDir;
        this.output = output;
    }
    public function init():Array<String> {
        final missionMaps = Table.toArray(FileLib.Find('${missionDir}*.json', Path.DATA).files);
        for (m in missionMaps) {
            m = m.substring(0, m.length - 5);
        }
        if (missionMaps.length == 0) {
            output("No mission files found. Generating defaults.");
            final defaultMissions = [
                { map: "gm_fork", mission: "" }
            ];
            FileLib.CreateDir(missionDir);
            for (dm in defaultMissions) {
                FileLib.Write('${missionDir}${dm.map}.json', dm.mission);
                output('Generated ${dm.map}.json');
            }
        }
        return missionMaps;
    }

    public function getMapMission(mapName: String): Null<Mission> {
        output("Loading mission file...");
        final fileName = '${missionDir}${mapName}.json';
        final json = FileLib.Read(fileName, Path.DATA);
        var missionData:Mission = null;
        try {
            if (json == null) {
                throw new Exception('File \'data/${fileName}\' does not exist.');
            }
            missionData = Json.parse(json);
        } catch(e) {
            output('Error reading mission file: ${e.message}');
        }
        if (missionData != null) {
            output("Mission file is OK");
        }
        return missionData;
    }
}
