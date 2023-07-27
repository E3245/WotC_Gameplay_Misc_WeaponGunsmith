//
// 2/25/23: Adds Weaponsmith logic
class X2ConfigWeaponAlphaTemplate extends X2WeaponTemplate config(Weapon) dependson(XCGS_WeaponGunsmith);

//Engineering Definitions
struct EngineeringBuildDefs
{
	var name RequiredTech1;
	var name RequiredTech2;
	var int RequiredEngineeringScore;
	var int PointsToComplete;
	var int SupplyCost;
	var int AlloyCost;
	var int CrystalCost;
	var int CoreCost;
	var name SpecialItemTemplateName;
	var int SpecialItemCost;
	var int TradingPostValue;
};

//Weapon Definitons
struct WeaponAbilitiesDefs
{
	var name AbilityName;
	var string IconOverrideName;

	structdefaultproperties
	{
		AbilityName = none;
		IconOverrideName = "";
	}
};

//Weapon Stat Modifiers
struct WeaponStatModifiers
{
	var ECharStatType StatName;
	var int StatModValue;

	structdefaultproperties
	{
		StatName = eStat_Invalid;
		StatModValue = 0;
	}
};

struct WeaponPartStruct
{
	var WeaponPartType Part;
	var name PartTemplateName;
};

var config name             m_nWeaponCat				<ToolTip="must match one of the entries in X2ItemTemplateManager's WeaponCategories">;
var config name             m_nWeaponTech					<ToolTip="must match one of the entires in X2ItemTemplateManager's WeaponTechCategories">;
var config name			    m_nUIArmoryCameraPointTag		<ToolTip="The tag of the point in space in the UI armory map where this weapon should be located by default">;
var config ELocation        m_EStowedLocation				<ToolTip="physical attach point to model when not in-hands">;
var config string           m_sWeaponPanelImage			<ToolTip="UI resource for weapon image">;
var config bool             m_bMergeAmmo					<ToolTip="If this item is in the unit's inventory multiple times, the ammo will be consolidated.">;
var config name             m_nArmorTechCatForAltArchetype <ToolTip="If this field is set, it will load the AltGameArchetype when the unit is wearing armor that matches it.">;
var config EGender		    m_EGenderForAltArchetype		<ToolTip ="If this field is set, it will load the AltGameArchetype when the units gender matches.">;

//  Combat related stuff
var config int              m_iEnvironmentDamage     <ToolTip = m_K"damage to environmental effects; should be 50, 100, or 150.">;
var config int              m_iRange                 <ToolTip = m_K"-1 will mean within the unit's sight, 0 means melee">;
var config int              m_iRadius                <ToolTip = m_K"radius in METERS for AOE range">;
var config float            m_fCoverage              <ToolTip = m_K"percentage of tiles within the radius to affect">;
var config int              m_iTypicalActionCost     <ToolTip = m_K"typical cost in action points to fire the weapon (only used by some abilities)">;
var config int              m_iClipSize              <ToolTip="ammo amount before a reload is required">;
var config bool             m_bInfiniteAmmo           <ToolTip="no reloading required!">;
var config int              m_iAim;
var config int              m_iCritChance;
var config name             m_nDamageTypeTemplateName				<ToolTip = m_K"Template name for the type of ENVIRONMENT damage this weapon does">;
var config array<int>       m_aRangeAccuracy						<ToolTip = m_K"Array of accuracy modifiers, where index is tiles distant from target.">;
var config int              m_iSoundRange							<ToolTip="Range in Meters, for alerting enemies.  (Yellow alert)">;
var config bool			    m_bSoundOriginatesFromOwnerLocation   <ToolTip="True for all except grenades(?)">;
var config bool			    m_bIsLargeWeapon						<ToolTip="Used in Weapon Upgrade UI to determine distance from camera.">;
var config name             m_nOverwatchActionPoint				<ToolTip="Action point type to reserve when using Overwatch with this weapon.">;
var config int              m_iIdealRange                         <ToolTip="the unit's ideal range when using this weapon; only used by the AI. (NYI)">;
var config bool             m_bCanBeDodged;
var config bool			    m_bUseArmorAppearance					<ToolTip = m_K"This weapon will use the armor tinting values instead of the weapons">;
var config bool			    m_bIgnoreRadialBlockingCover;

var config WeaponDamageValue            m_KBaseDamage;  
var config array<WeaponDamageValue>     m_KExtraDamage;

var config bool                         m_bOverrideConcealmentRule;
var config EConcealmentRule             m_EOverrideConcealmentRule;  //  this is only used if bOverrideConcealmentRule is true

//  Upgrades
var config int                                  m_iNumUpgradeSlots             <ToolTip="Number of weapon slots available">;

// Cosmetic data
var config int                                  m_iPhysicsImpulse           <ToolTip="Determines the force within the physics system to apply to objects struck by this weapon">;

var config float                                m_fKnockbackDamageAmount		<ToolTip = m_K"Damage amount applied to the environment on knock back.">;
var config float                                m_fKnockbackDamageRadius		<ToolTip = m_K"Radius of the affected area at hit tile locations.">;

var config array<WeaponAttachment>				m_aDefaultAttachments;

var config PrecomputedPathData                  m_KWeaponPrecomputedPathData;

var config bool                                 m_bDisplayWeaponAndAmmo     <ToolTip="If set true, this will display in the lower right corner if set as a primary weapon.">;

// Item stat flags
var config bool			                        m_bHideDamageStat;
var config bool				                    m_bHideClipSizeStat;

var config array<AbilityAnimationOverride>		m_KAbilitySpecificAnimations;
var config bool                                 m_bHideWithNoAmmo <ToolTip="If true, the weapon mesh will be hidden upon loading a save if it has no ammo.">;

