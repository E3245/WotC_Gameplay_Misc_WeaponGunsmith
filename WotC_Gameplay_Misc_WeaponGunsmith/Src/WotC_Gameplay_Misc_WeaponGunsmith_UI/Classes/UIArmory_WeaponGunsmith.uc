class UIArmory_WeaponGunsmith extends UIArmory_WeaponUpgrade
	config(UI);

`include(ModConfigMenuAPI/MCM_API_Includes.uci)
`include(ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

struct PartFilteringCriteria
{
	var X2ConfigWeaponPartTemplate	Template;
	var bool						bAlwaysHide;
	var bool						bMatchingReceiver;
	var string						Reason;
};

// Panel on center bottom and bottom left
var UIPanel_WeaponCategoryControl WeaponCategoryControl;
//var UIPanel WeaponPartSelector;

var WeaponPartType 						SelectedPart;

var XCGS_WeaponGunsmith 				PrevGunsmithState;		// In case the player wants to revert back
var XCGS_WeaponGunsmith 				CurrentGunsmithState;

var array<bool>							ValidPartCategoryFlag;	// Initialized with PT_MAX slots. Checks if we can access this category.
var array<bool>							InitWeaponUpgradeVPCF;	// Same as above but keeps the references to which parts we've already unlocked via Weapon Upgrades. 

var bool 								bFilteringDisabled;

// Equipping weapon upgrades unlocks the ability to edit said category
var bool								bWeaponUpgradesInfluenceParts;
var bool								bMuzzleUnlocked;

var int								LastClickedIndex;
var byte								ModeSpinnerValue;
var int								WeaponCategorySpinnerIndex;
var bool								bReceiverValidationCheck;	// If not set, receivers need re-evaluation.

// List of all possible weapon parts for each category
var array<PartFilteringCriteria> 	arrWeaponPart_Receiver;
var array<PartFilteringCriteria> 	arrWeaponPart_Barrel;
var array<PartFilteringCriteria> 	arrWeaponPart_Handguard;
var array<PartFilteringCriteria> 	arrWeaponPart_Stock;
var array<PartFilteringCriteria> 	arrWeaponPart_Magazine;
var array<PartFilteringCriteria> 	arrWeaponPart_Reargrip;
var array<PartFilteringCriteria> 	arrWeaponPart_Underbarrel;
var array<PartFilteringCriteria> 	arrWeaponPart_Optics;
var array<PartFilteringCriteria> 	arrWeaponPart_Laser;
var array<PartFilteringCriteria> 	arrWeaponPart_Muzzle;

// Filters
var config array<name>				ValidBarrelUpgrades;
var config array<name>				ValidHandguardUpgrades;
var config array<name>				ValidStockUpgrades;
var config array<name>				ValidMagazineUpgrades;
var config array<name>				VaildReargripUpgrades;
var config array<name>				ValidUnderbarrelUpgrades;
var config array<name>				ValidOpticsUpgrades;
var config array<name>				ValidLaserUpgrades;
var config array<name>				ValidMuzzleUpgrades;

var localized string m_strWPNPartCategory_Receiver;
var localized string m_strWPNPartCategory_Barrel;
var localized string m_strWPNPartCategory_Handguard;
var localized string m_strWPNPartCategory_Stock;
var localized string m_strWPNPartCategory_Magazine;
var localized string m_strWPNPartCategory_Reargrip;

var localized string m_strWPNPartCategory_Underbarrel;
var localized string m_strWPNPartCategory_Laser;
var localized string m_strWPNPartCategory_Optics;
var localized string m_strWPNPartCategory_Muzzle;

var localized string m_strError_BarrelPreventsMuzzles;

var localized string m_PartSelectorTitle;

var localized string m_strButton_SwapToWeaponGunsmith;
var localized string m_strButton_SwapToWeaponUpgrade;

var localized string m_strResetWeaponToDefault;

var localized string strCustomizationDestruction_DialogueTitle;
var localized string strCustomizationDestruction_DialogueText;

var localized string m_strSwitchPartCategoryNavHelp;

`MCM_CH_VersionChecker(class'MCM_GunsmithModOptions_Defaults'.default.VERSION,class'UIListener_MCMOptions_GS'.default.CONFIG_VERSION)

simulated function InitArmory(StateObjectReference UnitOrWeaponRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	// Default Values
	SelectedPart = PT_RECEIVER;
	ModeSpinnerValue = SelectedPart;

	// Pull from user config file
	LoadINISettings();

	// Do this now since it's expensive to iterate through every template in the game multiple times
	GetListOfWeaponParts();

	// Create the screen
	super.InitArmory(UnitOrWeaponRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	if (ValidPartCategoryFlag.Length == 0)
	{
		CreateValidPartCategory();
	}

	WeaponCategoryControl = Spawn(class'UIPanel_WeaponCategoryControl', self).InitControlPanel('CtrlPanel');
	WeaponCategoryControl.SetPosition(1600, 600);
	WeaponCategoryControl.UpdateValidCategory(ValidPartCategoryFlag);

	`HQPRES.CAMLookAtNamedLocation( CameraTag, 0 );

	// Get the NavBar and add a Switch to Weapon Upgrade button

	WeaponStats.Hide(); 
	WeaponStats.SetAlpha(0.0f);
	UpgradesListContainer.Hide();
	UpgradesList.Hide();

	SlotsList.ItemPadding = 0;
}

