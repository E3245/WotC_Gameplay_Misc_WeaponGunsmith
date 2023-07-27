// Component state of XCGS_Item, stores cosmetic information about certain weapons
class XCGS_WeaponGunsmith extends XComGameState_BaseObject;

var bool bIsModified;	// If the weapon was modified in some fashion
var() name							WeaponTemplateName;
var() bool							bPreview_UseOnlyFirstAvaliable; // If set, forces the weapon to use the first available template.

// Currently equipped parts. Not recommended to remove the protected keyword.
var() protected X2ConfigWeaponPartTemplate ReceiverTemplate;
var() protected X2ConfigWeaponPartTemplate BarrelTemplate;
var() protected X2ConfigWeaponPartTemplate HandguardTemplate; 
var() protected X2ConfigWeaponPartTemplate StockTemplate;
var() protected X2ConfigWeaponPartTemplate MagazineTemplate;
var() protected X2ConfigWeaponPartTemplate ReargripTemplate;
var() protected X2ConfigWeaponPartTemplate UnderbarrelTemplate;
var() protected X2ConfigWeaponPartTemplate OpticsTemplate;
var() protected X2ConfigWeaponPartTemplate LaserTemplate;
var() protected X2ConfigWeaponPartTemplate MuzzleTemplate;

var() array<name> arrInstalledWeaponPartNames;

// Assigned on creation, these are the default templates that this GS will refer back to whenever a change is made
var() protected X2ConfigWeaponPartTemplate DefaultReceiverTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultBarrelTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultHandguardTemplate; 
var() protected X2ConfigWeaponPartTemplate DefaultStockTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultMagazineTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultReargripTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultUnderbarrelTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultOpticsTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultLaserTemplate;
var() protected X2ConfigWeaponPartTemplate DefaultMuzzleTemplate;

var() array<name> arrDefaultWeaponPartNames;

var() array<WeaponCustomizationData> arrWeaponCustomizationParts;	// Array of elements that defines what camo/color each part should have

function OnInit(name newWeaponTemplate)
{
	WeaponTemplateName = newWeaponTemplate;

	arrInstalledWeaponPartNames.Length = 0;
	arrDefaultWeaponPartNames.Length = 0;

	arrInstalledWeaponPartNames.Add(PT_MAX);
	arrDefaultWeaponPartNames.Add(PT_MAX);
}

// Accessor functions
function X2ConfigWeaponPartTemplate GetPartTemplate(WeaponPartType Type, optional bool bReturnDefault)
{
	local X2ConfigWeaponPartTemplate Template;
	local name						 TemplateName;
	local X2ItemTemplateManager		 ItemMgr;

	switch(Type)
	{
		case PT_RECEIVER:
			Template = (bReturnDefault == true) ? DefaultReceiverTemplate : ReceiverTemplate;
			break;
		case PT_BARREL:
			Template = (bReturnDefault == true) ? DefaultBarrelTemplate : BarrelTemplate;
			break;
		case PT_HANDGUARD:
			Template = (bReturnDefault == true) ? DefaultHandguardTemplate : HandguardTemplate; 
			break;
		case PT_STOCK:
			Template = (bReturnDefault == true) ? DefaultStockTemplate : StockTemplate;
			break;
		case PT_MAGAZINE:
			Template = (bReturnDefault == true) ? DefaultMagazineTemplate : MagazineTemplate;
			break;
		case PT_REARGRIP:
			Template = (bReturnDefault == true) ? DefaultReargripTemplate : ReargripTemplate;
			break;
		case PT_MUZZLE:
			Template = (bReturnDefault == true) ? DefaultMuzzleTemplate : MuzzleTemplate;
			break;
		case PT_UNDERBARREL:
			Template = (bReturnDefault == true) ? DefaultUnderbarrelTemplate : UnderbarrelTemplate;
			break;
		case PT_LASER:
			Template = (bReturnDefault == true) ? DefaultLaserTemplate : LaserTemplate;
			break;
		case PT_OPTIC:
			Template = (bReturnDefault == true) ? DefaultOpticsTemplate : OpticsTemplate;
			break;
		// Spit out error
		case PT_NONE:
		case PT_MAX:
			break;
	}

	// If this happens, then we lost our references and need to pull them from the Item Manager state again
	if (Template == none)
	{
		ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		TemplateName = (bReturnDefault == true) ? arrDefaultWeaponPartNames[Type] : arrInstalledWeaponPartNames[Type];

		Template = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(TemplateName));
	}

	//`LOG("Called " $ GetFuncName() $ " for part " $ Type $ ". Got template: " $ Template.DataName,, 'WotC_Gameplay_Misc_WeaponGunsmith');

	return Template;
}

