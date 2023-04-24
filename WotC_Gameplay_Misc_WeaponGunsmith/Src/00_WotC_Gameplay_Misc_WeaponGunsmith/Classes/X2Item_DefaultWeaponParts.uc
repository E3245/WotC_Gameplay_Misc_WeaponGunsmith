class X2Item_DefaultWeaponParts extends X2Item
	config(WeaponPart);

var config array<name> WeaponPartTemplateNames;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2ConfigWeaponPartTemplate Template;
	local name PartName;

	foreach default.WeaponPartTemplateNames(PartName)
	{
		`CREATE_X2TEMPLATE(class'X2ConfigWeaponPartTemplate', Template, PartName);
		Templates.AddItem(Template);
	}

	return Templates;
}