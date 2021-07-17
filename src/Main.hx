import mdg.panels.ScoreBoardPlayer;
import mdg.panels.ScoreBoard;
import gmod.Gmod;
import mdg.GameHooks;
import mdg.ents.Base_GmodEntity;

class Main {
    public static function main() {
        #if client
        ScoreBoard.register();
        ScoreBoardPlayer.register();
        Gmod.MsgC(Gmod.Color(219, 113, 82), '[Deadthgrounds 2] Client init\n');
        #end
        #if server
        Gmod.MsgC(Gmod.Color(219, 113, 82), '[Deadthgrounds 2] Server init\n');
        #end
        new GameHooks().setUp();
    }
}
