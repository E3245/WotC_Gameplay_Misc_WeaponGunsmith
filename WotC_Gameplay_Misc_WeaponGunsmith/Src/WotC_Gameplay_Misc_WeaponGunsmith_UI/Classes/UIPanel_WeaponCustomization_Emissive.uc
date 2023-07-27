class UIPanel_WeaponCustomization_Emissive extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		ColorListContainer;
var UIList		ColorList;

var UIX2PanelHeader TitleHeader;

var LinearColor EmissiveColor;

var float EmissivePower;

var delegate<GunsmithDataStructures.delColorValue> OnEmissiveColorChanged;
var delegate<GunsmithDataStructures.delFloatValue> OnEmissivePowerChanged;

var UIMechaListItem_ColorEditor	EmissiveColorHeaderListItem;
var UIMechaListItem_ColorEditor	EmissiveColorRListItem;
var UIMechaListItem_ColorEditor	EmissiveColorGListItem;
var UIMechaListItem_ColorEditor	EmissiveColorBListItem;

var UIMechaListItem_ColorEditor	EmissivePowerListItem;

var localized string strTitle_EmissiveColor;

var localized string strHeader;
var localized string strTitle_TextBox_EmissiveColor;

function UIPanel_WeaponCustomization_Emissive InitEmissivePanel(name InitName)
{
	InitPanel(InitName);

	EmissiveColor = MakeLinearColor(1, 1, 1, 1);
	EmissivePower = 1.0f;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	BGFrame = Spawn(class'UIBGBox', self);
	BGFrame.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	BGFrame.InitBG('theBG');
	BGFrame.SetAlpha(80);
	BGFrame.SetSize(330, 250);
//	BGFrame.SetOutline(true);

	ColorListContainer = Spawn(class'UIPanel', self);
	ColorListContainer.bAnimateOnInit = false;
	
	ColorList = Spawn(class'UIList', self);
	ColorList.InitList('ColorListMC');
	ColorList.SetSize(320, 250);
	ColorList.SetPosition(5, 50);
	ColorList.bStickyHighlight = false;
	ColorList.bAutosizeItems = false;
	ColorList.bAnimateOnInit = false;
	ColorList.bSelectFirstAvailable = false;
	ColorList.ItemPadding = 0;
//	ColorList.OnSelectionChanged = PreviewUpgrade;
//	ColorList.OnItemClicked = OnItemClicked;
	ColorList.Navigator.LoopSelection = false;	
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

	BuildMenuList();
}


//
// Updates the color and all the elements associated with said color
function BuildMenuList()
{
	ColorList.ClearItems();

	EmissiveColorHeaderListItem = CreateMechListItem();
	EmissiveColorHeaderListItem.UpdateDataColorChipWithText(strTitle_EmissiveColor, EmissiveColor, OpenEmissiveColorInputBox );

	EmissiveColorRListItem = CreateMechListItem();
	EmissiveColorRListItem.UpdateDataSliderWithColorBlocks("0xFF0000", "" $ Round(EmissiveColor.R * 255), Round(EmissiveColor.R * 100),, UpdateRedEmsSlider);
	EmissiveColorRListItem.Slider.SetPercent(EmissiveColor.R * 100);

	EmissiveColorGListItem = CreateMechListItem();
	EmissiveColorGListItem.UpdateDataSliderWithColorBlocks("0x00FF00",  "" $ Round(EmissiveColor.G * 255), Round(EmissiveColor.G * 100),, UpdateGreenEmsSlider);
	EmissiveColorGListItem.Slider.SetPercent(EmissiveColor.G * 100);

	EmissiveColorBListItem = CreateMechListItem();
	EmissiveColorBListItem.UpdateDataSliderWithColorBlocks("0x0000FF",  "" $ Round(EmissiveColor.R * 255), Round(EmissiveColor.B * 100),, UpdateBlueEmsSlider);
	EmissiveColorBListItem.Slider.SetPercent(EmissiveColor.B * 100);

	EmissivePowerListItem = CreateMechListItem();
	EmissivePowerListItem.UpdateDataSliderWithColorBlocks("0xFFFFFF",  "" $ Round(EmissivePower), Round(EmissivePower / 25),, UpdatePowerEmsSider);
	EmissivePowerListItem.Slider.SetPercent(EmissivePower / 25);

	ColorList.Show();
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

public function UpdateRedEmsSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	EmissiveColor.R = SliderControl.percent / 100;

	UpdateSliderUI(EmissiveColorRListItem, EmissiveColorHeaderListItem, EmissiveColor, Round(EmissiveColor.R * 255));

	if (OnEmissiveColorChanged != none)
		OnEmissiveColorChanged(EmissiveColor);
}

