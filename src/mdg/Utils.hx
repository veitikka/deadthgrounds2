package mdg;

import gmod.gclass.Angle;
import gmod.gclass.Vector;

inline function spawnSimfphys(vehicleName: String, position: Vector, angles: Angle) {
    untyped __lua__('simfphys.SpawnVehicleSimple(${vehicleName}, Vector(${position.x}, ${position.y}, ${position.z}), Angle(${angles.p}, ${angles.y}, ${angles.r}))');
}