simulated function OnInit()
{
	super.OnInit();

	// Adjust list size so it doesn't overlap the customization buttons (Thanks to RustyDios Improved Weapon Upgrade UI mod)
	// Formula may be wrong
	SlotsList.SetHeight(SlotsList.Height - (CustomizeList.Height + 24) );
}

function LoadINISettings()
{
    // Doing it this way means that it'll pull from defaults if the INI file wasn't created.
    bFilteringDisabled = `MCM_CH_GetValue(class'MCM_GunsmithModOptions_Defaults'.default.bCursedWeaponMode, 
							class'UIListener_MCMOptions_GS'.default.bCursedWeaponMode);

	bWeaponUpgradesInfluenceParts	= `MCM_CH_GetValue(class'MCM_GunsmithModOptions_Defaults'.default.bUpgradesUnlockWeaponPartCategory, 
							class'UIListener_MCMOptions_GS'.default.bUpgradesUnlockWeaponPartCategory);
}

function CreateValidPartCategory(optional X2ConfigWeaponPartTemplate Template)
{
	// If there's existing data here, clear it
	// Switching soldiers usually needs re-evaluations
	if (ValidPartCategoryFlag.Length > 0)
		ValidPartCategoryFlag.Length = 0;

	ValidPartCategoryFlag.Add(PT_MAX); 	// Declare PT_MAX size array

	// Dictate if we can access these categories by criteria
	ValidPartCategoryFlag[PT_RECEIVER]		= true;	// Always editable

	// Initialize which upgrades are available
	if (bWeaponUpgradesInfluenceParts)
	{
		// Initialize array if not already set
		if (InitWeaponUpgradeVPCF.Length == 0)
		{
			InitWeaponUpgradeVPCF.Add(PT_MAX);
			InitializeWeaponUnlockCategory();
		}

		// Reset ValidPartCategory to defaults
		ValidPartCategoryFlag = InitWeaponUpgradeVPCF;
	}
	else
	{
		ValidPartCategoryFlag[PT_BARREL]		= true;
		ValidPartCategoryFlag[PT_HANDGUARD]		= true;
		ValidPartCategoryFlag[PT_STOCK]			= true;
		ValidPartCategoryFlag[PT_MAGAZINE]		= true;
		ValidPartCategoryFlag[PT_REARGRIP]		= true;
		ValidPartCategoryFlag[PT_UNDERBARREL]	= true;
		ValidPartCategoryFlag[PT_LASER]			= true;
		ValidPartCategoryFlag[PT_OPTIC]			= true;

		bMuzzleUnlocked = true;

		// Is the currently equipped barrel preventing muzzles from being equipped?
		ValidPartCategoryFlag[PT_MUZZLE]		= !CurrentGunsmithState.GetPartTemplate(PT_BARREL).bBarrel_IgnoreValidParts;
	}

	// Check if the receiver allows customization of certain parts
	if (Template != none && Template.ePartName == PT_RECEIVER)
	{
		ValidPartCategoryFlag[PT_BARREL]		= (Template.UnlockedCategories[PT_BARREL] > 0);
		ValidPartCategoryFlag[PT_HANDGUARD]		= (Template.UnlockedCategories[PT_HANDGUARD] > 0);
		ValidPartCategoryFlag[PT_STOCK]			= (Template.UnlockedCategories[PT_STOCK] > 0);
		ValidPartCategoryFlag[PT_MAGAZINE]		= (Template.UnlockedCategories[PT_MAGAZINE] > 0);
		ValidPartCategoryFlag[PT_REARGRIP]		= (Template.UnlockedCategories[PT_REARGRIP] > 0);
		ValidPartCategoryFlag[PT_UNDERBARREL]	= (Template.UnlockedCategories[PT_UNDERBARREL] > 0);
		ValidPartCategoryFlag[PT_LASER]			= (Template.UnlockedCategories[PT_LASER] > 0);
		ValidPartCategoryFlag[PT_OPTIC]			= (Template.UnlockedCategories[PT_OPTIC] > 0);
		ValidPartCategoryFlag[PT_MUZZLE]		= (Template.UnlockedCategories[PT_MUZZLE] > 0) && !CurrentGunsmithState.GetPartTemplate(PT_BARREL).bBarrel_IgnoreValidParts;
	}
}