var config array<WeaponStatModifiers>			m_aStatChanges;

// Usuable Stat Change array for effects, etc.
var array<StatChange>							EffectStatChanges;

var config int									m_iReactionFireAim;
var config name									m_nGlobalStatSelect;

var config array<WeaponAbilitiesDefs>			m_aAbilities;

var config int									m_iTier;
var config string								m_sUIImage;
var config string								m_sEquipSound;

var config bool									m_bStartingItem;
var config bool									m_bInfiniteItem;
var config bool									m_bCanBeBuilt;

var config EngineeringBuildDefs					m_KBuildRequirements;

var config name									m_nCreatorTemplateName;
var config name									m_nBaseItem;

var config string								m_sGameArchetype;
var config string								m_sAltGameArchetype;

// Weaponsmith Upgrade system
var config name									m_nDefaultReceiverTemplate;
var config name									m_nDefaultBarrelTemplate;
var config name									m_nDefaultHandguardTemplate;
var config name									m_nDefaultStockTemplate;
var config name									m_nDefaultMagazineTemplate;
var config name									m_nDefaultReargripTemplate;
var config name									m_nDefaultUnderbarrelTemplate;
var config name									m_nDefaultLaserTemplate;
var config name									m_nDefaultOpticsTemplate;
var config name									m_nDefaultMuzzleTemplate;

