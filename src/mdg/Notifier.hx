package mdg;

import gmod.libs.VguiLib;
import gmod.gclass.Panel;
import gmod.libs.UtilLib;
import gmod.libs.TimerLib;
import gmod.libs.NetLib;
import gmod.libs.SurfaceLib;
import gmod.libs.DrawLib;
import gmod.stringtypes.Hook.GMHook;
import gmod.Gmod;
import gmod.libs.EntsLib;
import haxe.ds.Either;
import gmod.gclass.Player;
import mdg.structs.Notification;

class Notifier {
    public function new() {
        #if server
        UtilLib.AddNetworkString("mdg.net.notification");
        UtilLib.AddNetworkString("mdg.net.winnerannouncement");
        #end

        #if client
        NetLib.Receive("mdg.net.notification", () -> {
            noteText = NetLib.ReadString();
        });
        NetLib.Receive("mdg.net.winnerannouncement", () -> {
            final shouldShow = NetLib.ReadBool();
            final entity = NetLib.ReadEntity();
            if (shouldShow) {
                winner = cast entity;
                winnerImage = VguiLib.Create("AvatarImage");
                winnerImage.SetSize(128, 128);
                winnerImage.SetPlayer(winner, 184);
                winnerImage.SetPos((Gmod.ScrW() / 2) - ((512 + Theme.paddingWidth) / 2) + (Theme.paddingWidth / 2), (Gmod.ScrH() / 2) + (Theme.paddingHeight / 2));
                winnerImage.SetVisible(true);
            } else {
                winner = null;
                if (winnerImage != null) {
                    winnerImage.SetVisible(false);
                }
            }
        });
        #end
    }

    #if client
    static var noteText = "";
    static var winner:Player = null;
    static var winnerImage:Panel = null;

    @:gmodHook(GMHook.DrawOverlay, "mdg.hooks.notifier.client")
    static function paint() {
        if (noteText.length > 0) {
            SurfaceLib.SetFont("DermaLarge");
            var text = noteText;
            text = text.toUpperCase();
            final t = SurfaceLib.GetTextSize(text);
            final textWidth = t.a;
            final textHeight = t.b;

            final boxWidth = textWidth + Theme.paddingWidth;
            final boxHeight = textHeight + Theme.paddingHeight;

            final boxX = (Gmod.ScrW() / 2) - (boxWidth / 2);
            final boxY = (Gmod.ScrH() / 3) - boxHeight;

            DrawLib.RoundedBox(Theme.cornerRadius, boxX, boxY, boxWidth, boxHeight, Theme.notificationColor);
            DrawLib.SimpleTextOutlined(text, "DermaLarge", boxX + (Theme.paddingWidth / 2), boxY + (Theme.paddingHeight / 2), Theme.notificationTextColor, null, null, 2,
                Theme.textShadow);
        }

        if (winner != null) {
            final winnerAvatarSize = 128;
            final winnerBoxWidth = 512 + Theme.paddingWidth;
            final winnerBoxHeight = winnerAvatarSize + Theme.paddingHeight;

            final winnerBoxX = (Gmod.ScrW() / 2) - (winnerBoxWidth / 2);
            final winnerBoxY = (Gmod.ScrH() / 2);

            SurfaceLib.SetFont("DermaLarge");
            var text = winner.Nick();
            final t = SurfaceLib.GetTextSize(text);
            final textWidth = t.a;
            final textHeight = t.b;

            if (textWidth > winnerBoxWidth - winnerAvatarSize - Theme.paddingWidth) {
                text = text.substring(0, 20) + "...";
            }

            DrawLib.RoundedBoxEx(Theme.cornerRadius, winnerBoxX, winnerBoxY, winnerBoxWidth, Theme.paddingHeight / 2, Theme.notificationColor, true, true, false, false);
            DrawLib.RoundedBoxEx(Theme.cornerRadius, winnerBoxX, winnerBoxY + winnerBoxHeight - (Theme.paddingHeight / 2), winnerBoxWidth, Theme.paddingHeight / 2, Theme.notificationColor, false, false, true, true);
            DrawLib.RoundedBox(0, winnerBoxX, winnerBoxY + (Theme.paddingHeight / 2), Theme.paddingWidth / 2, winnerBoxHeight - Theme.paddingHeight, Theme.notificationColor);
            DrawLib.RoundedBox(0, winnerBoxX + winnerAvatarSize + (Theme.paddingWidth / 2), winnerBoxY + (Theme.paddingHeight / 2), winnerBoxWidth - winnerAvatarSize - (Theme.paddingWidth / 2), winnerBoxHeight - Theme.paddingHeight, Theme.notificationColor);
            DrawLib.SimpleTextOutlined("WINNER OF THE ROUND:", "DermaLarge", winnerBoxX + winnerAvatarSize + Theme.paddingWidth, winnerBoxY + (Theme.paddingHeight / 2), Theme.notificationTextColor, null, null, 2,
                Theme.textShadow);
                DrawLib.SimpleTextOutlined(text, "DermaLarge", winnerBoxX + winnerAvatarSize + Theme.paddingWidth, winnerBoxY + (Theme.paddingHeight / 2) + textHeight * 1.5, Theme.notificationTextColor, null, null, 2,
                Theme.textShadow);
        }
    }
    #end

    #if server
    var busy = false;
    var stack:Array<Notification> = [];

    public function notifyAll(message:String, ?minDisplayTime:Null<Float>, ?maxDisplayTime:Null<Float>) {
        final note = buildNotification(message, minDisplayTime, maxDisplayTime);
        if (busy) {
            stack.push(note);
            return;
        }
        processNotification(note);
    }

    public function announceWinner(player:Player) {
        final isNull = player == null;
        NetLib.Start("mdg.net.winnerannouncement");
        NetLib.WriteBool(!isNull);
        NetLib.WriteEntity(if (!isNull) player else EntsLib.GetByIndex(0));
        NetLib.Broadcast();
    }

    public function reset() {
        busy = false;
        broadcast("");
        announceWinner(null);
        TimerLib.Remove("mdg.timer.notification.max");
        TimerLib.Remove("mdg.timer.notification.min");
        stack = [];
    }

    function processNotification(note:Notification) {
        TimerLib.Remove("mdg.timer.notification.max");
        busy = true;
        broadcast(note.message);
        TimerLib.Create("mdg.timer.notification.min", note.minTime, 1, () -> {
            if (stack.length > 0) {
                processNotification(stack.pop());
            } else {
                busy = false;
                final diff = note.maxTime - note.minTime;
                if (diff < 0) {
                    broadcast("");
                    return;
                }
                TimerLib.Create("mdg.timer.notification.max", diff, 1, () -> {
                    broadcast("");
                });
            }
        });
    }

    function buildNotification(message:String, ?minDisplayTime:Null<Float>, ?maxDisplayTime:Null<Float>):Notification {
        return {
            message: message,
            minTime: if (minDisplayTime != null) minDisplayTime else 0,
            maxTime: if (maxDisplayTime != null) maxDisplayTime else 5
        }
    }

    function broadcast(msg:String) {
        NetLib.Start("mdg.net.notification");
        NetLib.WriteString(msg);
        NetLib.Broadcast();
    }
    #end
}
