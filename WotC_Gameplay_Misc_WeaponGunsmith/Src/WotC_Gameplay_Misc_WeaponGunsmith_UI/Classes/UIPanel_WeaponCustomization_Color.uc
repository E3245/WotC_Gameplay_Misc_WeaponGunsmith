class UIPanel_WeaponCustomization_Color extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		ColorListContainer;
var UIList		ColorList;

var UIX2PanelHeader TitleHeader;

var bool		bEnableTertiaryColor;

var delegate<GunsmithDataStructures.delColorValue> OnPrimaryColorChanged;
var delegate<GunsmithDataStructures.delColorValue> OnSecondaryColorChanged;
var delegate<GunsmithDataStructures.delColorValue> OnTertiaryColorChanged;

var UIMechaListItem_ColorEditor	PrimaryColorHeaderListItem;
var UIMechaListItem_ColorEditor	PrimaryColorRListItem;
var UIMechaListItem_ColorEditor	PrimaryColorGListItem;
var UIMechaListItem_ColorEditor	PrimaryColorBListItem;

var UIMechaListItem_ColorEditor	SecondaryColorHeaderListItem;
var UIMechaListItem_ColorEditor	SecondaryColorRListItem;
var UIMechaListItem_ColorEditor	SecondaryColorGListItem;
var UIMechaListItem_ColorEditor	SecondaryColorBListItem;

var UIMechaListItem_ColorEditor	TertiaryColorHeaderListItem;
var UIMechaListItem_ColorEditor	TertiaryColorRListItem;
var UIMechaListItem_ColorEditor	TertiaryColorGListItem;
var UIMechaListItem_ColorEditor	TertiaryColorBListItem;

var LinearColor PrimaryColor;
var LinearColor SecondaryColor;
var LinearColor TertiaryColor;

var localized string strTitle_PrimaryColor;
var localized string strTitle_SecondaryColor;
var localized string strTitle_TertiaryColor;

var localized string strHeader;
var localized string strTitle_TextBox_PrimaryColor;
var localized string strTitle_TextBox_SecondaryColor;
var localized string strTitle_TextBox_TertiaryColor;

function UIPanel_WeaponCustomization_Color InitColorPanel(name InitName, bool EnableTertiaryColors)
{
	InitPanel(InitName);

	PrimaryColor = MakeLinearColor(1, 0, 0, 1);
	SecondaryColor = MakeLinearColor(0, 1, 0, 1);
	TertiaryColor = MakeLinearColor(0, 0, 1, 1);

	bEnableTertiaryColor = EnableTertiaryColors;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	BGFrame = Spawn(class'UIBGBox', self);
	BGFrame.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	BGFrame.InitBG('theBG');
	BGFrame.SetAlpha(80);
	BGFrame.SetSize(330, 370);
//	BGFrame.SetOutline(true);

	ColorListContainer = Spawn(class'UIPanel', self);
	ColorListContainer.bAnimateOnInit = false;
	
	ColorList = Spawn(class'UIList', self);
	ColorList.InitList('OptionsListMC');
	ColorList.SetSize(320, 370);
	ColorList.SetPosition(5, 50);
	ColorList.bStickyHighlight = false;
	ColorList.bAutosizeItems = false;
	ColorList.bAnimateOnInit = false;
	ColorList.bSelectFirstAvailable = false;
	ColorList.ItemPadding = 0;
//	ColorList.OnSelectionChanged = PreviewUpgrade;
//	ColorList.OnItemClicked = OnItemClicked;
	ColorList.Navigator.LoopSelection = false;	
	ColorList.Hide();
//	//INS: - JTA 2016/3/2
//	ColorList.bLoopSelection = false;
//	ColorList.Navigator.LoopOnReceiveFocus = true;
//	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
//	ColorList.bCascadeFocus = true;
//	ColorList.bPermitNavigatorToDefocus = true;
//
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('', strHeader, "");
	TitleHeader.SetPosition(5, 1);
	TitleHeader.SetHeaderWidth(BGFrame.Width);

	if (bEnableTertiaryColor)
		EnableTertiaryColorPanel();
	else
		DisableTertiaryColorPanel();


	ColorList.Show();
}

function EnableTertiaryColorPanel()
{
	// Make sure the boolean is actually set
	if (bEnableTertiaryColor == false)
		bEnableTertiaryColor = true;

	// Resize the panels
	BGFrame.SetHeight(520);
	ColorList.SetHeight(520);

	BuildMenuList();
}

function DisableTertiaryColorPanel()
{
	// Make sure the boolean is actually set
	if (bEnableTertiaryColor == true)
		bEnableTertiaryColor = false;

	BGFrame.SetHeight(370);
	ColorList.SetHeight(370);

	BuildMenuList();
}