// Converts this template into proper usable weapon  Must be used as an instanced function, and called during the creation cycle.
function ConvertToWeaponTemplate()
{
	local WeaponAbilitiesDefs		AbilityData;
	local WeaponStatModifiers		StatMod;
//	local AbilityAnimationOverride	AnimOverrideData;
	local ArtifactCost				Resources;

    WeaponCat					= m_nWeaponCat;
    WeaponTech					= m_nWeaponTech;

	// UI
    UIArmoryCameraPointTag		= m_nUIArmoryCameraPointTag;
	Tier						= m_iTier;
	EquipSound					= m_sEquipSound;
	strImage					= m_sUIImage;
    StowedLocation				= m_EStowedLocation;
    WeaponPanelImage			= m_sWeaponPanelImage;

	// Visuals
    ArmorTechCatForAltArchetype = m_nArmorTechCatForAltArchetype;
    GenderForAltArchetype		= m_EGenderForAltArchetype;
	GameArchetype				= m_sGameArchetype;
	AltGameArchetype			= m_sAltGameArchetype;
    bUseArmorAppearance			= m_bUseArmorAppearance;
    DefaultAttachments			= m_aDefaultAttachments;

    AbilitySpecificAnimations	= m_KAbilitySpecificAnimations;

	// Item stuff
	CreatorTemplateName			= m_nCreatorTemplateName;
	BaseItem					= m_nBaseItem;
	bInfiniteItem				= m_bInfiniteItem;
	StartingItem				= m_bStartingItem;

	// Gameplay Stats
	RangeAccuracy				= m_aRangeAccuracy;
	BaseDamage					= m_KBaseDamage;
	ExtraDamage					= m_KExtraDamage;
	
	iClipSize					= m_iClipSize;
	Aim							= m_iAim;
	CritChance					= m_iCritChance;
	NumUpgradeSlots				= m_iNumUpgradeSlots;

    iRange						= m_iRange;
	iIdealRange					= m_iIdealRange;

    iRadius						= m_iRadius;
    fCoverage					= m_fCoverage;

	iSoundRange					= m_iSoundRange;
	iEnvironmentDamage			= m_iEnvironmentDamage;

	// Cannot be less than 0
    if (m_iTypicalActionCost < 0)
        iTypicalActionCost = 1;
    else
        iTypicalActionCost = m_iTypicalActionCost;

    if (m_nDamageTypeTemplateName == '')
        DamageTypeTemplateName = 'DefaultProjectile';
    else
        DamageTypeTemplateName = m_nDamageTypeTemplateName;

	// Cannot be blank, fallback to overwatch instead
    if (m_nOverwatchActionPoint	 == '')
        OverwatchActionPoint = 'overwatch';   
    else
        OverwatchActionPoint = m_nOverwatchActionPoint;

    iPhysicsImpulse = m_iPhysicsImpulse;

    fKnockbackDamageAmount = m_fKnockbackDamageAmount;
    fKnockbackDamageRadius = m_fKnockbackDamageRadius;

    bSoundOriginatesFromOwnerLocation = m_bSoundOriginatesFromOwnerLocation;

    WeaponPrecomputedPathData = m_KWeaponPrecomputedPathData;

	foreach m_aStatChanges(StatMod)
	{
		if (StatMod.StatModValue != 0)
		{
			SetupMarkupStats(StatMod.StatName, StatMod.StatModValue);
			AddPersistentStatChange(StatMod.StatName, StatMod.StatModValue);
		}
	}

	//Abilities Loop
	if (m_aAbilities.Length > 0)
	{
		//Loop until the end of the length of the array
		foreach m_aAbilities(AbilityData)
		{
			//Add the ability name at index [i]
			Abilities.AddItem(AbilityData.AbilityName);
			//Check if the name at index [i] also has a IconOverrideName string. 
			//It doesn't check if the string is valid though
			if (Len(AbilityData.IconOverrideName) > 0)
			{
				AddAbilityIconOverride(AbilityData.AbilityName, AbilityData.IconOverrideName);
			}
		}
	}
	else
	{
		//Add the default abilities
		Abilities.AddItem('StandardShot');
		Abilities.AddItem('Overwatch');
		Abilities.AddItem('OverwatchShot');
		Abilities.AddItem('Reload');
		Abilities.AddItem('HotLoadAmmo');
	}

	//Stat Modifiers
	Abilities.AddItem('Ability_Weapon_StatModifier');
	Abilities.AddItem('Ability_Weapon_ReactionFireMod');

	// Extra gameplay variables
    bMergeAmmo					= m_bMergeAmmo;
    bCanBeDodged				= m_bCanBeDodged;
    
	bIgnoreRadialBlockingCover	= m_bIgnoreRadialBlockingCover;

    bOverrideConcealmentRule	= m_bOverrideConcealmentRule;
    OverrideConcealmentRule		= m_EOverrideConcealmentRule;
    bHideWithNoAmmo				= m_bHideWithNoAmmo;
    bDisplayWeaponAndAmmo		= m_bDisplayWeaponAndAmmo;

	// Special setup for certain weapon categories
	switch (m_nWeaponCat)
	{
		case 'rifle':
		case 'shotgun':
		case 'bullpup':
			InventorySlot = eInvSlot_PrimaryWeapon;
			break;
		case 'sniper_rifle':
		case 'vektor_rifle':
			InventorySlot = eInvSlot_PrimaryWeapon;
			bIsLargeWeapon = true;
			
			iTypicalActionCost = 2;
			break;
		case 'cannon':
			bIsLargeWeapon = true;
			InventorySlot = eInvSlot_PrimaryWeapon;
			break;
		case 'sidearm':
		case 'pistol':
			InventorySlot = eInvSlot_SecondaryWeapon;
			OverwatchActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
			InfiniteAmmo = true;
			bHideClipSizeStat = true;

			//SetAnimationNameForAbility('FanFire', 'FF_FireMultiShotConvA');	// Do that in the config templates
			break;
		case 'sword':
			InventorySlot = eInvSlot_SecondaryWeapon;
			StowedLocation = eSlot_RightBack;
			InfiniteAmmo = true;

			iRange = 0;
			iRadius = 1;
			
			Abilities.Length = 0;
			break;
		default:
			InfiniteAmmo = m_bInfiniteAmmo;
			bIsLargeWeapon = m_bIsLargeWeapon;

			bHideDamageStat = m_bHideDamageStat;
			bHideClipSizeStat = m_bHideClipSizeStat;
			break;
	}

	// Strategy Cost and Single Build Functionality
	if (m_bCanBeBuilt)
	{
		Requirements.RequiredEngineeringScore		= m_KBuildRequirements.RequiredEngineeringScore;
		PointsToComplete							= m_KBuildRequirements.PointsToComplete;
		Requirements.bVisibleifPersonnelGatesNotMet = true;

		if (m_KBuildRequirements.RequiredTech1 != '')
		{
			Requirements.RequiredTechs.AddItem(m_KBuildRequirements.RequiredTech1);
		}
		if (m_KBuildRequirements.RequiredTech2 != '')
		{
			Requirements.RequiredTechs.AddItem(m_KBuildRequirements.RequiredTech2);
		}

		Cost.ResourceCosts.AddItem(Resources);

		if (m_KBuildRequirements.SupplyCost > 0)
		{
			Resources.ItemTemplateName = 'Supplies';
			Resources.Quantity = m_KBuildRequirements.SupplyCost;
			Cost.ResourceCosts.AddItem(Resources);
		}
		if (m_KBuildRequirements.AlloyCost > 0)
		{
			Resources.ItemTemplateName = 'AlienAlloy';
			Resources.Quantity = m_KBuildRequirements.AlloyCost;
			Cost.ResourceCosts.AddItem(Resources);
		}
		if (m_KBuildRequirements.CrystalCost > 0)
		{
			Resources.ItemTemplateName = 'EleriumDust';
			Resources.Quantity = m_KBuildRequirements.CrystalCost;
			Cost.ResourceCosts.AddItem(Resources);
		}
		if (m_KBuildRequirements.CoreCost > 0)
		{
			Resources.ItemTemplateName = 'EleriumCore';
			Resources.Quantity = m_KBuildRequirements.CoreCost;
			Cost.ResourceCosts.AddItem(Resources);
		}
		if (m_KBuildRequirements.SpecialItemTemplateName != '' && m_KBuildRequirements.SpecialItemCost > 0)
		{
			Resources.ItemTemplateName = m_KBuildRequirements.SpecialItemTemplateName;
			Resources.Quantity = m_KBuildRequirements.SpecialItemCost;
			Cost.ArtifactCosts.AddItem(Resources);
		}
	}

	// Add OnAcquiredFn that creates a component gamestate of our item
	//OnAcquiredFn = OnAcquiredGunsmithTypeWeapon;
	OnEquippedFn 	= OnEquippedGunsmithTypeWeapon;
	OnUnequippedFn 	= OnUnequippedGunsmithTypeWeapon;
}

static function OnEquippedGunsmithTypeWeapon(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	BuildWeaponGunsmithComponentState(NewGameState, ItemState);
}

static function bool OnAcquiredGunsmithTypeWeapon(XComGameState NewGameState, XComGameState_Item ItemState)
{
	BuildWeaponGunsmithComponentState(NewGameState, ItemState);

	return true;	// The Item should be created
}

static function OnUnequippedGunsmithTypeWeapon(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XCGS_WeaponGunsmith 			WeaponGunsmithState;

	WeaponGunsmithState = XCGS_WeaponGunsmith(ItemState.FindComponentObject(class'XCGS_WeaponGunsmith'));

	// Delete our GS state if this weapon is not modified in any way
	if (WeaponGunsmithState != none && WeaponGunsmithState.bIsModified == false)
	{
		//`LOG("Removing State: " $ WeaponGunsmithState.ObjectID $ " from Item [" $ ItemState.ObjectID $ "] " $ ItemState.GetMyTemplateName(),, 'WotC_Gameplay_Misc_WeaponGunsmith');

		ItemState.RemoveComponentObject(WeaponGunsmithState);
		NewGameState.RemoveStateObject(WeaponGunsmithState.ObjectID);
	}
}

