class X2DownloadableContentInfo_WotC_GunsmithWeapons extends X2DownloadableContentInfo;

var config bool bLog;
var config bool bEnableAddingWeaponsToHQ;

var config int WeaponNicknames_MaxCharacterLimit;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	if (!default.bEnableAddingWeaponsToHQ)
		return;
 
	UpdateStorage();
}

static event OnLoadedSavedGameToStrategy()
{
	if (!default.bEnableAddingWeaponsToHQ)
		return;
 
	UpdateStorageOnEveryLoad();
}

//This function checks if a mod is installed
static function bool CheckForActiveMod(string DLCName) {
    local string CurrentMod;

    foreach class'XComModOptions'.default.ActiveMods(CurrentMod) {
        if (CurrentMod == DLCName) {
            return true;
        }
    }

    return false;
}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
//	class'X2Item_Global_Upgrades'.static.AddAllAttachments();
}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
	EnlistObjectsToTactical(StartGameState);
}

static function UpdateStorageOnEveryLoad()
{
    local XComGameState NewGameState;
    local XComGameStateHistory History;
    local XComGameState_HeadquartersXCom XComHQ;
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2ItemTemplate ItemTemplate;
    local XComGameState_Item NewItemState;
	local int x;

    History = `XCOMHISTORY;
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.class $ "::" $ GetFuncName());
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    NewGameState.AddStateObject(XComHQ);
    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    for(x = 0; x < class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates.Length; x++)
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates[x].ReqItem);
		if(XComHQ.HasItem(ItemTemplate)) // Does XComHQ have the required item?
		{
			ItemTemplate = ItemTemplateMgr.FindItemTemplate(class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates[x].TemplateName);
			if(ItemTemplate != none && !XComHQ.HasItem(ItemTemplate)) // Does XComHQ NOT have the new item?
			{
                NewItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
                `LOG("Created " $ ItemTemplate.DataName $ " with ItemState ObjectID: " $ NewItemState.ObjectID,default.bLog, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
                NewGameState.AddStateObject(NewItemState);
                XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}
	History.AddGameStateToHistory(NewGameState);
}

// ******** HANDLE UPDATING STORAGE ************* //
static function UpdateStorage()
{
    local XComGameState NewGameState;
    local XComGameStateHistory History;
    local XComGameState_HeadquartersXCom XComHQ;
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2ItemTemplate ItemTemplate;
    local XComGameState_Item NewItemState;
	local int x;
 
    History = `XCOMHISTORY;
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.class $ "::" $ GetFuncName());
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    NewGameState.AddStateObject(XComHQ);
    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    for(x = 0; x < class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates.Length; x++)
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates[x].ReqItem);
		if(XComHQ.HasItem(ItemTemplate)) // Does XComHQ have the required item?
		{
			ItemTemplate = ItemTemplateMgr.FindItemTemplate(class'X2Weapon_GunsmithWeapons'.default.WeaponTemplates[x].TemplateName);
			if(ItemTemplate != none && !XComHQ.HasItem(ItemTemplate)) // Does XComHQ NOT have the new item?
			{
                NewItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
                `LOG("Created " $ ItemTemplate.DataName $ " with ItemState ObjectID: " $ NewItemState.ObjectID, default.bLog, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
                NewGameState.AddStateObject(NewItemState);
                XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}
	History.AddGameStateToHistory(NewGameState);
	History.CleanupPendingGameState(NewGameState);
}


// This function has no knowledge of any variables in this gamestate class
static function EnlistObjectsToTactical(XComGameState StartGameState)
{
	local XComGameStateHistory				History;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_Unit				UnitState;
	local StateObjectReference				UnitRef;
	local array<XComGameState_Item>			arrItems;
	local XComGameState_Item				SingleItem;
	local XCGS_WeaponGunsmith				GunsmithState;

	// Iterate through every primary/secondary weapon in the squad's inventory for our gunsmith component
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;

	foreach XComHQ.Squad(UnitRef)
	{
		UnitState = XComGameState_Unit(StartGameState.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState == none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID)); 
			if (UnitState == none)
				continue;
		}

		arrItems = UnitState.GetAllInventoryItems();
		
		// Support for weapons in the utility or teriary slots
		foreach arrItems(SingleItem)
		{
			if ( X2ConfigWeaponAlphaTemplate(SingleItem.GetMyTemplate()) == none )
				continue;

			// Enlist the object to tactical if it exists
			GunsmithState = XCGS_WeaponGunsmith(SingleItem.FindComponentObject(class'XCGS_WeaponGunsmith'));
			if (GunsmithState != none)
				GunsmithState = XCGS_WeaponGunsmith(StartGameState.ModifyStateObject(GunsmithState.Class, GunsmithState.ObjectID));
		}
	}
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local XComGameState_Item	Weapon;
	local XCGS_WeaponGunsmith	WeaponGunsmithState;

	if (!UnitState.IsSoldier())
		return;

	Weapon = UnitState.GetPrimaryWeapon();

	if (X2ConfigWeaponAlphaTemplate(Weapon.GetMyTemplate()) == none)
	{
		//`LOG("Template " $ Weapon.GetMyTemplateName() $ " is not a Gunsmithable weapon", ,'WotC_Gameplay_Misc_WeaponGunsmith');
		return;
	}

	WeaponGunsmithState = XCGS_WeaponGunsmith(Weapon.FindComponentObject(class'XCGS_WeaponGunsmith'));

	if (WeaponGunsmithState == none)
	{
		//`LOG("Gunsmith weapon " $ Weapon.GetMyTemplateName() $ " but has no gunsmith state!", ,'WotC_Gameplay_Misc_WeaponGunsmith');
		return;
	}
		
	if (WeaponGunsmithState.ShouldUseRifleGrip() == false)
	{
		//`LOG("Template " $ Weapon.GetMyTemplateName() $ " doesn't need rifle grip animations", ,'WotC_Gameplay_Misc_WeaponGunsmith');
		return;
	}

	//`LOG("Adding Rifle Grip animations to soldier", ,'WotC_Gameplay_Misc_WeaponGunsmith');

	if (UnitState.kAppearance.iGender == eGender_Female)
	{
		if (UnitState.GetMyTemplateName() == 'ReaperSoldier')
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory_Fem")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_ReaperShadow")));
		}
		else if (UnitState.GetMyTemplateName() == 'SkirmisherSoldier')
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory_Fem")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Skirmisher_RifleGrip_Master_ANIM.Anims.AS_Skirmisher")));
		}
		else
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory_Fem")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
		}
	}
	else
	{
		if (UnitState.GetMyTemplateName() == 'ReaperSoldier')
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_ReaperShadow")));
		}
		else if (UnitState.GetMyTemplateName() == 'SkirmisherSoldier')
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Skirmisher_RifleGrip_ANIM.Anims.AS_Skirmisher")));
		}
		else
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("HQArmory_Soldier_Master_ANIM.Anims.AS_Soldier_BattleRifle_M14_Armory")));
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_RifleGrip_Master_ANIM.Anims.AS_Soldier")));
		}
	}
}