function InitializeWeaponUnlockCategory()
{
	local XComGameState_Item	Weapon;
	local array<name>			CurrentWeaponUpgrades;

	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	CurrentWeaponUpgrades = Weapon.GetMyWeaponUpgradeTemplateNames();

	InitWeaponUpgradeVPCF[PT_RECEIVER]		= true;
	InitWeaponUpgradeVPCF[PT_BARREL]		= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidBarrelUpgrades);
	InitWeaponUpgradeVPCF[PT_HANDGUARD]		= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidHandguardUpgrades);
	InitWeaponUpgradeVPCF[PT_STOCK]			= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidStockUpgrades);
	InitWeaponUpgradeVPCF[PT_MAGAZINE]		= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidMagazineUpgrades);
	InitWeaponUpgradeVPCF[PT_REARGRIP]		= HasWeaponUpgrade(CurrentWeaponUpgrades, VaildReargripUpgrades);
	InitWeaponUpgradeVPCF[PT_UNDERBARREL]	= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidUnderbarrelUpgrades);
	InitWeaponUpgradeVPCF[PT_LASER]			= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidLaserUpgrades);
	InitWeaponUpgradeVPCF[PT_OPTIC]			= HasWeaponUpgrade(CurrentWeaponUpgrades, ValidOpticsUpgrades);

	bMuzzleUnlocked = HasWeaponUpgrade(CurrentWeaponUpgrades, ValidMuzzleUpgrades);
	InitWeaponUpgradeVPCF[PT_MUZZLE]		= bMuzzleUnlocked;
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local UIArmory ArmoryScreen;
	local UIArmory_WeaponGunsmith GunsmithScreen;
	local UIScreenStack ScreenStack;
	local Rotator CachedRotation;

	ScreenStack = `SCREENSTACK;

	// Update the weapon in the WeaponUpgrade screen
	GunsmithScreen = UIArmory_WeaponGunsmith(ScreenStack.GetScreen(class'UIArmory_WeaponGunsmith'));

	if( GunsmithScreen.ActorPawn != none )
		CachedRotation = GunsmithScreen.ActorPawn.Rotation;

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			ArmoryScreen.ReleasePawn();
			ArmoryScreen.SetUnitReference(NewRef);
			ArmoryScreen.Header.UnitRef = NewRef;
		}
	}

	GunsmithScreen.SetWeaponReference(GunsmithScreen.GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference());

	if(GunsmithScreen.ActorPawn != none)
		GunsmithScreen.ActorPawn.SetRotation(CachedRotation);
	
	//Force refresh - otherwise we end up with out-of-date weapon pawn (showing customization from previous soldier)
	GunsmithScreen.PreviewUpgrade(GunsmithScreen.SlotsList, GunsmithScreen.LastClickedIndex);
}

simulated function SetWeaponReference(StateObjectReference NewWeaponRef)
{
	local XComGameState_Item Weapon;

	if(CustomizationState != none)
		SubmitCustomizationChanges();

	WeaponRef = NewWeaponRef;
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	
	bReceiverValidationCheck = false; // Weapon has changed, receivers need validation again

	PrevGunsmithState = XCGS_WeaponGunsmith(Weapon.FindComponentObject(class'XCGS_WeaponGunsmith'));
	CurrentGunsmithState = PrevGunsmithState;

	SetWeaponName(Weapon.GetMyTemplate().GetItemFriendlyName());
	CreateWeaponPawn(Weapon);
	DefaultWeaponRotation = ActorPawn.Rotation;

	// Re-evaluate unlocked weapon categories
	CreateValidPartCategory(CurrentGunsmithState.GetPartTemplate(PT_RECEIVER));
	WeaponCategoryControl.UpdateValidCategory(ValidPartCategoryFlag);

	// If we end up in an invalid category, boot the player back to the Receiver part category
	if (ValidPartCategoryFlag[SelectedPart] == false)
	{
		WeaponCategoryControl.OnItemClicked(WeaponCategoryControl.PartsList, 0);
	}

	ChangeActiveList(SlotsList, true);
	UpdateOwnerSoldier();
	UpdateSlots();

	if(CustomizeList.bIsInited)
		UpdateCustomization(none);

	MC.FunctionVoid("animateIn");
}

simulated function UpdateOwnerSoldier()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;

	History = `XCOMHISTORY;
	Weapon = XComGameState_Item(History.GetGameStateForObjectID(WeaponRef.ObjectID));
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(Weapon.OwnerStateObject.ObjectID));

	if(Unit != none)
		SetEquippedText(Unit.GetName(eNameType_FullNick), Weapon.GetMyTemplate().GetItemFriendlyName(Weapon.ObjectID));
	else
		SetEquippedText(m_strWeaponNotEquipped, Weapon.GetMyTemplate().GetItemFriendlyName(Weapon.ObjectID));
}

// Used in UIArmory_WeaponUpgrade & UIArmory_WeaponList
simulated function CreatePreviewGunsmithWeaponPawn(XComGameState_Item Weapon, XCGS_WeaponGunsmith Gunsmith, optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;
	local XGWeapon WeaponVisualizer;
	
	// Make sure to clean up weapon actors left over from previous Armory screens.
	if(ActorPawn == none)
		ActorPawn = UIArmory(Movie.Stack.GetLastInstanceOf(class'UIArmory')).ActorPawn;

	// Clean up previous weapon actor
	if( ActorPawn != none )
		ActorPawn.Destroy();

	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	if( WeaponVisualizer != none )
	{
		WeaponVisualizer.Destroy();
	}

//	class'XGItem'.static.CreateVisualizer(Weapon);
	class'XGWeapon_Platform_AR'.static.CreatePreviewVisualizer(Weapon, true, none, Gunsmith);

	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	ActorPawn = WeaponVisualizer.GetEntity();

	PawnLocationTag = X2WeaponTemplate(Weapon.GetMyTemplate()).UIArmoryCameraPointTag;

	if(DesiredRotation == NoneRotation)
		DesiredRotation = GetPlacementActor().Rotation;

	ActorPawn.SetLocation(GetPlacementActor().Location);
	ActorPawn.SetRotation(DesiredRotation);
	ActorPawn.SetHidden(false);
}