// Setter functions
function SetPartTemplate(X2ConfigWeaponPartTemplate newTemplate, WeaponPartType Type, optional bool bOverrideDefault, optional bool bVerifyReceiverComponents)	
{
	//`LOG("Setting " $ WeaponPartType(Type) $ " " $ newTemplate.DataName $ " for Template " $ WeaponTemplateName $ " with ObjectID: " $ ObjectID,, 'WotC_Gameplay_Misc_WeaponGunsmith');

	switch(Type)
	{
		case PT_RECEIVER:
			ReceiverTemplate = newTemplate;

			if (bOverrideDefault) { DefaultReceiverTemplate = newTemplate; }

			if (bVerifyReceiverComponents)
				VerifyWeaponPartTemplate(ReceiverTemplate);
			break;
		case PT_BARREL:
			BarrelTemplate = newTemplate;

			if (bOverrideDefault) { DefaultBarrelTemplate = newTemplate; }

			// V1.005: Check if we need to pop off some attachments
			if (newTemplate.bBarrel_IgnoreValidParts)
			{
				MuzzleTemplate = DefaultMuzzleTemplate;
				arrInstalledWeaponPartNames[PT_MUZZLE] = arrDefaultWeaponPartNames[PT_MUZZLE];
			}

			if ((newTemplate.bBarrel_PreventUBWeap && UnderbarrelTemplate.bUnderbarrel_IsWeap) ||
				(newTemplate.bBarrel_PreventUBGrips && UnderbarrelTemplate.bUnderbarrel_IsGrip)
				)
			{
				UnderbarrelTemplate = DefaultUnderbarrelTemplate;
				arrInstalledWeaponPartNames[PT_UNDERBARREL] = arrDefaultWeaponPartNames[PT_UNDERBARREL];
			}
			break;
		case PT_HANDGUARD:
			HandguardTemplate = newTemplate;

			if (bOverrideDefault) { DefaultHandguardTemplate = newTemplate; }
			break;
		case PT_STOCK:
			StockTemplate = newTemplate;

			if (bOverrideDefault) { DefaultStockTemplate = newTemplate; }
			break;
		case PT_MAGAZINE:
			MagazineTemplate = newTemplate;

			if (bOverrideDefault) { DefaultMagazineTemplate = newTemplate; }
			break;
		case PT_REARGRIP:
			ReargripTemplate = newTemplate;

			if (bOverrideDefault) { DefaultReargripTemplate = newTemplate; }
			break;
		case PT_MUZZLE:
			MuzzleTemplate = newTemplate;

			if (bOverrideDefault) { DefaultMuzzleTemplate = newTemplate; }
			break;
		case PT_UNDERBARREL:
			UnderbarrelTemplate = newTemplate;

			if (bOverrideDefault) { DefaultUnderbarrelTemplate = newTemplate; }
			break;
		case PT_LASER:
			LaserTemplate = newTemplate;

			if (bOverrideDefault) { DefaultLaserTemplate = newTemplate; }
			break;
		case PT_OPTIC:
			OpticsTemplate = newTemplate;

			if (bOverrideDefault) { DefaultOpticsTemplate = newTemplate; }
			break;
		// Spit out error
		case PT_NONE:
			break;
	}

	arrInstalledWeaponPartNames[Type] = newTemplate.DataName;

	if (bOverrideDefault)
		arrDefaultWeaponPartNames[Type] = newTemplate.DataName; 
}

