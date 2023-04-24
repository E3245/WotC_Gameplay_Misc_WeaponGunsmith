class UIPanel_WeaponCategoryControl extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		PartsListContainer;
var UIList		PartsList;
var UIText		TitleText;

var byte		SelectedIndex;

var array<bool>	ValidPartCategory;

function UIPanel_WeaponCategoryControl InitControlPanel(name InitName, optional array<bool> arrInitValidCategories)
{
	InitPanel(InitName);

	ValidPartCategory = arrInitValidCategories;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	BGFrame = Spawn(class'UIBGBox', self).InitBG('');
	BGFrame.SetSize(320, 480);
//	BGFrame.SetOutline(true);

	PartsListContainer = Spawn(class'UIPanel', self);
	PartsListContainer.bAnimateOnInit = false;
	
	PartsList = Spawn(class'UIList', self);
	PartsList.InitList('PartsListMC');
	PartsList.SetSize(300, 400);
	PartsList.SetPosition(5, 50);
	PartsList.bStickyHighlight = false;
	PartsList.bAutosizeItems = false;
	PartsList.bAnimateOnInit = false;
	PartsList.bSelectFirstAvailable = false;
	PartsList.ItemPadding = 0;
//	PartsList.OnSelectionChanged = PreviewUpgrade;
	PartsList.OnItemClicked = OnItemClicked;
	PartsList.Navigator.LoopSelection = false;	
//	//INS: - JTA 2016/3/2
//	PartsList.bLoopSelection = false;
//	PartsList.Navigator.LoopOnReceiveFocus = true;
//	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
//	PartsList.bCascadeFocus = true;
//	PartsList.bPermitNavigatorToDefocus = true;
//

	TitleText = Spawn(class'UIText', self).InitText('HeaderText', class'UIArmory_WeaponGunsmith'.default.m_PartSelectorTitle, true);
	TitleText.SetPosition(5, 1);

	BuildMenuList();
}

function BuildMenuList()
{
	local byte				i;
	local UIListItemString	Item;

	PartsList.ClearItems();

	for(i = PT_RECEIVER; i < PT_MAX; ++i)
	{
		Item = UIListItemString(PartsList.CreateItem(class'UIListItemString')).InitListItem(class'UIArmory_WeaponGunsmith'.static.GetCategoryLabelString(WeaponPartType(i), UIArmory_WeaponGunsmith(Screen).SelectedReceiverTemplate));
		Item.metadataInt = i;

		if (ValidPartCategory[i] == false)
		{
			Item.DisableListItem();
		}
		else if (ValidPartCategory[i] && UIArmory_WeaponGunsmith(Screen).SelectedPart == WeaponPartType(i) )
		{
			Item.ShouldShowGoodState(true);
			PartsList.SetSelectedIndex(i - 1);
			SelectedIndex = i - 1;	// Iteration starts at 1 instead of 0. For lists, it starts at 0
		}
	}
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local UIListItemString	Item;

	Item = UIListItemString(ContainerList.GetItem(ItemIndex));

	if (Item.bDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	UIArmory_WeaponGunsmith(Screen).SwitchWeaponCategory(WeaponPartType(Item.metadataInt));

	// Reset the old button
	UIListItemString(ContainerList.GetItem(SelectedIndex)).ShouldShowGoodState(false);

	SelectedIndex = byte(ItemIndex);

	// Set the new button as the selected button
	UIListItemString(ContainerList.GetItem(ItemIndex)).ShouldShowGoodState(true);
}

function DisableListItem(WeaponPartType PartName)
{
	local int Val;

	Val = PartName - 1;

	UIListItemString(PartsList.GetItem(Val)).DisableListItem();
}

function UpdateValidCategory(array<bool> arrNewValidCategories)
{
	local byte i;
	ValidPartCategory = arrNewValidCategories;

	for( i = 0 ; i < PartsList.ItemCount; ++i)
	{
		//Update names
		UIListItemString(PartsList.GetItem(i)).SetText(class'UIArmory_WeaponGunsmith'.static.GetCategoryLabelString(WeaponPartType(i + 1), UIArmory_WeaponGunsmith(Screen).SelectedReceiverTemplate));

		if (ValidPartCategory[i + 1] == false)
		{
			UIListItemString(PartsList.GetItem(i)).OnLoseFocus();	// Sometimes the bar stays highlighted when switching to a disabled state.
			UIListItemString(PartsList.GetItem(i)).DisableListItem();
		}
		else
		{
			UIListItemString(PartsList.GetItem(i)).EnableListItem();
		}
	}
}