simulated function UpdateSlots()
{
	local XGParamTag LocTag;
	local XComGameState_Item Weapon;

	local array<X2ConfigWeaponPartTemplate> arrParts;
	local X2ConfigWeaponPartTemplate		IterPart;
	local UIListItemString					ListItem;

	local int i;

	local string FriendlyName;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	LocTag.StrValue0 = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Weapon.GetMyTemplate().GetItemFriendlyName(Weapon.ObjectID));

	SlotsList.ClearItems();

	arrParts = GetSelectedWeaponParts();

	foreach arrParts(IterPart, i)
	{
		FriendlyName = (IterPart.FriendlyName != "") ? IterPart.FriendlyName : string(IterPart.DataName);

		ListItem = UIListItemString(SlotsList.CreateItem(class'UIListItemString')).InitListItem(FriendlyName);
		ListItem.SetWidth(342);

		// If the part matches, highlight
		if (IterPart.DataName == CurrentGunsmithState.GetPartTemplate(SelectedPart).DataName)
		{
			ListItem.ShouldShowGoodState(true);
			LastClickedIndex = i;

			// Set the part as selected in the list
			//SlotsList.SetSelectedIndex(i);
		}
	}

	if (SlotsList.Scrollbar != none)
	{
		SlotsList.Scrollbar.Show();
	}

	SetSlotsListTitle(GetCategoryLabelString(SelectedPart));

	`XEVENTMGR.TriggerEvent('UIArmory_WeaponGunsmith_SlotsUpdated', SlotsList, self, none);
}

simulated function PreviewUpgrade(UIList ContainerList, int ItemIndex)
{
	local XComGameState_Item 				Weapon;
	local XComGameState 					ChangeState;
	local XCGS_WeaponGunsmith				UpdatedGunsmithState;

	local Vector							PreviousLocation;
	local array<X2ConfigWeaponPartTemplate> arrParts;

	if(ItemIndex == INDEX_NONE)
	{
		return;
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade");
	ChangeState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Visualize Weapon Upgrade");

	Weapon 			  		= XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	
	UpdatedGunsmithState 	= XCGS_WeaponGunsmith(Weapon.FindComponentObject(class'XCGS_WeaponGunsmith'));
	UpdatedGunsmithState	= XCGS_WeaponGunsmith(ChangeState.ModifyStateObject(UpdatedGunsmithState.Class, UpdatedGunsmithState.ObjectID));
	
	arrParts = GetSelectedWeaponParts();

	// If we only have the Receiver unlocked, then force the weapon to reset to default parts when swapping receivers
	//if ( !IsAnyPartValid() )
	//	UpdatedGunsmithState.bPreview_UseOnlyFirstAvaliable = true;

	// Update Gunsmith state with new template
	UpdatedGunsmithState.SetPartTemplate(arrParts[ItemIndex], SelectedPart, false, true);

	// Start Issue #39
	/// HL-Docs: ref:Bugfixes; issue:39
	/// Create weapon pawn before setting PawnLocationTag so that the weapon can rotate when previewing weapon upgrades.
	PreviousLocation = ActorPawn.Location;

	// Hacked version so that Gunsmith parts get updated properly when selecting them
	CreatePreviewGunsmithWeaponPawn(Weapon, UpdatedGunsmithState, ActorPawn.Rotation);
	ActorPawn.SetLocation(PreviousLocation);
	MouseGuard.SetActorPawn(ActorPawn, ActorPawn.Rotation);
	// End Issue #39

	if(ActiveList != UpgradesList)
	{
		MouseGuard.SetActorPawn(ActorPawn); //When we're not selecting an upgrade, let the user spin the weapon around
		RestoreWeaponLocation();
	}
	else
	{
		MouseGuard.SetActorPawn(None); //Otherwise, grab the rotation to show them the upgrade as they select it
	}
	// Start Issue #39
	// Create weapon pawn if the upgrade template does not exist to preserve the vanilla WOTC behavior
	// in case something goes wrong.
	//if (UpgradeTemplate == none)
	//{
	//	PreviousLocation = ActorPawn.Location;
	//	CreateWeaponPawn(Weapon, ActorPawn.Rotation);
	//	ActorPawn.SetLocation(PreviousLocation);
	//	MouseGuard.SetActorPawn(ActorPawn, ActorPawn.Rotation);
	//}
	// End Issue #39
	`XCOMHISTORY.CleanupPendingGameState(ChangeState);
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local UIListItemString				Item;
	local X2ConfigWeaponPartTemplate	PartTemplate;

	if(ContainerList != ActiveList) return;

	// Make clicking noise but do nothing else
	if (LastClickedIndex == ItemIndex)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade_Select");
		return;
	}

	Item = UIListItemString(ContainerList.GetItem(ItemIndex));

	if(Item.bDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	//bsg-hlee (05.10.17): Only let upgrades be selected if there are actually upgrades avail.
	if(ActiveList.ItemCount > 0)
	{
		// Install the upgrade
		PartTemplate = InstallPartOnWeapon(ItemIndex);

		// Make the button green
		Item.ShouldShowGoodState(true);

		UIListItemString(ContainerList.GetItem(LastClickedIndex)).ShouldShowGoodState(false);
		
		LastClickedIndex = ItemIndex;

		// Changing receivers may change the weapon name
		UpdateOwnerSoldier();

		// Equipping a new barrel might prevent swapping muzzles
		// Only do this if the slot is unlocked
		if (!bFilteringDisabled)
		{
			// Equipping Receivers can change what is customizable
			if (SelectedPart == PT_RECEIVER)
				CreateValidPartCategory(PartTemplate);

			if (bMuzzleUnlocked)
			{
				ValidPartCategoryFlag[PT_MUZZLE] = true;
				
				if (SelectedPart == PT_BARREL && PartTemplate.bBarrel_IgnoreValidParts)
				{
					ValidPartCategoryFlag[PT_MUZZLE] = false;
				}
			}
		}

		WeaponCategoryControl.UpdateValidCategory(ValidPartCategoryFlag);
		
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade_Select");
	}
}

