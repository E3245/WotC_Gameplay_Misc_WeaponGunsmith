class X2EventListener_GunsmithWeapons extends X2EventListener;

var localized string m_strWeaponGunsmithTitle;
var localized string m_strWeaponGunsmithTooltip;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateArmoryUIListeners());
	Templates.AddItem(CreateUpgradeItemFix());

	return Templates;
}

static function CHEventListenerTemplate CreateArmoryUIListeners()
{
	local CHEventListenerTemplate Template;
	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'UIArmory_WeaponGunsmith_Button');
	Template.AddCHEvent('OnArmoryMainMenuUpdate', 	UIArmory_AddGunsmithButtonIfPossible, ELD_Immediate);
	Template.AddCHEvent('UIArmory_WeaponUpgrade_NavHelpUpdated', UIArmory_WeaponUpgrade_AddSwapButton, ELD_Immediate, 100);	// Lowest Priority
	Template.RegisterInStrategy = true;

	return Template;
}

static protected function EventListenerReturn UIArmory_AddGunsmithButtonIfPossible(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local UIList			List;
	local UIArmory_MainMenu	Screen;
	local UIListItemString	GunsmithButton;
	local int				ToIdx;

	// Grab the list and Screen from the Event Listener
	Screen = UIArmory_MainMenu(EventSource);
	List   = UIList(EventData);

	if (List == none || Screen == none)
		return ELR_NoInterrupt;

	// Check if the weapon equipped on the soldier is a X2ConfigWeaponAlphaTemplate
	// Don't add the button if it's not this particular template
	if (X2ConfigWeaponAlphaTemplate( Screen.GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate() ) == none )
	{
		return ELR_NoInterrupt;
	}

	// Create a button and insert it below Weapon Customization
	// TODO: Swap Children
	GunsmithButton = Screen.Spawn(class'UIListItemString', List.ItemContainer).InitListItem(default.m_strWeaponGunsmithTitle);
	GunsmithButton.MCName = 'ArmoryMainMenu_WeaponGunsmithButton';
	GunsmithButton.ButtonBG.OnClickedDelegate	= static.OnWeaponGunsmith;
	GunsmithButton.metadataInt					= Screen.UnitReference.ObjectID;	// Store ObjectID into metadata
	GunsmithButton.ShouldShowGoodState(true, default.m_strWeaponGunsmithTooltip);

	if (!`XCOMHQ.bModularWeapons)
		GunsmithButton.SetDisabled(true, class'UIFacility_Armory'.default.m_strRequireModularWeapon);

	// Our index is going to start at the bottom, swap up until we find the button to be under
	ToIdx		= List.GetItemIndex(Screen.WeaponUpgradeButton);
	MoveButtonToPosition(List, GunsmithButton, ToIdx + 1);

	return ELR_NoInterrupt;
}

// Provided by Iridar's Dynamic Deployment mod
static function MoveButtonToPosition(UIList List, UIPanel Item, int Pos)
{
	local int StartingIndex, ItemIndex;

	StartingIndex = List.GetItemIndex(Item);

	if(StartingIndex != INDEX_NONE)
	{
		if(List.SelectedIndex > INDEX_NONE && List.SelectedIndex < List.ItemCount)
			List.GetSelectedItem().OnLoseFocus();

		ItemIndex = StartingIndex;
		while(ItemIndex > Pos)
		{
			List.ItemContainer.SwapChildren(ItemIndex, ItemIndex - 1);
			ItemIndex--;
		}

		List.RealizeItems();

		if(List.SelectedIndex > INDEX_NONE && List.SelectedIndex < List.ItemCount)
			List.GetSelectedItem().OnReceiveFocus();
	}

	//if we move the currently selected item to the top, change the selection to the item that got moved into that location
	if(StartingIndex == List.SelectedIndex && List.OnSelectionChanged != none)
		List.OnSelectionChanged(List, List.SelectedIndex);
}

static function OnWeaponGunsmith(UIButton kButton)
{
	local XComHQPresentationLayer	HQPres;
	local StateObjectReference		UnitRef;
	local UIListItemString			ItemString;

	ItemString = UIListItemString(kButton.ParentPanel);

	if (ItemString.bDisabled)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return;
	}

	HQPres = XComHQPresentationLayer(kButton.Movie.Pres);

	// Remove pawn for Weapon Upgrade
	if (`ScreenStack.IsInStack(class'UIArmory_MainMenu'))
	{
		UIArmory(`ScreenStack.GetFirstInstanceOf(class'UIArmory_MainMenu')).ReleasePawn();
	}

	UnitRef.ObjectID = ItemString.metadataInt;
	
	// Open Weapon Gunsmith if Modular Weapons is unlocked
	if( HQPres != none && `ScreenStack.IsNotInStack(class'UIArmory_WeaponGunsmith') )
	{
		UIArmory_WeaponGunsmith(`ScreenStack.Push(HQPres.Spawn(class'UIArmory_WeaponGunsmith', HQPres), HQPres.Get3DMovie())).InitArmory(UnitRef);
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

static protected function EventListenerReturn UIArmory_WeaponUpgrade_AddSwapButton(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local UINavigationHelp NavHelp;
	local UIArmory_WeaponUpgrade Screen;

	NavHelp = UINavigationHelp(EventData);
	Screen = UIArmory_WeaponUpgrade(EventSource);

	if (NavHelp == none || Screen == none)
		return ELR_NoInterrupt;

	// Two buttons show up if we don't filter against our custom screen
	if (Screen.Class == class'UIArmory_WeaponGunsmith')
		return ELR_NoInterrupt;

	// Check if the weapon equipped on the soldier is a X2ConfigWeaponAlphaTemplate
	// Don't add the button if it's not this particular template
	if (X2ConfigWeaponAlphaTemplate( Screen.GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate() ) == none )
	{
		return ELR_NoInterrupt;
	}

	NavHelp.AddLeftHelp(class'UIArmory_WeaponGunsmith'.default.m_strButton_SwapToWeaponGunsmith, , SwapToWeaponGunsmith);

	return ELR_NoInterrupt;
}

function SwapToWeaponGunsmith()
{
	local XComHQPresentationLayer	HQPres;
	local UIScreenStack				ScreenStack;
	local UIArmory					ArmoryScreen;
	local UIArmory_WeaponGunsmith	GunsmithScreen;
	local StateObjectReference		UnitRef, WeaponRef;
	local int i;

	ScreenStack = `SCREENSTACK;

	WeaponRef	= UIArmory_WeaponUpgrade(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory_WeaponUpgrade')).WeaponRef;
	UnitRef		= UIArmory(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory')).GetUnit().GetReference();

	// Close this screen and open the weapon upgrade menu
	ScreenStack.PopFirstInstanceOfClass(class'UIArmory_WeaponUpgrade');

	HQPres = `HQPRES;
	
	if( HQPres != none && `ScreenStack.IsNotInStack(class'UIArmory_WeaponGunsmith') )
	{
		UIArmory_WeaponGunsmith(`ScreenStack.Push(HQPres.Spawn(class'UIArmory_WeaponGunsmith', HQPres), HQPres.Get3DMovie())).InitArmory(UnitRef);
	}

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			ArmoryScreen.ReleasePawn();
			ArmoryScreen.SetUnitReference(UnitRef);
			ArmoryScreen.Header.UnitRef = UnitRef;
		}

		GunsmithScreen = UIArmory_WeaponGunsmith(ScreenStack.Screens[i]);
		if ( GunsmithScreen != none )
		{
			GunsmithScreen.SetWeaponReference(WeaponRef);	// Weapon Pawn doesn't appear correctly otherwise
		}
	}
	
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

static function CHEventListenerTemplate CreateUpgradeItemFix()
{
	local CHEventListenerTemplate Template;
	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'UIArmory_WeaponGunsmith_Button');
	Template.AddCHEvent('ItemUpgraded', UpgradeGunsmithItem, ELD_OnStateSubmitted, 50);
	Template.RegisterInStrategy = true;

	return Template;
}

static protected function EventListenerReturn UpgradeGunsmithItem(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Item	UpgradedItem, BaseItem;
	local XCGS_WeaponGunsmith	WeaponGunsmithState;

	UpgradedItem	= XComGameState_Item(EventData);
	BaseItem		= XComGameState_Item(EventSource);

	// Both items need to exist
	if (UpgradedItem == none || BaseItem == none)
		return ELR_NoInterrupt;

	// Check if the BaseItem is a GS weapon and has a modded GS component
	if ( X2ConfigWeaponAlphaTemplate(BaseItem.GetMyTemplate()) == none)
		return ELR_NoInterrupt;

	WeaponGunsmithState = XCGS_WeaponGunsmith(BaseItem.FindComponentObject(class'XCGS_WeaponGunsmith'));

	// Exit if no GS state or GS state is left untouched
	if ( (WeaponGunsmithState == none) || (WeaponGunsmithState != none && !WeaponGunsmithState.bIsModified) )
		return ELR_NoInterrupt;

	// Add our GS component to the next weapon tier
	UpgradedItem.AddComponentObject(WeaponGunsmithState);
}