//
// Updates the color and all the elements associated with said color
function BuildMenuList()
{
	ColorList.ClearItems();

	PrimaryColorHeaderListItem = CreateMechListItem();
	PrimaryColorHeaderListItem.UpdateDataColorChipWithText(strTitle_PrimaryColor, PrimaryColor, OpenPrimaryColorInputBox );

	PrimaryColorRListItem = CreateMechListItem();
	PrimaryColorRListItem.UpdateDataSliderWithColorBlocks("0xFF0000", "" $ Round(PrimaryColor.R * 255), Round(PrimaryColor.R * 100),, UpdateRedPriSlider);
	PrimaryColorRListItem.Slider.SetPercent(PrimaryColor.R * 100);

	PrimaryColorGListItem = CreateMechListItem();
	PrimaryColorGListItem.UpdateDataSliderWithColorBlocks("0x00FF00",  "" $ Round(PrimaryColor.G * 255), Round(PrimaryColor.G * 100),, UpdateGreenPriSlider);
	PrimaryColorGListItem.Slider.SetPercent(PrimaryColor.G * 100);

	PrimaryColorBListItem = CreateMechListItem();
	PrimaryColorBListItem.UpdateDataSliderWithColorBlocks("0x0000FF",  "" $ Round(PrimaryColor.R * 255), Round(PrimaryColor.B * 100),, UpdateBluePriSlider);
	PrimaryColorBListItem.Slider.SetPercent(PrimaryColor.B * 100);

	SecondaryColorHeaderListItem = CreateMechListItem();
	SecondaryColorHeaderListItem.UpdateDataColorChipWithText(strTitle_SecondaryColor, SecondaryColor, OpenSecondaryColorInputBox );

	SecondaryColorRListItem = CreateMechListItem();
	SecondaryColorRListItem.UpdateDataSliderWithColorBlocks("0xFF0000", "" $ Round(SecondaryColor.R * 255), SecondaryColor.R * 100,, UpdateRedSecSlider);
	SecondaryColorRListItem.Slider.SetPercent(SecondaryColor.R * 100);

	SecondaryColorGListItem = CreateMechListItem();
	SecondaryColorGListItem.UpdateDataSliderWithColorBlocks("0x00FF00", "" $ Round(SecondaryColor.G * 255), SecondaryColor.G * 100,, UpdateGreenSecSlider);
	SecondaryColorGListItem.Slider.SetPercent(SecondaryColor.G * 100);

	SecondaryColorBListItem = CreateMechListItem();
	SecondaryColorBListItem.UpdateDataSliderWithColorBlocks("0x0000FF", "" $ Round(SecondaryColor.B * 255), SecondaryColor.B * 100,, UpdateBlueSecSlider);
	SecondaryColorBListItem.Slider.SetPercent(SecondaryColor.B * 100);

	TertiaryColorHeaderListItem = CreateMechListItem();
	TertiaryColorHeaderListItem.UpdateDataColorChipWithText(strTitle_TertiaryColor, TertiaryColor, OpenTertiaryColorInputBox );

	TertiaryColorRListItem = CreateMechListItem();
	TertiaryColorRListItem.UpdateDataSliderWithColorBlocks("0xFF0000", "" $ Round(TertiaryColor.R * 255), TertiaryColor.R * 100,, UpdateRedTerSlider);
	TertiaryColorRListItem.Slider.SetPercent(TertiaryColor.R * 100);

	TertiaryColorGListItem = CreateMechListItem();
	TertiaryColorGListItem.UpdateDataSliderWithColorBlocks("0x00FF00", "" $ Round(TertiaryColor.G * 255), TertiaryColor.G * 100,, UpdateGreenTerSlider);
	TertiaryColorGListItem.Slider.SetPercent(TertiaryColor.G * 100);

	TertiaryColorBListItem = CreateMechListItem();
	TertiaryColorBListItem.UpdateDataSliderWithColorBlocks("0x0000FF", "" $ Round(TertiaryColor.B * 255), TertiaryColor.B * 100,, UpdateBlueTerSlider);
	TertiaryColorBListItem.Slider.SetPercent(TertiaryColor.B * 100);

	if (bEnableTertiaryColor)
	{
		TertiaryColorHeaderListItem.Show();
		TertiaryColorRListItem.Show();
		TertiaryColorGListItem.Show();
		TertiaryColorBListItem.Show();
	}
	else
	{
		TertiaryColorHeaderListItem.Hide();
		TertiaryColorRListItem.Hide();
		TertiaryColorGListItem.Hide();
		TertiaryColorBListItem.Hide();
	}
}

function UIMechaListItem_ColorEditor CreateMechListItem()
{
	local UIMechaListItem_ColorEditor	ListItem;

	ListItem = Spawn(class'UIMechaListItem_ColorEditor', ColorList.ItemContainer );	
	ListItem.bAnimateOnInit = false;
	ListItem.InitListItem();
	ListItem.OnMouseEventDelegate = DetailItemMouseEvent;
	ListItem.bShouldPlayGenericUIAudioEvents = false;

	return ListItem;
}