simulated function UpdateNavHelp()
{
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	// TODO: Figure out button scheme
	NavHelp.AddLeftHelp(m_strButton_SwapToWeaponUpgrade, , SwapToWeaponUpgradeScreen);
	
	if(`ISCONTROLLERACTIVE)
	{
		if( IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
		{
			NavHelp.AddCenterHelp(m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17): Removing inlined buttons
		}
		
		if (ActiveList == SlotsList)
		{
			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17): Removing inlined buttons
		}

		//NavHelp.AddCenterHelp(m_strSwitchPartCategoryNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LT_L2);
	}
	else
	{
		if( XComHQPresentationLayer(Movie.Pres) != none )
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
			PrevKey = `XEXPAND.ExpandString(PrevSoldierKey);
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
			NextKey = `XEXPAND.ExpandString(NextSoldierKey);

			if( IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
			{
				NavHelp.SetButtonType("XComButtonIconPC");
				i = eButtonIconPC_Prev_Soldier;
				NavHelp.AddCenterHelp(string(i), "", PrevSoldier, false, PrevKey);
				i = eButtonIconPC_Next_Soldier;
				NavHelp.AddCenterHelp(string(i), "", NextSoldier, false, NextKey);
				NavHelp.SetButtonType("");
			}
		}
	}
	NavHelp.Show();

	`XEVENTMGR.TriggerEvent('UIArmory_WeaponUpgrade_NavHelpUpdated', NavHelp, self, none);
}

simulated function UpdateCustomization(UIPanel DummyParam)
{
	local int i;

	// Clear any residual items
	CustomizeList.ClearItems();

	i = 0;

	// Blank Item to absorb weird bug with input box opening as first element
	GetCustomizeItem(i).UpdateDataDescription("DONOTSHOW").SetDisabled(true);
	GetCustomizeItem(i).DisableNavigation();
	GetCustomizeItem(i++).Hide();

	// WEAPON CATEGORY
	//-----------------------------------------------------------------------------------------
	WeaponCategorySpinnerIndex = i;
	GetCustomizeItem(i++).UpdateDataSpinner("", GetCategoryLabelString(SelectedPart), OnSpinnerCategoryChanged);

	// RESET WEAPON CUSTOMIZATION
	// Resets weapon to first valid parts on the weapon template
	//-----------------------------------------------------------------------------------------
	GetCustomizeItem(i++).UpdateDataDescription(m_strResetWeaponToDefault, OnWeaponCustomizationResetClicked);

	CustomizeList.SetPosition(CustomizationListX, CustomizationListY - CustomizeList.ShrinkToFit() - CustomizationListYPadding);
}

simulated function OpenWeaponNameInputBox()
{
	// Do nothing because clicking Weapon Category somehow brings up the input name box???
	return;
}

function OnWeaponCustomizationResetClicked()
{
	local TDialogueBoxData DialogData;

	// Create UIDialogBox warning player that weapon customization will be reset to defaults including appearance.
	DialogData.eType		= eDialog_Warning;
	DialogData.strTitle		= default.strCustomizationDestruction_DialogueTitle;
	DialogData.strText		= default.strCustomizationDestruction_DialogueText;
	DialogData.strAccept	= class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel	= class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ConfirmResetWeaponCustomizationCallback;
	Movie.Pres.UIRaiseDialog(DialogData);
}

function ConfirmResetWeaponCustomizationCallback(Name eAction)
{
	local XComGameStateContext_ChangeContainer 	ChangeContainer;
	local XComGameState 						ChangeState;
	local XCGS_WeaponGunsmith					NewGunsmithState;
	local XComGameState_Item 					Weapon;

	// Create change context
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Reset Weapon Gunsmith Visual To Defaults");
	ChangeState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

	Weapon 			  		= XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	NewGunsmithState 		= XCGS_WeaponGunsmith(Weapon.FindComponentObject(class'XCGS_WeaponGunsmith'));

	NewGunsmithState	= XCGS_WeaponGunsmith(ChangeState.ModifyStateObject(NewGunsmithState.Class, NewGunsmithState.ObjectID));

	// Reset back to default templates
	NewGunsmithState.ResetWeaponStateToDefault();

	CurrentGunsmithState = NewGunsmithState;

	`GAMERULES.SubmitGameState(ChangeState);

	// Swap back to Receiver category
	SwitchWeaponCategory(PT_RECEIVER, true);

	// Force a refresh
	PreviewUpgrade(SlotsList, 0);

	// Changing receivers may change the weapon name
	UpdateOwnerSoldier();
}

function OnSpinnerCategoryChanged(UIListItemSpinner SpinnerControl, int Direction)
{
	local bool CategoryFound;

	ModeSpinnerValue += direction;

	if (ModeSpinnerValue < PT_RECEIVER)
		ModeSpinnerValue = PT_OPTIC;
	else if (ModeSpinnerValue > PT_OPTIC)
		ModeSpinnerValue = PT_RECEIVER;

	// Check if we can access this category. If not, keep changing the index until there is such a category.
	CategoryFound = false;

	while (!CategoryFound)
	{
		if (ValidPartCategoryFlag[WeaponPartType(ModeSpinnerValue)] == true)
		{
			SelectedPart = WeaponPartType(ModeSpinnerValue); 
			break;
		}

		ModeSpinnerValue += direction;
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SpinnerControl.SetValue(GetCategoryLabelString(SelectedPart));
	WeaponCategoryControl.OnItemClicked(WeaponCategoryControl.PartsList, ModeSpinnerValue - 1);

	// Force a refresh on the slots
	UpdateSlots();
}

simulated function OnReceiveFocus()
{
	MouseGuard.ActorPawn = ActorPawn;
	super.OnReceiveFocus();

	// Sometimes these menu show up when swapping between Weapon Upgrade and Gunsmith
	WeaponStats.Hide(); 
	WeaponStats.SetAlpha(0.0f);
	UpgradesListContainer.Hide();
	UpgradesList.Hide();
}

function SwitchWeaponCategory(WeaponPartType NewPart, optional bool bForceChangeWeaponCategory = false)
{
	local UIMechaListItem Item;

	// 2nd item in the list (first one absorbs name input)
	Item = UIMechaListItem(CustomizeList.GetItem(WeaponCategorySpinnerIndex));

	SelectedPart = NewPart;

	Item.Spinner.SetValue(GetCategoryLabelString(SelectedPart));

	ModeSpinnerValue = int(SelectedPart);

	// Force a refresh on the slots
	UpdateSlots();

	if (bForceChangeWeaponCategory)
	{
		WeaponCategoryControl.OnItemClicked(WeaponCategoryControl.PartsList, ModeSpinnerValue);
	}
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	local XComGameState_Item Weapon;

	// If the unit doesn't have a specific weapon equipped, then prevent cycling
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference().ObjectID));

	// Logic taken from UIArmory_MainMenu
	return super.CanCycleTo(Unit) && X2ConfigWeaponAlphaTemplate(Weapon.GetMyTemplate()) != none;
}

// Close this screen and swap to Weapon Upgrade screen
function SwapToWeaponUpgradeScreen()
{
	local XComHQPresentationLayer	HQPres;
	local UIScreenStack				ScreenStack;
	local UIArmory					ArmoryScreen;
	local UIArmory_WeaponUpgrade	UpgradeScreen;
	local int i;

	ScreenStack = `SCREENSTACK;

	// Close this screen and open the weapon upgrade menu
	ScreenStack.PopFirstInstanceOfClass(class'UIArmory_WeaponGunsmith');

	HQPres = XComHQPresentationLayer(Movie.Pres);
	
	if( HQPres != none )
	{
		HQPres.UIArmory_WeaponUpgrade(GetUnitRef());
	}

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			ArmoryScreen.ReleasePawn();
			ArmoryScreen.SetUnitReference(GetUnitRef());
			ArmoryScreen.Header.UnitRef = GetUnitRef();
		}

		UpgradeScreen = UIArmory_WeaponUpgrade(ScreenStack.Screens[i]);
		if (UpgradeScreen != none)
		{
			UpgradeScreen.SetWeaponReference(WeaponRef);

			//Force refresh - otherwise we end up with out-of-date weapon pawn (showing customization from previous soldier)
			UpgradeScreen.PreviewUpgrade(UpgradeScreen.SlotsList, 0);
		}
	}
	
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	if (ActiveList != none)
	{
		switch (cmd)
		{
			case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
				if (CustomizeList != none && CustomizeList.OnUnrealCommand(cmd, arg))
				{
					return true;
				}

				break;

			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
			case class'UIUtilities_Input'.const.FXS_KEY_D:
				OnSpinnerCategoryChanged(GetCustomizeItem(0).Spinner, -1);
				break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
			case class'UIUtilities_Input'.const.FXS_KEY_A:
				OnSpinnerCategoryChanged(GetCustomizeItem(0).Spinner, 1);
				break;
		}
	}

	return super.OnUnrealCommand(cmd, arg);
}