// Checks if components of the receiver are valid for this weapon
// Reverts parts to the first entry in the array, then the weapon template's default part, if it fails to find the part
function VerifyWeaponPartTemplate(X2ConfigWeaponPartTemplate NewReceiverTemplate)
{
	local X2ItemTemplateManager			ItemMgr;
	local X2ConfigWeaponPartTemplate	PartTemplate;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Barrel
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Barrel.Find(BarrelTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Barrel[0]));

		if (PartTemplate != none)
			BarrelTemplate = PartTemplate;
		else
			BarrelTemplate = DefaultBarrelTemplate;

		arrInstalledWeaponPartNames[PT_BARREL] = BarrelTemplate.DataName;
	}

	// Stock
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Stock.Find(StockTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Stock[0]));

		if (PartTemplate != none)
			StockTemplate = PartTemplate;
		else
			StockTemplate = DefaultStockTemplate;

		arrInstalledWeaponPartNames[PT_STOCK] = StockTemplate.DataName;
	}

	// Handguard
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Handguard.Find(HandguardTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Handguard[0]));

		if (PartTemplate != none)
			HandguardTemplate = PartTemplate;
		else
			HandguardTemplate = DefaultHandguardTemplate;

		arrInstalledWeaponPartNames[PT_HANDGUARD] = HandguardTemplate.DataName;
	}

	// Magazine
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Magazine.Find(MagazineTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Magazine[0]));

		if (PartTemplate != none)
			MagazineTemplate = PartTemplate;
		else
			MagazineTemplate = DefaultMagazineTemplate;

		arrInstalledWeaponPartNames[PT_MAGAZINE] = MagazineTemplate.DataName;
	}

	// Reargrip
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Reargrip.Find(ReargripTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Reargrip[0]));

		if (PartTemplate != none)
			ReargripTemplate = PartTemplate;
		else
			ReargripTemplate = DefaultReargripTemplate;

		arrInstalledWeaponPartNames[PT_REARGRIP] = ReargripTemplate.DataName;
	}

	// Underbarrel
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Underbarrel.Find(UnderbarrelTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Underbarrel[0]));

		if (PartTemplate != none)
			UnderbarrelTemplate = PartTemplate;
		else
			UnderbarrelTemplate = DefaultUnderbarrelTemplate;

		arrInstalledWeaponPartNames[PT_UNDERBARREL] = UnderbarrelTemplate.DataName;
	}

	// Optics
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Optics.Find(OpticsTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Optics[0]));

		if (PartTemplate != none)
			OpticsTemplate = PartTemplate;
		else
			OpticsTemplate = DefaultOpticsTemplate;

		arrInstalledWeaponPartNames[PT_OPTIC] = OpticsTemplate.DataName;
	}

	// Laser
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Laser.Find(LaserTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Laser[0]));

		if (PartTemplate != none)
			LaserTemplate = PartTemplate;
		else
			LaserTemplate = DefaultLaserTemplate;

		arrInstalledWeaponPartNames[PT_LASER] = LaserTemplate.DataName;
	}

	// Muzzle
	if (bPreview_UseOnlyFirstAvaliable || NewReceiverTemplate.ValidParts_Muzzle.Find(MuzzleTemplate.DataName) == INDEX_NONE)
	{
		PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(NewReceiverTemplate.ValidParts_Muzzle[0]));

		if (PartTemplate != none)
			MuzzleTemplate = PartTemplate;
		else
			MuzzleTemplate = DefaultMuzzleTemplate;

		arrInstalledWeaponPartNames[PT_MUZZLE] = MuzzleTemplate.DataName;
	}
}

function bool ShouldUseRifleGrip()
{
	local X2ConfigWeaponPartTemplate CurrentStockTemplate, CurrentReargripTemplate;

	CurrentStockTemplate		= GetPartTemplate(PT_STOCK);
	CurrentReargripTemplate		= GetPartTemplate(PT_REARGRIP);

	return (CurrentStockTemplate.bActivateRifleGrip || CurrentReargripTemplate.bActivateRifleGrip);
}

//
// CUSTOMIZATION FUNCTIONS
//
function ApplyCustomization(WeaponPartType Type, WeaponCustomizationData NewCustomizationData)
{
	arrWeaponCustomizationParts[Type] = NewCustomizationData;
}

// V1.005: Set the default color on this gamestate
function SetDefaultCustomizationState(TWeaponAppearance WepAppearance)
{
	local int						i;
	
	arrWeaponCustomizationParts.Add(PT_MAX);

	for(i = 0; i < PT_MAX; ++i)
	{
		arrWeaponCustomizationParts[i].CamoTemplateName = WepAppearance.nmWeaponPattern;
		arrWeaponCustomizationParts[i].iPrimaryTintPaletteIdx = WepAppearance.iWeaponTint;
	}
}

function ResetWeaponStateToDefault()
{
	ReceiverTemplate		= DefaultReceiverTemplate;
	BarrelTemplate			= DefaultBarrelTemplate;
	HandguardTemplate		= DefaultHandguardTemplate;
	StockTemplate			= DefaultStockTemplate;
	MagazineTemplate		= DefaultMagazineTemplate;
	ReargripTemplate		= DefaultReargripTemplate;
	UnderbarrelTemplate		= DefaultUnderbarrelTemplate;
	OpticsTemplate			= DefaultOpticsTemplate;
	LaserTemplate			= DefaultLaserTemplate;
	MuzzleTemplate			= DefaultMuzzleTemplate;

	// Reset flag to revert naming scheme to default
	bIsModified = false;
}