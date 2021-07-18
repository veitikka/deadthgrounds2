package mdg;

import gmod.Gmod;

class Theme {
    public static function rgbPercentage(fl: Float): Float {
        return fl / 255;
    }

    public static final sphereColor = Gmod.Color(178, 25, 25);
    public static final textColor = Gmod.Color(255, 255, 255);
    public static final textShadow = Gmod.Color(32, 32, 32, 40);
    public static final notificationColor = Gmod.Color(25, 25, 30, 200);
    public static final notificationTextColor = Gmod.Color(255, 255, 255);

    public static final paddingWidth = 64;
    public static final paddingHeight = 16;
    public static final cornerRadius = 4;

    public static final scoreBoardMargin = 8;
    public static final scoreBoardPadding = 4;
}