//
// UTILITY FUNCTIONS
// 
// Commit the changes to the Item State and Gunsmith State
function X2ConfigWeaponPartTemplate InstallPartOnWeapon(int ItemIndex)
{
	local XComGameStateContext_ChangeContainer 	ChangeContainer;
	local XComGameState 						ChangeState;
	local XCGS_WeaponGunsmith					NewGunsmithState;
	local XComGameState_Item 					Weapon;
	
	local array<X2ConfigWeaponPartTemplate>		arrParts;
	local X2ConfigWeaponPartTemplate			PartTemplate;

	// Create change context
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Update Weapon Gunsmith Visual");
	ChangeState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

	Weapon 			  		= XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
	NewGunsmithState 		= XCGS_WeaponGunsmith(Weapon.FindComponentObject(class'XCGS_WeaponGunsmith'));

	NewGunsmithState	= XCGS_WeaponGunsmith(ChangeState.ModifyStateObject(NewGunsmithState.Class, NewGunsmithState.ObjectID));
	
	arrParts = GetSelectedWeaponParts();

	PartTemplate = arrParts[ItemIndex];

	// Update Gunsmith state with new template
	NewGunsmithState.SetPartTemplate(PartTemplate, SelectedPart, false, true);

	// It will be considered modified from now on, installing the part back on will not revert those changes
	if (!NewGunsmithState.bIsModified)
		NewGunsmithState.bIsModified = true;

	CurrentGunsmithState = NewGunsmithState;

	`GAMERULES.SubmitGameState(ChangeState);

	return PartTemplate;
}

// Redo for large amount of templates
// This code does not handle 1000s of templates which is inevitable.
// TODO: Should we store valid receivers on weapon templates if filtering is enabled?
function GetListOfWeaponParts()
{
	local X2ItemTemplateManager				ItemMgr;
	local X2DataTemplate					Template;
	local X2ConfigWeaponPartTemplate 		PartTemplate;
	local PartFilteringCriteria				Criteria, EmptyCriteria;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach ItemMgr.IterateTemplates(Template)
	{
		Criteria		= EmptyCriteria;
		PartTemplate	= X2ConfigWeaponPartTemplate(Template);

		if(PartTemplate != none)
		{
			//`LOG("Found Part Template " $ PartTemplate.DataName,, 'WotC_Gameplay_Misc_WeaponGunsmith_UI');
			
			Criteria.Template = PartTemplate;

			switch(PartTemplate.ePartName)
			{
				case PT_RECEIVER:
					arrWeaponPart_Receiver.AddItem(Criteria);
					break;
				case PT_BARREL:
					arrWeaponPart_Barrel.AddItem(Criteria);
					break;
				case PT_HANDGUARD:
					arrWeaponPart_Handguard.AddItem(Criteria);
					break;
				case PT_STOCK:
					arrWeaponPart_Stock.AddItem(Criteria);
					break;
				case PT_MAGAZINE:
					arrWeaponPart_Magazine.AddItem(Criteria);
					break;
				case PT_REARGRIP:
					arrWeaponPart_Reargrip.AddItem(Criteria);
					break;
				case PT_MUZZLE:
					if (PartTemplate.DataName == 'PT_SPECIAL_MUZZLE_NONE')
						arrWeaponPart_Muzzle.InsertItem(0, Criteria);
					else
						arrWeaponPart_Muzzle.AddItem(Criteria);
					break;
				case PT_UNDERBARREL:
					if (PartTemplate.DataName == 'PT_SPECIAL_UNDERBARREL_NONE')
						arrWeaponPart_Underbarrel.InsertItem(0, Criteria);
					else
						arrWeaponPart_Underbarrel.AddItem(Criteria);
					break;
				case PT_LASER:
					if (PartTemplate.DataName == 'PT_SPECIAL_LASER_NONE')
						arrWeaponPart_Laser.InsertItem(0, Criteria);
					else 
						arrWeaponPart_Laser.AddItem(Criteria);
					break;
				case PT_OPTIC:
					if (PartTemplate.DataName == 'PT_SPECIAL_OPTIC_NONE')
						arrWeaponPart_Optics.InsertItem(0, Criteria);
					else
						arrWeaponPart_Optics.AddItem(Criteria);
					break;
				// Spit out error
				case PT_NONE:
				case PT_MAX:
					break;
			}
		}
	}
}

