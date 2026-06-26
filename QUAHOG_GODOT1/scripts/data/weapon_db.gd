extends RefCounted
class_name WeaponDB




const SFX: = "res://assets/audio/sfx/weapon/"

const WEAPONS: = {
    "fists": {
        "name": "Fists", "melee": true, "damage": 1, "rate": 0.45, "range": 2.3, 
        "model": "", "len": 0.0, "heat": 0, "price": 0, 
        "swing": SFX + "weapon_melee_swing.mp3", "hit": SFX + "weapon_melee_hit.mp3", 
    }, 
    "pistol": {
        "name": "Pistol", "melee": false, "damage": 1, "rate": 0.22, "range": 90.0, 
        "clip": 12, "pellets": 1, "spread": 0.008, "auto": false, 
        "model": "res://assets/props/weapons/pistol.glb", "len": 0.34, "heat": 1, "price": 0, 
        "ammo_buy": 36, "ammo_price": 25, 
        "shot": SFX + "weapon_pistol_shot.mp3", "reload": SFX + "weapon_pistol_reload.mp3", 
        "impact": SFX + "weapon_bullet_impact.mp3", 
    }, 
    "shotgun": {
        "name": "Shotgun", "melee": false, "damage": 1, "rate": 0.8, "range": 30.0, 
        "clip": 6, "pellets": 8, "spread": 0.075, "auto": false, 
        "model": "res://assets/props/weapons/shotgun.glb", "len": 0.9, "heat": 2, "price": 350, 
        "ammo_buy": 18, "ammo_price": 40, 
        "shot": SFX + "weapon_shotgun_blast.mp3", "reload": SFX + "weapon_pistol_reload.mp3", 
        "impact": SFX + "weapon_bullet_impact.mp3", 
    }, 
    "rifle": {
        "name": "Rifle", "melee": false, "damage": 1, "rate": 0.11, "range": 80.0, 
        "clip": 30, "pellets": 1, "spread": 0.022, "auto": true, 
        "model": "res://assets/props/weapons/rifle.glb", "len": 0.9, "heat": 2, "price": 700, 
        "ammo_buy": 90, "ammo_price": 60, 
        "shot": SFX + "weapon_rifle_shot.mp3", "reload": SFX + "weapon_pistol_reload.mp3", 
        "impact": SFX + "weapon_bullet_impact.mp3", 
    }, 
    "bat": {
        "name": "Bat", "melee": true, "damage": 2, "rate": 0.42, "range": 2.9, 
        "model": "res://assets/props/weapons/bat.glb", "len": 0.9, "heat": 1, "price": 120, 
        "swing": SFX + "weapon_melee_swing.mp3", "hit": SFX + "weapon_melee_hit.mp3", 
    }, 
}


const ORDER: = ["fists", "bat", "pistol", "shotgun", "rifle"]


static func get_def(id: String) -> Dictionary:
    return WEAPONS.get(id, WEAPONS["fists"])

static func is_melee(id: String) -> bool:
    return bool(get_def(id).get("melee", false))
