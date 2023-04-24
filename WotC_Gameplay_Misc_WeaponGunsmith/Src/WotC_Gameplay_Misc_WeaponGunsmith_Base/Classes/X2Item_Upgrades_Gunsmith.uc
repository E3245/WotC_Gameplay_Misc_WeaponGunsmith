class X2Item_Upgrades_Gunsmith extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateBasicCritUpgrade());
	
	return Items;
}

static function X2DataTemplate CreateBasicCritUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'GunsmithInternalMod');

	Template.CanApplyUpgradeToWeaponFn = NoUpgradeAllowed;
	
	return Template;
}

static function bool NoUpgradeAllowed(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex)
{
	return false;
}