public function UpdateRedPriSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	PrimaryColor.R = SliderControl.percent / 100;

	UpdateSliderUI(PrimaryColorRListItem, PrimaryColorHeaderListItem, PrimaryColor, Round(PrimaryColor.R * 255));

	if (OnPrimaryColorChanged != none)
		OnPrimaryColorChanged(PrimaryColor);
}

public function UpdateGreenPriSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	PrimaryColor.G = SliderControl.percent / 100;

	UpdateSliderUI(PrimaryColorGListItem, PrimaryColorHeaderListItem, PrimaryColor, Round(PrimaryColor.G * 255));

	if (OnPrimaryColorChanged != none)
		OnPrimaryColorChanged(PrimaryColor);
}

public function UpdateBluePriSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	PrimaryColor.B = SliderControl.percent / 100;

	UpdateSliderUI(PrimaryColorBListItem, PrimaryColorHeaderListItem, PrimaryColor, Round(PrimaryColor.B * 255));

	if (OnPrimaryColorChanged != none)
		OnPrimaryColorChanged(PrimaryColor);
}


public function UpdateRedSecSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	SecondaryColor.R = SliderControl.percent / 100;

	UpdateSliderUI(SecondaryColorRListItem, SecondaryColorHeaderListItem, SecondaryColor, Round(SecondaryColor.R * 255));

	if (OnSecondaryColorChanged != none)
		OnSecondaryColorChanged(SecondaryColor);
}

public function UpdateGreenSecSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	SecondaryColor.G = SliderControl.percent / 100;

	UpdateSliderUI(SecondaryColorGListItem, SecondaryColorHeaderListItem, SecondaryColor, Round(SecondaryColor.G * 255));

	if (OnSecondaryColorChanged != none)
		OnSecondaryColorChanged(SecondaryColor);
}

public function UpdateBlueSecSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	SecondaryColor.B = SliderControl.percent / 100;
	
	UpdateSliderUI(SecondaryColorBListItem, SecondaryColorHeaderListItem, SecondaryColor, Round(SecondaryColor.B * 255));

	if (OnSecondaryColorChanged != none)
		OnSecondaryColorChanged(SecondaryColor);
}


public function UpdateRedTerSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	TertiaryColor.R = SliderControl.percent / 100;

	UpdateSliderUI(TertiaryColorRListItem, TertiaryColorHeaderListItem, TertiaryColor, Round(TertiaryColor.R * 255));

	if (OnTertiaryColorChanged != none)
		OnTertiaryColorChanged(TertiaryColor);
}

public function UpdateGreenTerSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	TertiaryColor.G = SliderControl.percent / 100;

	UpdateSliderUI(TertiaryColorGListItem, TertiaryColorHeaderListItem, TertiaryColor, Round(TertiaryColor.G * 255));

	if (OnTertiaryColorChanged != none)
		OnTertiaryColorChanged(TertiaryColor);
}

public function UpdateBlueTerSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	TertiaryColor.B = SliderControl.percent / 100;
	
	UpdateSliderUI(TertiaryColorBListItem, TertiaryColorHeaderListItem, TertiaryColor, Round(TertiaryColor.B * 255));

	if (OnTertiaryColorChanged != none)
		OnTertiaryColorChanged(TertiaryColor);
}

