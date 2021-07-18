package mdg.panels;
#if client
import gmod.panels.DPanel;
import gmod.libs.DrawLib;
import gmod.Gmod;
import gmod.gclass.Player;
import gmod.panels.DImageButton;
import gmod.panels.DLabel;
import gmod.enums.TEXT_ALIGN;
import gmod.stringtypes.Hook.GMHook;
import gmod.enums.DOCK;
import gmod.libs.VguiLib;
import gmod.stringtypes.PanelClass.GMPanels;
import gmod.gclass.Panel;
import gmod.panels.DButton;
import gmod.panels.AvatarImage;
import gmod.helpers.panel.PanelBuild;

using mdg.extensions.PlayerExtensions;

class ScoreBoardPlayer extends PanelBuild<gmod.panels.DPanel> {
    var player:Player = null;
    var avatar:AvatarImage = null;
    var nameLabel:DLabel = null;
    var mute:DImageButton = null;
    var ping:DLabel = null;
    var deaths:DLabel = null;
    var kills:DLabel = null;
    var wins:DLabel = null;

    var name = "";
    var numWins = 0;
    var numKills = 0;
    var numDeaths = 0;
    var numPing = 0;
    var isMuted = false;

    public function setUp(player:Player) {
        this.player = player;

    }

    override function Init() {
        final avatarButton = VguiLib.Create(GMPanels.DButton);
        avatar = VguiLib.Create(GMPanels.AvatarImage, avatarButton);
        self.Add(avatarButton);
        avatarButton.Dock(DOCK.LEFT);
        avatarButton.SetSize(56, 56);
        avatar.SetSize(56, 56);
        avatar.SetMouseInputEnabled(false);

        nameLabel = VguiLib.Create(GMPanels.DLabel);
        self.Add(nameLabel);
        nameLabel.Dock(DOCK.FILL);
        nameLabel.SetFont("ScoreboardDefault");
        nameLabel.SetColor(Theme.textColor.ToTable());
        nameLabel.DockMargin(Theme.scoreBoardMargin, 0, 0, 0);

        mute = VguiLib.Create(GMPanels.DImageButton);
        mute.Dock(DOCK.RIGHT);
        mute.SetSize(56, 56);

        ping = createStatLabel();
        self.Add(ping);

        deaths = createStatLabel();
        self.Add(deaths);

        kills = createStatLabel();
        self.Add(kills);

        wins = createStatLabel();
        self.Add(wins);

        self.Dock(DOCK.TOP);
        self.DockPadding(Theme.scoreBoardPadding, Theme.scoreBoardPadding, Theme.scoreBoardPadding, Theme.scoreBoardPadding);
        self.SetHeight(56 + (Theme.scoreBoardPadding * 2));
        self.DockMargin(Theme.scoreBoardMargin, 0, Theme.scoreBoardMargin, Theme.scoreBoardMargin);
    }

    override function Paint(width:Float, height:Float):Bool {
        if (Gmod.IsValid(player)) {
            return false;
        }

        if (player.Team() == TEAM_CONNECTING) {
            DrawLib.RoundedBox(Theme.cornerRadius, 0, 0, width, height, Theme.notificationColor);
            return false;
        }

        DrawLib.RoundedBox(Theme.cornerRadius, 0, 0, width, height, Theme.notificationColor);
        return false;
    }

    override function Think() {
        if (!Gmod.IsValid(player)) {
            self.SetZPos(9999);
            self.Remove();
            return;
        }

        if (name != player.Nick()) {
            name = player.Nick();
            nameLabel.SetText(name);
        }

        if (numKills != player.Frags()) {
            numKills = Math.round(player.Frags());
            kills.SetText('${numKills}');
        }

        if (numDeaths != player.Deaths()) {
            numDeaths = Math.round(player.Deaths());
            kills.SetText('${numDeaths}');
        }

        if (numPing != player.Ping()) {
            numPing = Math.round(player.Ping());
            kills.SetText('${numPing}');
        }

        if (numWins != player.getWins()) {
            numWins = player.getWins();
            kills.SetText('${numWins}');
        }

        if (isMuted != player.IsMuted()) {
            isMuted = player.IsMuted();
            if (isMuted) {
                mute.SetImage("icon32/muted.png", "Muted");
            } else {
                mute.SetImage("icon32/unmuted.png", "Unmuted");
            }
        }

        if (player.Team() == TEAM_CONNECTING) {
            self.SetZPos(2000 + player.EntIndex());
            return;
        }
        self.SetZPos((player.EntIndex()));
    }

    function openProfilePage() {

    }

    function createStatLabel() {
        final label = VguiLib.Create(GMPanels.DLabel);
        label.Dock(DOCK.RIGHT);
        label.SetWidth(64);
        label.SetContentAlignment(5);
        label.SetFont("ScoreboardDefault");
        label.SetColor(Theme.textColor.ToTable());
        label.DockMargin(Theme.scoreBoardMargin, 0, 0, 0);
        return label;
    }
}
#end