// V1.005: Improved creation delegate to account for bad Gamestates due to mod update
static function BuildWeaponGunsmithComponentState(XComGameState NewGameState, XComGameState_Item ItemState)
{
	local XCGS_WeaponGunsmith 			WeaponGunsmithState, ModifiedGSState;
	local X2ConfigWeaponAlphaTemplate	WeaponTemplate;
	local byte i;
	local bool	bRequireCreation;

	WeaponGunsmithState = XCGS_WeaponGunsmith(ItemState.FindComponentObject(class'XCGS_WeaponGunsmith'));
	WeaponTemplate = X2ConfigWeaponAlphaTemplate(ItemState.GetMyTemplate());
	ModifiedGSState = none;

	// Generate a new tracker state if none exist
	if (WeaponGunsmithState == none)
		bRequireCreation = true;
	
	// Sometimes a mod update can destroy GS weapon state. If this happens, reset options to default
	if (WeaponGunsmithState != none && WeaponGunsmithState.arrInstalledWeaponPartNames.Length == 0)
	{
		ModifiedGSState = XCGS_WeaponGunsmith(NewGameState.ModifyStateObject(class'XCGS_WeaponGunsmith', WeaponGunsmithState.ObjectID));

		for (i = PT_RECEIVER; i < PT_MAX; i++)
			ModifiedGSState.SetPartTemplate(WeaponTemplate.GetDefaultWeaponPartTemplate(WeaponPartType(i)), WeaponPartType(i), true);
	}

	// If our weapon customization stuff isn't initialized properly due to a mod update, re-create it from scratch
	if (WeaponGunsmithState != none && WeaponGunsmithState.arrWeaponCustomizationParts.Length == 0)
	{
		if (ModifiedGSState == none)
			ModifiedGSState = XCGS_WeaponGunsmith(NewGameState.ModifyStateObject(class'XCGS_WeaponGunsmith', WeaponGunsmithState.ObjectID));

		// Copy Appearance from ItemState
		ModifiedGSState.SetDefaultCustomizationState(ItemState.WeaponAppearance);
	}

	if (bRequireCreation)
	{
		WeaponGunsmithState = XCGS_WeaponGunsmith(NewGameState.CreateNewStateObject(class'XCGS_WeaponGunsmith'));
		WeaponGunsmithState.OnInit( ItemState.GetMyTemplateName() );


		for (i = PT_RECEIVER; i < PT_MAX; i++)
			WeaponGunsmithState.SetPartTemplate(WeaponTemplate.GetDefaultWeaponPartTemplate(WeaponPartType(i)), WeaponPartType(i), true);

		// Copy Appearance from ItemState
		WeaponGunsmithState.SetDefaultCustomizationState(ItemState.WeaponAppearance);

		ItemState.AddComponentObject(WeaponGunsmithState);

		//`LOG("Created Gunsmith State: " $ WeaponGunsmithState.ObjectID $ " for Item [" $ ItemState.ObjectID $ "] " $ ItemState.GetMyTemplateName(),, 'WotC_Gameplay_Misc_WeaponGunsmith');
		return;
	}
}


//Putting the markup code here to speed things up
function SetupMarkupStats(ECharStatType StatName, float StatAmount)
{
	//Do not show stats if the Stat Amount is 0
	if (StatAmount > 0.000)
	{
		switch (StatName)
			{
			case(eStat_HP): 
				SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, StatAmount, true);
				break;
			case(eStat_Offense): 
				break;
			case(eStat_Defense): 
				break;
			case(eStat_Mobility): 
				SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, StatAmount);
				break;
			case(eStat_Will): 
				SetUIStatMarkup(class'XLocalizedData'.default.WillLabel, eStat_Will, StatAmount);
				break;
			case(eStat_Hacking): 
				break;
			case(eStat_SightRadius): 
				break;
			case(eStat_Dodge): 
				SetUIStatMarkup(class'XLocalizedData'.default.DodgeLabel, eStat_Dodge, StatAmount);
				break;
			case(eStat_ArmorMitigation): 
				SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, StatAmount);
				break;
			case(eStat_ArmorPiercing): 
				//Add WeaponBaseDamage.Pierce to the stat
				SetUIStatMarkup(class'XLocalizedData'.default.PierceLabel, eStat_ArmorPiercing, (StatAmount + BaseDamage.Pierce));
				break;
			case(eStat_PsiOffense): 
				break;
			case(eStat_HackDefense): 
				break;
			case(eStat_DetectionRadius): 
				break;
			case(eStat_DetectionModifier): 
				break;
			case(eStat_CritChance): 
				SetUIStatMarkup(class'XLocalizedData'.default.CriticalChanceBonusLabel, eStat_CritChance, StatAmount);
				break;
			case(eStat_FlankingCritChance): 
				break;
			case(eStat_FlankingAimBonus): 
				break;
			default:
				break;
			}
	}
}

simulated function AddPersistentStatChange(ECharStatType StatType, float StatAmount, optional EStatModOp InModOp=MODOP_Addition )
{
    local StatChange NewChange;
    
    NewChange.StatType = StatType;
    NewChange.StatAmount = StatAmount;
    NewChange.ModOp = InModOp;

	EffectStatChanges.AddItem(NewChange);
}