public function UpdateGreenEmsSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	EmissiveColor.G = SliderControl.percent / 100;

	UpdateSliderUI(EmissiveColorGListItem, EmissiveColorHeaderListItem, EmissiveColor, Round(EmissiveColor.G * 255));

	if (OnEmissiveColorChanged != none)
		OnEmissiveColorChanged(EmissiveColor);
}

public function UpdateBlueEmsSlider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	EmissiveColor.B = SliderControl.percent / 100;

	UpdateSliderUI(EmissiveColorBListItem, EmissiveColorHeaderListItem, EmissiveColor, Round(EmissiveColor.B * 255));

	if (OnEmissiveColorChanged != none)
		OnEmissiveColorChanged(EmissiveColor);
}

public function  UpdatePowerEmsSider(UISlider SliderControl)
{
	if (SliderControl.percent < 5)
		SliderControl.percent = 0;

	EmissivePower = Round(Clamp(SliderControl.Percent * 0.25f, 0, 25));

	EmissivePowerListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(EmissivePower), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));

	if (OnEmissivePowerChanged != none)
		OnEmissivePowerChanged(EmissivePower);
}

function UpdateSliderUI(UIMechaListItem_ColorEditor Item, UIMechaListItem_ColorEditor Header, LinearColor NewColor, int Value)
{
	`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");

	Header.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(NewColor));
	Header.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(NewColor));
	Item.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Value, class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
}

function UpdateEmissiveColor(LinearColor newColor)
{
	EmissiveColor = newColor;
	EmissiveColorHeaderListItem.ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(EmissiveColor));
	EmissiveColorHeaderListItem.Desc2.SetHTMLText(class'UIMechaListItem_ColorEditor'.static.UpdateAndInverseTextColor(EmissiveColor));
	
	EmissiveColorRListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(EmissiveColor.R * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	EmissiveColorRListItem.Slider.SetPercent(EmissiveColor.R * 100);
	
	EmissiveColorGListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(EmissiveColor.G * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	EmissiveColorGListItem.Slider.SetPercent(EmissiveColor.G * 100);
	
	EmissiveColorBListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ Round(EmissiveColor.B * 255), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	EmissiveColorBListItem.Slider.SetPercent(EmissiveColor.B * 100);

	if (OnEmissiveColorChanged != none)
		OnEmissiveColorChanged(EmissiveColor);
}

function UpdateEmissivePower(float newPower)
{
	EmissivePower = newPower;

	EmissivePowerListItem.Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(EmissivePower), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	EmissivePowerListItem.Slider.SetPercent(EmissivePower / 25);

	if (OnEmissivePowerChanged != none)
		OnEmissivePowerChanged(EmissivePower);
}

function OpenEmissiveColorInputBox()
{
	local string NewColor;

	NewColor = Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(EmissiveColor), "0x00", "");

	class'UIMechaListItem_ColorEditor'.static.OpenInputBox(NewColor, strTitle_TextBox_EmissiveColor, OnEmissiveColorBoxClosed, VirtualKeyboard_OnEmissiveColorInputBoxAccepted);
}

function VirtualKeyboard_OnEmissiveColorInputBoxAccepted(string text, bool bWasSuccessful)
{
	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		OnEmissiveColorBoxClosed(text);
	}
}

function OnEmissiveColorBoxClosed(string text)
{
	if (text != "" && Len(text) == 6)
	{
		UpdateEmissiveColor(class'GunsmithDataStructures'.static.HexStringToLinearColor(text));
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