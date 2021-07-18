package mdg.panels;
import gmod.helpers.GLinked;
#if client
import gmod.panels.DScrollPanel;
import gmod.libs.PlayerLib;
import gmod.panels.DLabel;
import gmod.Gmod;
import gmod.enums.DOCK;
import gmod.libs.VguiLib;
import gmod.stringtypes.PanelClass.GMPanels;
import gmod.panels.DPanel;
import gmod.panels.EditablePanel;
import gmod.helpers.panel.PanelBuild;

using mdg.extensions.PlayerExtensions;

typedef GScoreBoard = GLinked<EditablePanel, ScoreBoard>;

@:expose("ScoreBoard")
class ScoreBoard extends PanelBuild<gmod.panels.EditablePanel> {
    var titleText = "";
    var title:DLabel = null;
    var list:DScrollPanel = null;
    static var instance = null;

    public static function getInstance():GScoreBoard {
        if (instance == null) {
            instance = VguiLib.Create(gclass);
        }
        return instance;
    }

    override function Init() {
        final header = VguiLib.Create(GMPanels.DPanel);
        self.Add(header);
        header.Dock(DOCK.TOP);
        header.SetHeight(92);

        title = VguiLib.Create(GMPanels.DLabel);
        self.Add(title);
        title.SetFont("ScoreboardDefault");
        title.SetColor(Theme.textColor.ToTable());
        title.Dock(DOCK.TOP);
        title.SetHeight(48);
        title.SetExpensiveShadow(2, Theme.textShadow);

        list = VguiLib.Create(GMPanels.DScrollPanel);
        self.Add(list);
        list.Dock(DOCK.FILL);
    }

    override function PerformLayout(width:Float, height:Float) {
        final w = 700;
        self.SetSize(w, Gmod.ScrH() - 200);
        self.SetPos((Gmod.ScrW() / 2) - (w/2), 100);
    }

    override function Paint(width:Float, height:Float):Bool {
        return false;
    }

    override function Think() {
        if (titleText != Gmod.GetHostName()) {
            titleText = Gmod.GetHostName();
            title.SetText(titleText);
        }

        for (player in PlayerLib.GetAll()) {
            if (Gmod.IsValid(player.playerData().scoreBoardEntry)) {
                continue;
            }

            final entry = VguiLib.Create(ScoreBoardPlayer.gclass);
            player.playerData().scoreBoardEntry = entry;
            player.playerData().scoreBoardEntry.setUp(player);
            list.AddItem(entry);
        }
    }
}
#end