// When the player inevitably switches weapons via this screen, we need to update the list of valid receivers for every new weapon.
function CheckReceiverCriteria(out PartFilteringCriteria Criteria)
{
	local XComGameState_Item 				Weapon;
	local X2ConfigWeaponPartTemplate		ReceiverTemplate;

	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	// Reset values
	Criteria.bAlwaysHide = false;
	Criteria.Reason = "";
	ReceiverTemplate = Criteria.Template;

	`LOG("Checking Receiver Part Template " $ ReceiverTemplate.DataName $ " for validation",, 'WotC_Gameplay_Misc_WeaponGunsmith_UI');

	if ( (ReceiverTemplate.arrWeaponTemplateWhitelist.Length > 0 && (ReceiverTemplate.arrWeaponTemplateWhitelist.Find(Weapon.GetMyTemplateName()) == INDEX_NONE)) )
	{
		`LOG("Receiver Part Template " $ ReceiverTemplate.DataName $ " invalid for current weapon " $ Weapon.GetMyTemplateName() $ ". Does not exist in Whitelist",, 'WotC_Gameplay_Misc_WeaponGunsmith_UI');

		Criteria.bAlwaysHide = true;
		Criteria.Reason = "Invalid Part for weapon";
	}
	else if ( (ReceiverTemplate.arrWeaponTemplateBlacklist.Length > 0 && (ReceiverTemplate.arrWeaponTemplateBlacklist.Find(Weapon.GetMyTemplateName()) != INDEX_NONE)) )
	{
		`LOG("Receiver Part Template " $ ReceiverTemplate.DataName $ " invalid for current weapon " $ Weapon.GetMyTemplateName() $ ". Exists in Blacklist",, 'WotC_Gameplay_Misc_WeaponGunsmith_UI');
		
		Criteria.bAlwaysHide = true;
		Criteria.Reason = "Invalid Part for weapon";
	}
}

function array<X2ConfigWeaponPartTemplate> GetSelectedWeaponParts()
{
	local array<PartFilteringCriteria>		arrPart;
	local PartFilteringCriteria				IterPart;
	local X2ConfigWeaponPartTemplate		ReceiverTemplate;
	local array<X2ConfigWeaponPartTemplate>	OutArray;
	local array<name> PartNames;
	local int i;

	// Just return the list of receivers for this weapon
	if (SelectedPart == PT_RECEIVER)
	{
		//`LOG("Checking " $ arrWeaponPart_Receiver.Length $ " receivers for validation",, 'WotC_Gameplay_Misc_WeaponGunsmith_UI');

		foreach arrWeaponPart_Receiver(IterPart, i)
		{
			if (!bReceiverValidationCheck)
			{
				CheckReceiverCriteria(IterPart);
				arrWeaponPart_Receiver[i] = IterPart;
			}
			
			// These parts will never be valid, so skip over them
			if (IterPart.bAlwaysHide)
				continue;

			OutArray.AddItem(IterPart.Template);
		}
		
		bReceiverValidationCheck = true;
		
		return OutArray;
	}

	if (bFilteringDisabled)
	{
		return GetSelectedWeaponParts_DEBUG();
	}

	// Determine the currently equipped Receiver and start filtering the arrays
	ReceiverTemplate = CurrentGunsmithState.GetPartTemplate(PT_RECEIVER);

	// If this happens something went wrong
	if ( ReceiverTemplate == none)
		return OutArray;

	switch(SelectedPart)
	{
		case PT_BARREL:
			PartNames	= ReceiverTemplate.ValidParts_Barrel;
			arrPart		= arrWeaponPart_Barrel;
		break;
		case PT_HANDGUARD:
			PartNames	= ReceiverTemplate.ValidParts_Handguard;
			arrPart		= arrWeaponPart_Handguard;
		break;
		case PT_STOCK:
			PartNames	= ReceiverTemplate.ValidParts_Stock;
			arrPart		= arrWeaponPart_Stock;
		break;
		case PT_MAGAZINE:
			PartNames	= ReceiverTemplate.ValidParts_Magazine;
			arrPart		= arrWeaponPart_Magazine;
		break;
		case PT_REARGRIP:
			PartNames	= ReceiverTemplate.ValidParts_Reargrip;
			arrPart		= arrWeaponPart_Reargrip;
		break;
		case PT_MUZZLE:
			PartNames	= ReceiverTemplate.ValidParts_Muzzle;
			arrPart		= arrWeaponPart_Muzzle;
		break;
		case PT_UNDERBARREL:
			PartNames	= ReceiverTemplate.ValidParts_Underbarrel;
			arrPart		= arrWeaponPart_Underbarrel;
		break;
		case PT_LASER:
			PartNames	= ReceiverTemplate.ValidParts_Laser;
			arrPart		= arrWeaponPart_Laser;
		break;
		case PT_OPTIC:
			PartNames	= ReceiverTemplate.ValidParts_Optics;
			arrPart		= arrWeaponPart_Optics;
		break;
		// Spit out error
		case PT_NONE:
		case PT_MAX:
			break;
	}

	foreach arrPart(IterPart)
	{
		// These parts will never be valid, so skip over them
		if (IterPart.bAlwaysHide)
			continue;

		if (PartNames.Find(IterPart.Template.DataName) == INDEX_NONE)
			continue;

		OutArray.AddItem(IterPart.Template);
	}

	return OutArray;
}