// Validate a template
function bool ValidateTemplate(out string strError)
{
	local X2ItemTemplateManager					ItemMgr;
	local X2StrategyElementTemplateManager		StratMgr;
	local X2ItemTemplate						BaseItemToFind;

	// If a weapon has a m_nCreatorTemplateName set, check if BaseItem is valid.
	// Notes: 
	// (*) Blank BaseItem are valid; the item will not be created until the Tech is researched or the Item is build.
	// (*) BaseItem pointed to itself is NOT valid and will crash the game when upgrading.
	// (*) BaseItem is filled but CreatorTemplateName is NOT valid but will not crash the game. This is for consistency purposes.
	// (*) BaseItem pointed to a weapon in a different category is NOT valid and will crash the game when upgrading.

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (BaseItem == DataName)
	{
		strError = "given BaseItem points to itself! Will cause infinite recursion when buying schematic!";
		return false;
	}

	if (CreatorTemplateName == '' && BaseItem != '')
	{
		strError = "given CreatorTemplateName is empty but BaseItem '" $ BaseItem $ "' has an entry!";
		return false;
	}

	if (CreatorTemplateName != '')
	{
		// Check if this tech template exists
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

		if (X2TechTemplate(StratMgr.FindStrategyElementTemplate(CreatorTemplateName)) == none && X2SchematicTemplate(ItemMgr.FindItemTemplate(CreatorTemplateName)) == none)
		{
			strError = "given CreatorTemplateName '" $ CreatorTemplateName $ "' is neither a valid tech template or schematic!";
			return false;
		}
	}

	if (BaseItem != '')
	{
		BaseItemToFind = ItemMgr.FindItemTemplate(BaseItem);

		if (X2WeaponTemplate(BaseItemToFind) == none)
		{
			strError = "given BaseItem '" $ BaseItem $ "' does not exist!";
			return false;
		}
		
		if (X2WeaponTemplate(BaseItemToFind).WeaponCat != WeaponCat)
		{
			strError = "given BaseItem '" $ BaseItem $ "' weapon category '" $ X2WeaponTemplate(BaseItemToFind).WeaponCat $ "' mismatches category '" $ WeaponCat $ "' of Weapon '" $ DataName $ "' !";
			return false;
		}
	}

	return super.ValidateTemplate(strError);
}

function X2ConfigWeaponPartTemplate GetDefaultWeaponPartTemplate(WeaponPartType Type)
{
	local name PartTemplateName;
	local X2ConfigWeaponPartTemplate PartTemplate;
	local X2ItemTemplateManager ItemMgr;

	switch(Type)
	{
		case PT_RECEIVER:
			PartTemplateName = m_nDefaultReceiverTemplate;
			break;
		case PT_BARREL:
			PartTemplateName = (m_nDefaultBarrelTemplate != '') ? m_nDefaultBarrelTemplate : 'PT_SPECIAL_BARREL_NONE';
			break;
		case PT_HANDGUARD:
			PartTemplateName = (m_nDefaultHandguardTemplate != '') ? m_nDefaultHandguardTemplate : 'PT_SPECIAL_HANDGUARD_NONE';
			break;
		case PT_STOCK:
			PartTemplateName = (m_nDefaultStockTemplate != '') ? m_nDefaultStockTemplate : 'PT_SPECIAL_STOCK_NONE';
			break;
		case PT_MAGAZINE:
			PartTemplateName = (m_nDefaultMagazineTemplate != '') ? m_nDefaultMagazineTemplate : 'PT_SPECIAL_MAGAZINE_NONE';
			break;
		case PT_REARGRIP:
			PartTemplateName = (m_nDefaultReargripTemplate != '') ? m_nDefaultReargripTemplate : 'PT_SPECIAL_REARGRIP_NONE';
			break;
		case PT_MUZZLE:
			PartTemplateName = (m_nDefaultMuzzleTemplate != '') ? m_nDefaultMuzzleTemplate : 'PT_SPECIAL_MUZZLE_NONE';
			break;
		case PT_UNDERBARREL:
			PartTemplateName = (m_nDefaultUnderbarrelTemplate != '') ? m_nDefaultUnderbarrelTemplate : 'PT_SPECIAL_UNDERBARREL_NONE';
			break;
		case PT_LASER:
			PartTemplateName = (m_nDefaultLaserTemplate != '') ? m_nDefaultLaserTemplate : 'PT_SPECIAL_LASER_NONE';
			break;
		case PT_OPTIC:
			PartTemplateName = (m_nDefaultOpticsTemplate != '') ? m_nDefaultOpticsTemplate : 'PT_SPECIAL_OPTIC_NONE';
			break;
		// Spit out error
		case PT_NONE:
		case PT_MAX:
			break;
	}

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	//`LOG("Building Weapon Gunsmith Itemstate for template " $ DataName $ " with " $ m_aDefaultWeaponPartTemplate.Length $ " parts",, 'WotC_Gameplay_Misc_WeaponGunsmith');
	//`LOG("Part " $ PartTemplateName $ " exists? " $ PartTemplate != none,, 'WotC_Gameplay_Misc_WeaponGunsmith');
	
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(PartTemplateName));
	
	return PartTemplate;
}

function string GetItemFriendlyName(optional int ItemID = 0, optional bool bShowSquadUpgrade)
{
	local XComGameStateHistory			History;
	local XComGameState_Item			ItemState;
	local XCGS_WeaponGunsmith			WeaponGunsmithState;
	local X2ConfigWeaponPartTemplate	ReceiverTemplate;
	local string strTemp;

	if(FriendlyName == "")
		return "Error! " $ string(DataName) $ " has no FriendlyName!";
	
	strTemp = FriendlyName;
	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemID));
	WeaponGunsmithState = XCGS_WeaponGunsmith(ItemState.FindComponentObject(class'XCGS_WeaponGunsmith'));

	// Pull the name from the Receiver if there is one and the weapon was modified in any fashion
	if (WeaponGunsmithState != none && WeaponGunsmithState.bIsModified)
	{
		ReceiverTemplate = WeaponGunsmithState.GetPartTemplate(PT_RECEIVER);

		if (ReceiverTemplate != none && ReceiverTemplate.m_strReceiverFriendlyName.Length > 0)
			strTemp = ReceiverTemplate.m_strReceiverFriendlyName[GetIndexByWeaponTech()];
	}

	// V1.005: Nicknames take precedence over receiver names
	if(ItemState != none && ItemState.Nickname != "")
		strTemp = ItemState.Nickname;

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strTemp);
}