function UpdateSliderUI(UIMechaListItem_ColorEditor Item, UIMechaListItem_ColorEditor Header, LinearColor NewColor, int Value)
{
	`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");

	Header.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(NewColor));
	Header.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(NewColor));
	Item.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Value, class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
}

//
// Updates the color and all the elements associated with said color
function UpdatePrimaryColor(LinearColor newColor)
{
	PrimaryColor = newColor;
	PrimaryColorHeaderListItem.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(PrimaryColor));
	PrimaryColorHeaderListItem.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(PrimaryColor));
	
	PrimaryColorRListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(PrimaryColor.R * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	PrimaryColorRListItem.Slider.SetPercent(PrimaryColor.R * 100);
	
	PrimaryColorGListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(PrimaryColor.G * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	PrimaryColorRListItem.Slider.SetPercent(PrimaryColor.G * 100);
	
	PrimaryColorBListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(PrimaryColor.B * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	PrimaryColorRListItem.Slider.SetPercent(PrimaryColor.B * 100);

	if (OnPrimaryColorChanged != none)
		OnPrimaryColorChanged(PrimaryColor);
}

function UpdateSecondaryColor(LinearColor newColor)
{
	SecondaryColor = newColor;
	SecondaryColorHeaderListItem.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(SecondaryColor));
	SecondaryColorHeaderListItem.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(SecondaryColor));
	
	SecondaryColorRListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(SecondaryColor.R * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	SecondaryColorRListItem.Slider.SetPercent(SecondaryColor.R * 100);
	
	SecondaryColorGListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(SecondaryColor.G * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	SecondaryColorRListItem.Slider.SetPercent(SecondaryColor.G * 100);

	SecondaryColorBListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(SecondaryColor.B * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	SecondaryColorRListItem.Slider.SetPercent(SecondaryColor.B * 100);

	if (OnSecondaryColorChanged != none)
		OnSecondaryColorChanged(SecondaryColor);
}

function UpdateTertiaryColor(LinearColor newColor)
{
	TertiaryColor = newColor;
	TertiaryColorHeaderListItem.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(TertiaryColor));
	TertiaryColorHeaderListItem.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(TertiaryColor));
	
	TertiaryColorRListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(TertiaryColor.R * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	TertiaryColorRListItem.Slider.SetPercent(TertiaryColor.R * 100);
	
	TertiaryColorGListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(TertiaryColor.G * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	TertiaryColorRListItem.Slider.SetPercent(TertiaryColor.G * 100);

	TertiaryColorBListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(TertiaryColor.B * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	TertiaryColorRListItem.Slider.SetPercent(TertiaryColor.B * 100);

	if (OnTertiaryColorChanged != none)
		OnTertiaryColorChanged(TertiaryColor);
}

// Text input for Primary/Secondary Colors
//
function OpenPrimaryColorInputBox()
{
	local string NewColor;

	NewColor = Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(PrimaryColor), "0x00", "");

	class'UIMechaListItem_ColorEditor'.static.OpenInputBox(NewColor, strTitle_TextBox_PrimaryColor, OnPrimaryColorBoxClosed, VirtualKeyboard_OnPrimaryColorInputBoxAccepted);
}

function OpenSecondaryColorInputBox()
{
	local string NewColor;

	NewColor = Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(SecondaryColor), "0x00", "");

	class'UIMechaListItem_ColorEditor'.static.OpenInputBox(NewColor, strTitle_TextBox_SecondaryColor, OnSecondaryColorBoxClosed, VirtualKeyboard_OnSecondaryColorInputBoxAccepted);
}

function OpenTertiaryColorInputBox()
{
	local string NewColor;

	NewColor = Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(TertiaryColor), "0x00", "");

	class'UIMechaListItem_ColorEditor'.static.OpenInputBox(NewColor, strTitle_TextBox_TertiaryColor, OnTertiaryColorBoxClosed, VirtualKeyboard_OnTertiaryColorInputBoxAccepted);
}


function OnPrimaryColorBoxClosed(string text)
{
	if (text != "" && Len(text) == 6)
	{
		UpdatePrimaryColor(class'GunsmithDataStructures'.static.HexStringToLinearColor(text));
	}
}

function VirtualKeyboard_OnPrimaryColorInputBoxAccepted(string text, bool bWasSuccessful)
{
	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		OnPrimaryColorBoxClosed(text);
	}
}

function OnSecondaryColorBoxClosed(string text)
{
	if (text != "" && Len(text) == 6)
	{
		UpdateSecondaryColor(class'GunsmithDataStructures'.static.HexStringToLinearColor(text));
	}
}

function VirtualKeyboard_OnSecondaryColorInputBoxAccepted(string text, bool bWasSuccessful)
{
	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		OnSecondaryColorBoxClosed(text);
	}
}

function OnTertiaryColorBoxClosed(string text)
{
	if (text != "" && Len(text) == 6)
	{
		UpdateTertiaryColor(class'GunsmithDataStructures'.static.HexStringToLinearColor(text));
	}
}

function VirtualKeyboard_OnTertiaryColorInputBoxAccepted(string text, bool bWasSuccessful)
{
	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		OnTertiaryColorBoxClosed(text);
	}
}


function DetailItemMouseEvent(UIPanel Panel, int Cmd)
{
	local UIMechaListItem MechaListItem;

	if (Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
	{
		// Cancel possible PlayMouseOverSound timer from another detail item's mouse out event
		SetTimer(0.0f, false, 'PlayMouseOverSound');
	}
	else if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT)
	{
		MechaListItem = UIMechaListItem(Panel);
		if(MechaListItem != none && !MechaListItem.bDisabled)
		{
			switch (MechaListItem.Type)
			{
			case EUILineItemType_Spinner:
			case EUILineItemType_Dropdown:
			case EUILineItemType_Slider:
				// Spinners, dropdwons, and sliders don't send mouseover events from Flash,
				// so have the detail item play a sound on mouse out but give time for the mouse guard or other detail items to cancel
				SetTimer(0.05f, false, 'PlayMouseOverSound');
				break;
			default:
				break;
			}
		}
	}
}

function PlayMouseOverSound()
{
	`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
}