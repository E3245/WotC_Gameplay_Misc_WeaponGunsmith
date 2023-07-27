class UIPanel_WeaponCategoryControl extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		OptionsListContainer;
var UIList		OptionsList;
var UIText		TitleText;

var UIX2PanelHeader TitleHeader;

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

	// V1.005: Updated Background
	BGFrame = Spawn(class'UIBGBox', self);
	BGFrame.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	BGFrame.InitBG('theBG');
	BGFrame.SetAlpha(80);
	BGFrame.SetSize(320, 480);
//	BGFrame.SetOutline(true);

	OptionsListContainer = Spawn(class'UIPanel', self);
	OptionsListContainer.bAnimateOnInit = false;
	
	OptionsList = Spawn(class'UIList', self);
	OptionsList.InitList('OptionsListMC');
	OptionsList.SetSize(300, 400);
	OptionsList.SetPosition(5, 50);
	OptionsList.bStickyHighlight = false;
	OptionsList.bAutosizeItems = false;
	OptionsList.bAnimateOnInit = false;
	OptionsList.bSelectFirstAvailable = false;
	OptionsList.ItemPadding = 0;
//	OptionsList.OnSelectionChanged = PreviewUpgrade;
	OptionsList.OnItemClicked = OnItemClicked;
	OptionsList.Navigator.LoopSelection = false;	
//	//INS: - JTA 2016/3/2
//	OptionsList.bLoopSelection = false;
//	OptionsList.Navigator.LoopOnReceiveFocus = true;
//	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
//	OptionsList.bCascadeFocus = true;
//	OptionsList.bPermitNavigatorToDefocus = true;
//
	// V1.005: Updated Text
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('', class'UIArmory_WeaponGunsmith'.default.m_PartSelectorTitle, "");
	TitleHeader.SetPosition(5, 1);
	TitleHeader.SetHeaderWidth(BGFrame.Width);

	BuildMenuList();
}

function BuildMenuList()
{
	local byte				i;
	local UIListItemString	Item;

	OptionsList.ClearItems();

	for(i = PT_RECEIVER; i < PT_MAX; ++i)
	{
		Item = UIListItemString(OptionsList.CreateItem(class'UIListItemString')).InitListItem(class'UIArmory_WeaponGunsmith'.static.GetCategoryLabelString(WeaponPartType(i), UIArmory_WeaponGunsmith(Screen).SelectedReceiverTemplate));
		Item.metadataInt = i;

		if (ValidPartCategory[i] == false)
		{
			Item.DisableListItem();
		}
		else if (ValidPartCategory[i] && UIArmory_WeaponGunsmith(Screen).SelectedPart == WeaponPartType(i) )
		{
			Item.ShouldShowGoodState(true);
			OptionsList.SetSelectedIndex(i - 1);
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

	UIListItemString(OptionsList.GetItem(Val)).DisableListItem();
}

function UpdateValidCategory(array<bool> arrNewValidCategories)
{
	local byte i;
	ValidPartCategory = arrNewValidCategories;

	for( i = 0 ; i < OptionsList.ItemCount; ++i)
	{
		//Update names
		UIListItemString(OptionsList.GetItem(i)).SetText(class'UIArmory_WeaponGunsmith'.static.GetCategoryLabelString(WeaponPartType(i + 1), UIArmory_WeaponGunsmith(Screen).SelectedReceiverTemplate));

		if (ValidPartCategory[i + 1] == false)
		{
			UIListItemString(OptionsList.GetItem(i)).OnLoseFocus();	// Sometimes the bar stays highlighted when switching to a disabled state.
			UIListItemString(OptionsList.GetItem(i)).DisableListItem();
		}
		else
		{
			UIListItemString(OptionsList.GetItem(i)).EnableListItem();
		}
	}
}