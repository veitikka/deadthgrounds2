package mdg.structs;

typedef Mission = {
    lobbyspawns: Array<Pos>,
    gamespawns: Array<Pos>,
    dronespawns: Array<Pos>,
    finales: Array<Pos>,
    weapons: {
        small: Array<PosAng>,
        medium: Array<PosAng>,
        large: Array<PosAng>,
        ammo: Array<PosAng>
    },
    items: {
        medical: Array<PosAng>,
        armor: Array<PosAng>,
        misc: Array<PosAng>
    },
    vehicles: {
        small: Array<PosAng>,
        medium: Array<PosAng>,
        large: Array<PosAng>,
    },
    helicopters: Array<PosAng>,
    supplies: Array<Pos>
}

typedef Pos = {
    pos: Array<Float>
}

typedef PosAng = {
    pos: Array<Float>,
    ang: Array<Float>
}