function array<X2ConfigWeaponPartTemplate> GetSelectedWeaponParts_DEBUG()
{
	local array<PartFilteringCriteria>		arrPart;
	local PartFilteringCriteria				IterPart;
	local array<X2ConfigWeaponPartTemplate>	OutArray;

	switch(SelectedPart)
	{
		case PT_RECEIVER:
			arrPart = arrWeaponPart_Receiver; 
			break;
		case PT_BARREL:
			arrPart = arrWeaponPart_Barrel; 
			break;
		case PT_HANDGUARD:
			arrPart = arrWeaponPart_Handguard;
			break;
		case PT_STOCK:
			arrPart = arrWeaponPart_Stock; 
			break;
		case PT_MAGAZINE:
			arrPart = arrWeaponPart_Magazine; 
			break;
		case PT_REARGRIP:
			arrPart = arrWeaponPart_Reargrip; 
			break;
		case PT_MUZZLE:
			arrPart = arrWeaponPart_Muzzle; 
			break;
		case PT_UNDERBARREL:
			arrPart = arrWeaponPart_Underbarrel; 
			break;
		case PT_LASER:
			arrPart = arrWeaponPart_Laser; 
			break;
		case PT_OPTIC:
			arrPart = arrWeaponPart_Optics; 
			break;
		// Spit out error
		case PT_NONE:
		case PT_MAX:
			break;
	}

	foreach arrPart(IterPart)
	{
		OutArray.AddItem(IterPart.Template);
	}

	return OutArray;
}

static function string GetCategoryLabelString(WeaponPartType Part)
{
	switch(Part)
	{
		case PT_RECEIVER:
			return default.m_strWPNPartCategory_Receiver; break;
		case PT_BARREL:
			return default.m_strWPNPartCategory_Barrel; break;
		case PT_HANDGUARD:
			return default.m_strWPNPartCategory_Handguard; break;
		case PT_STOCK:
			return default.m_strWPNPartCategory_Stock; break;
		case PT_MAGAZINE:
			return default.m_strWPNPartCategory_Magazine; break;
		case PT_REARGRIP:
			return default.m_strWPNPartCategory_Reargrip; break;
		case PT_MUZZLE:
			return default.m_strWPNPartCategory_Muzzle; break;
		case PT_UNDERBARREL:
			return default.m_strWPNPartCategory_Underbarrel; break;
		case PT_LASER:
			return default.m_strWPNPartCategory_Laser; break;
		case PT_OPTIC:
			return default.m_strWPNPartCategory_Optics; break;
		// Spit out error
		case PT_NONE:
		case PT_MAX:
			break;
	}

	return "";
}

function bool HasWeaponUpgrade(array<name> CurrentWeaponUpgrades, array<name> AnyFilter)
{
	local name TestTemplate;

	foreach CurrentWeaponUpgrades(TestTemplate)
	{
		if (AnyFilter.Find(TestTemplate) != INDEX_NONE)
			return true;
	}

	return false;
}

function bool IsAnyPartValid()
{
	local byte i;

	i = PT_MAX;
	while(i > PT_RECEIVER)
	{
		if (ValidPartCategoryFlag[i])
			return true;

		--i;
	}

	return false;
}

defaultproperties
{
	LibID = "WeaponUpgradeScreenMC";
	CameraTag = "UIBlueprint_Loadout";
	DisplayTag = "UIBlueprint_Loadout";
	bHideOnLoseFocus = false;
}