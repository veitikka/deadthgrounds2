package mdg.ents;

import gmod.sent.ENT_ANIM;
import gmod.helpers.sent.SentBuild;

class Base_GmodEntity extends SentBuild<ENT_ANIM> {

    final properties:EntFields = {
        Base : "base_anim",
        Spawnable: false
        
    }

    override function Initialize() {

    }
}
