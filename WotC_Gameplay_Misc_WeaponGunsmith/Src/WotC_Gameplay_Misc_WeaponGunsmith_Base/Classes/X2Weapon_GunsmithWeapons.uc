class X2Weapon_GunsmithWeapons extends X2Item
	config(Weapon);

// Pairs a weapon with an existing weapon in XComHeaquarters.
struct HQWeaponPair
{
	var name TemplateName;
	var name ReqItem;
};

var config array<HQWeaponPair> WeaponTemplates;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2WeaponTemplate> Templates;
	local X2ConfigWeaponAlphaTemplate Template;
	local HQWeaponPair WeaponData;

	foreach default.WeaponTemplates(WeaponData)
	{
		`CREATE_X2TEMPLATE(class'X2ConfigWeaponAlphaTemplate', Template, WeaponData.TemplateName);
		
		// Convert to usuable common Weapon Template
		Template.ConvertToWeaponTemplate();

		if (Template.m_nGlobalStatSelect != '' || Template.m_nGlobalStatSelect != 'None')
		{
			class'X2Item_Weapon_GlobalStats'.static.UseGlobalStatsForWeapon(Template);
		}

		Templates.AddItem(Template);
	}

	return Templates;
}