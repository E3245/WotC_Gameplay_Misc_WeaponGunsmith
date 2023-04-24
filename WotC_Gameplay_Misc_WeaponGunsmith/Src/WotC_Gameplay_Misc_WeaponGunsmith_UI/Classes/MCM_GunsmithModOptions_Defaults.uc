class MCM_GunsmithModOptions_Defaults extends Object config(MCM_GunsmithModOptions_Default);

// Upgrades allow players to edit parts of a weapon. By default only the receiver is customizable.
var config bool bUpgradesUnlockWeaponPartCategory;

// Disables filtering on weapons, making every part available to equip on any weapons.
var config bool bCursedWeaponMode;

var config int VERSION;