function int GetIndexByWeaponTech()
{
	local int Val;

	Val = 0;	// Default, if no techs are avaliable or is conventional weapon

	switch (m_nWeaponTech)
	{
		case 'laser':
			Val = 1;
			break;
		case 'magnetic':
			Val = 2;
			break;
		case 'coil':
			Val = 3;
			break;
		case 'beam':
			Val = 4;
			break;
	}

	return Val;
}

static function string WriteJSONForNetwork(XComGameState_Item ItemState)
{
	local XCGS_WeaponGunsmith			WeaponGunsmithState;
	local JSONObject					Root, CustomizeObject;
	local OnlineSubsystem				m_OnlineSub;
	local UniqueNetId					PlayerId;
	local int i;

	// Exit if invalid or not set
	if (ItemState.ObjectID == 0)
		return "";

	WeaponGunsmithState = XCGS_WeaponGunsmith(ItemState.FindComponentObject(class'XCGS_WeaponGunsmith'));
	m_OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();

	m_OnlineSub.PlayerInterface.GetUniquePlayerId(`ONLINEEVENTMGR.LocalUserIndex, PlayerId);
	
	Root = new class'JSONObject';

	// Metadata
	Root.SetStringValue("Object",							"GunsmithWeapon");
	Root.SetStringValue("Author",							m_OnlineSub.UniqueNetIdToString(PlayerId) );
	Root.SetIntValue("Steamworks",							int(class'GameEngine'.static.IsSteamworksInitialized()) );

	Root.SetStringValue("WeaponTemplate",					string(ItemState.GetMyTemplate().DataName));
	Root.SetStringValue("Nickname",							ItemState.Nickname);

	// Gunsmith Items
	Root.SetStringValue("ReceiverTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_RECEIVER).DataName) );
	Root.SetStringValue("BarrelTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_BARREL).DataName) );
	Root.SetStringValue("HandguardTemplate",				string(WeaponGunsmithState.GetPartTemplate(PT_HANDGUARD).DataName) );
	Root.SetStringValue("StockTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_STOCK).DataName) );
	Root.SetStringValue("MagazineTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_MAGAZINE).DataName) );
	Root.SetStringValue("ReargripTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_REARGRIP).DataName) );
	Root.SetStringValue("UnderbarrelTemplate",				string(WeaponGunsmithState.GetPartTemplate(PT_UNDERBARREL).DataName) );
	Root.SetStringValue("OpticsTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_OPTIC).DataName) );
	Root.SetStringValue("LaserTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_LASER).DataName) );
	Root.SetStringValue("MuzzleTemplate",					string(WeaponGunsmithState.GetPartTemplate(PT_MUZZLE).DataName) );

	for(i = PT_NONE; i < PT_MAX; ++i)
	{
		CustomizeObject = new class'JSONObject';
		
		CustomizeObject.SetStringValue("CamoTemplateName",		string(WeaponGunsmithState.arrWeaponCustomizationParts[i].CamoTemplateName));
		CustomizeObject.SetIntValue("PrimaryPaletteIdx",		WeaponGunsmithState.arrWeaponCustomizationParts[i].iPrimaryTintPaletteIdx);
		CustomizeObject.SetIntValue("SecondaryPaletteIdx",		WeaponGunsmithState.arrWeaponCustomizationParts[i].iSecondaryTintPaletteIdx);
		CustomizeObject.SetStringValue("PrimaryTintColor",		class'UIUtilities_Colors'.static.LinearColorToFlashHex(WeaponGunsmithState.arrWeaponCustomizationParts[i].PrimaryTintColor));
		CustomizeObject.SetStringValue("SecondaryTintColor",	class'UIUtilities_Colors'.static.LinearColorToFlashHex(WeaponGunsmithState.arrWeaponCustomizationParts[i].SecondaryTintColor));
		CustomizeObject.SetStringValue("TertiaryTintColor",		class'UIUtilities_Colors'.static.LinearColorToFlashHex(WeaponGunsmithState.arrWeaponCustomizationParts[i].TertiaryTintColor));

		CustomizeObject.SetStringValue("EmissiveColor",			class'UIUtilities_Colors'.static.LinearColorToFlashHex(WeaponGunsmithState.arrWeaponCustomizationParts[i].EmissiveColor));
		CustomizeObject.SetFloatValue("EmissivePower",			WeaponGunsmithState.arrWeaponCustomizationParts[i].fEmissivePower);
		CustomizeObject.SetFloatValue("USize",					WeaponGunsmithState.arrWeaponCustomizationParts[i].fTexUSize);
		CustomizeObject.SetFloatValue("VSize",					WeaponGunsmithState.arrWeaponCustomizationParts[i].fTexVSize);
		CustomizeObject.SetIntValue("RotDegrees",				WeaponGunsmithState.arrWeaponCustomizationParts[i].iTexRot);
		
		CustomizeObject.SetBoolValue("SwapMasks",				WeaponGunsmithState.arrWeaponCustomizationParts[i].bSwapMasks);
		CustomizeObject.SetBoolValue("PrimaryAsSecondary",		WeaponGunsmithState.arrWeaponCustomizationParts[i].bMergeMasks);

		//Write to main JSON object
		switch (WeaponPartType(i))
		{
			case PT_RECEIVER:
				Root.SetObject("RECEIVER_CustomizationData", CustomizeObject);
				break;
			case PT_BARREL:
				Root.SetObject("BARREL_CustomizationData", CustomizeObject);
				break;
			case PT_HANDGUARD:
				Root.SetObject("HANDGUARD_CustomizationData", CustomizeObject);
				break;
			case PT_STOCK:
				Root.SetObject("STOCK_CustomizationData", CustomizeObject);
				break;
			case PT_MAGAZINE:
				Root.SetObject("MAGAZINE_CustomizationData", CustomizeObject);
				break;
			case PT_REARGRIP:
				Root.SetObject("REARGRIP_CustomizationData", CustomizeObject);
				break;
			case PT_MUZZLE:
				Root.SetObject("MUZZLE_CustomizationData", CustomizeObject);
				break;
			case PT_UNDERBARREL:
				Root.SetObject("UNDERBARREL_CustomizationData", CustomizeObject);
				break;
			case PT_LASER:
				Root.SetObject("LASER_CustomizationData", CustomizeObject);
				break;
			case PT_OPTIC:
				Root.SetObject("OPTIC_CustomizationData", CustomizeObject);
				break;
			// Spit out error
			case PT_NONE:
			case PT_MAX:
				break;
		}
	}

	// Tail payload to ensure data is complete
	Root.SetStringValue("Tail", class'WebRequest'.static.EncodeBase64("WeaponGunsmithIntegrityCheck"));

	// Stringify JSON
	return class'JsonObject'.static.EncodeJson(Root);
}

// State submission is NOT handled here, do it outside this function
static function StateObjectReference ImportJSONFromNetwork(string Data, bool bFilteringDisabled, bool bCreateGameState, StateObjectReference WeaponRef, XCGS_WeaponGunsmith	WeaponGunsmithState)
{
	local StateObjectReference					EmptyRef;
	local JSONObject							Root, CustomizeObject;
	local X2ItemTemplateManager					ItemMgr;
	local XComGameState_Item					ImportedWeapon;
	local XCGS_WeaponGunsmith					ImportedGunsmithState;

	local XComGameState							ChangeState;

	local name									ReceiverTemplateName, WeaponTemplate;
	local X2ConfigWeaponPartTemplate			ReceiverTemplate, PartTemplate;
	local int									i;
	local array<WeaponCustomizationData>		arrImportedCust;

	local XGParamTag							LocTag;
	local string								Text;

	Root			= class'JsonObject'.static.DecodeJson(Data);

	// Check Heads and Tails and ensure that this is a vaild weapon
	if (	Root.GetStringValue("Object") != "GunsmithWeapon" && 
			class'WebRequest'.static.DecodeBase64(Root.GetStringValue("Tail")) != "WeaponGunsmithIntegrityCheck" )
	{
		// Write error message
		ImportFailedDialogue(	class'GunsmithDataStructures'.default.strCustomizationImport_Fail_BadDecode_DialogueTitle,
																				class'GunsmithDataStructures'.default.strCustomizationImport_Fail_BadDecode_DialogueText);
		return EmptyRef;
	}

	ItemMgr			= class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ImportedWeapon 	= XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	//Author = Root.GetStringValue("Author");
	//bSteam = Root.GetIntValue("Steamworks");

	// Must match an existing gunsmith template or receiver must support said weapon template

	WeaponTemplate			= name(Root.GetStringValue("WeaponTemplate"));
	ReceiverTemplateName	= name(Root.GetStringValue("ReceiverTemplate"));

	ReceiverTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(ReceiverTemplateName));

	if (!bFilteringDisabled)
	{
		if (WeaponTemplate == '')
		{
			ImportFailedDialogue(class'GunsmithDataStructures'.default.strCustomizationImport_Fail_EmptyWeapon_DialogueTitle,
																				 class'GunsmithDataStructures'.default.strCustomizationImport_Fail_EmptyWeapon_DialogueText);
			return EmptyRef;
		}

		if (ReceiverTemplateName == '' || ReceiverTemplate == none)
		{
			ImportFailedDialogue(class'GunsmithDataStructures'.default.strCustomizationImport_Fail_EmptyReceiver_DialogueTitle,
																				 class'GunsmithDataStructures'.default.strCustomizationImport_Fail_EmptyReceiver_DialogueText);
			return EmptyRef;
		}

		// Check Weapon Template
		if (ImportedWeapon.GetMyTemplateName() != WeaponTemplate)
		{
			// Mis-matched template, attempt to check if the Receiver supports this weapon
			if (ReceiverTemplate.arrWeaponTemplateWhitelist.Find(WeaponTemplate) == INDEX_NONE)
			{
				LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
				LocTag.StrValue0 = string(WeaponTemplate);
				Text = `XEXPAND.ExpandString(class'GunsmithDataStructures'.default.strCustomizationImport_Fail_InvalidReceiver_DialogueText);

				// Produce an error message telling the player that this JSON data is not valid for this weapon.
				ImportFailedDialogue(	class'GunsmithDataStructures'.default.strCustomizationImport_Fail_InvalidReceiver_DialogueTitle,
																						Text);
				return EmptyRef;
			}
		}

	}

	if (bCreateGameState)
	{
		ChangeState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Import Gunsmith Data");
	}

	ImportedWeapon 			= XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	ImportedGunsmithState	= XCGS_WeaponGunsmith(ChangeState.ModifyStateObject(WeaponGunsmithState.Class, WeaponGunsmithState.ObjectID));

	ImportedWeapon.NickName = Root.GetStringValue("Nickname");

	// Receiver
	ImportedGunsmithState.SetPartTemplate(ReceiverTemplate, PT_RECEIVER, false, true);

	// Barrel
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("BarrelTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_BARREL);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_BARREL);
	
	// Handguard
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("HandguardTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_HANDGUARD);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_HANDGUARD);
	
	// Stock
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("StockTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_STOCK);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_STOCK);

	// Reargrip
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("ReargripTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_REARGRIP);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_REARGRIP);

	// Magazine
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("MagazineTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_MAGAZINE);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_MAGAZINE);
	
	// Muzzle
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("MuzzleTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_MUZZLE);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_MUZZLE);
	
	// Underbarrel
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("UnderbarrelTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_UNDERBARREL);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_UNDERBARREL);

	// Laser
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("LaserTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_LASER);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_LASER);

	// Optic
	PartTemplate = X2ConfigWeaponPartTemplate(ItemMgr.FindItemTemplate(name(Root.GetStringValue("OpticTemplate"))));

	if (PartTemplate == none)
		PartTemplate = X2ConfigWeaponAlphaTemplate(ImportedWeapon.GetMyTemplate()).GetDefaultWeaponPartTemplate(PT_OPTIC);

	ImportedGunsmithState.SetPartTemplate(PartTemplate, PT_OPTIC);

	// Initialize array
	arrImportedCust.Add(PT_MAX);

	for(i = PT_NONE; i < PT_MAX; ++i)
	{
		CustomizeObject = none;

		//Write to main JSON object
		switch (WeaponPartType(i))
		{
			case PT_RECEIVER:
				CustomizeObject = Root.GetObject("RECEIVER_CustomizationData");
				break;
			case PT_BARREL:
				CustomizeObject = Root.GetObject("BARREL_CustomizationData");
				break;
			case PT_HANDGUARD:
				CustomizeObject = Root.GetObject("HANDGUARD_CustomizationData");
				break;
			case PT_STOCK:
				CustomizeObject = Root.GetObject("STOCK_CustomizationData");
				break;
			case PT_MAGAZINE:
				CustomizeObject = Root.GetObject("MAGAZINE_CustomizationData");
				break;
			case PT_REARGRIP:
				CustomizeObject = Root.GetObject("REARGRIP_CustomizationData");
				break;
			case PT_MUZZLE:
				CustomizeObject = Root.GetObject("MUZZLE_CustomizationData");
				break;
			case PT_UNDERBARREL:
				CustomizeObject = Root.GetObject("UNDERBARREL_CustomizationData");
				break;
			case PT_LASER:
				CustomizeObject = Root.GetObject("LASER_CustomizationData");
				break;
			case PT_OPTIC:
				CustomizeObject = Root.GetObject("OPTIC_CustomizationData");
				break;
			// Spit out error
			case PT_NONE:
			case PT_MAX:
				break;
		}

		if (CustomizeObject == none)
			continue;
		
		arrImportedCust[i].CamoTemplateName				= name(CustomizeObject.GetStringValue("CamoTemplateName"));
		arrImportedCust[i].iPrimaryTintPaletteIdx		= CustomizeObject.GetIntValue("PrimaryPaletteIdx");
		arrImportedCust[i].iSecondaryTintPaletteIdx		= CustomizeObject.GetIntValue("SecondaryPaletteIdx");

		arrImportedCust[i].PrimaryTintColor				= class'GunsmithDataStructures'.static.HexStringToLinearColor(Repl(CustomizeObject.GetStringValue("PrimaryTintColor"), "0x00", ""));
		arrImportedCust[i].SecondaryTintColor			= class'GunsmithDataStructures'.static.HexStringToLinearColor(Repl(CustomizeObject.GetStringValue("SecondaryTintColor"), "0x00", ""));
		arrImportedCust[i].TertiaryTintColor			= class'GunsmithDataStructures'.static.HexStringToLinearColor(Repl(CustomizeObject.GetStringValue("TertiaryTintColor"), "0x00", ""));
		arrImportedCust[i].EmissiveColor				= class'GunsmithDataStructures'.static.HexStringToLinearColor(Repl(CustomizeObject.GetStringValue("EmissiveColor"), "0x00", "")); 
		
		arrImportedCust[i].fEmissivePower				= CustomizeObject.GetFloatValue("EmissivePower");
		arrImportedCust[i].fTexUSize					= CustomizeObject.GetFloatValue("USize");
		arrImportedCust[i].fTexVSize					= CustomizeObject.GetFloatValue("VSize");
		arrImportedCust[i].iTexRot						= CustomizeObject.GetIntValue("RotDegrees");

		arrImportedCust[i].bSwapMasks					= CustomizeObject.GetBoolValue("SwapMasks");
		arrImportedCust[i].bMergeMasks					= CustomizeObject.GetBoolValue("PrimaryAsSecondary");
	}

	ImportedGunsmithState.arrWeaponCustomizationParts = arrImportedCust;

	if (bCreateGameState)
	{
		if (ChangeState.GetNumGameStateObjects() > 0)
			`GAMERULES.SubmitGameState(ChangeState);
		else
			`XCOMHISTORY.CleanupPendingGameState(ChangeState);
	}

	return ImportedWeapon.GetReference();
}

static function ImportFailedDialogue(string Title, string Text)
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Warning;
	kDialogData.strTitle	= Title;
	kDialogData.strText		= Text;
	kDialogData.strAccept	= class'UIUtilities_Text'.default.m_strGenericAccept;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

DefaultProperties
{
	GameplayInstanceClass=class'XGWeapon_Platform_AR'
}