class UIPanel_WeaponCustomization_Options extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		OptionsListContainer;
var UIList		OptionsListRow1;
var UIList		OptionsListRow2;

var UIX2PanelHeader TitleHeader;

var float	USize;
var float	VSize;
var int		TexRot;

var bool	bSwapTintMasks;
var bool	bMergeTintMasks;

var delegate<GunsmithDataStructures.delFloatValue>	OnTexUSizeChanged;
var delegate<GunsmithDataStructures.delFloatValue>	OnTexVSizeChanged;
var delegate<GunsmithDataStructures.delIntValue>	OnTexRotSizeChanged;
var delegate<GunsmithDataStructures.delBoolValue>	OnSwapMasksChecked;
var delegate<GunsmithDataStructures.delBoolValue>	OnMergeMasksChecked;
var delegate<GunsmithDataStructures.delOnClicked>	OnApplyAllButtonPressed;

var UIMechaListItem_ColorEditor SwapTintMaskItem;
var UIMechaListItem_ColorEditor MergeTintMaskItem;

var UIMechaListItem_ColorEditor UTextureCoordItem;
var UIMechaListItem_ColorEditor VTextureCoordItem;
var UIMechaListItem_ColorEditor RotTextureCoordItem;

var localized string strHeader;
var localized string strOption_SwapMasks;
var localized string strButton_ApplyToAll;
var localized string strOption_ApplyToAll;
var localized string strOption_MergeTints;
var localized string strOption_TexCoord_U;
var localized string strOption_TexCoord_V;
var localized string strOption_TexCoord_Rotation;

var localized string strTooltip_SwapMasks;
var localized string strTooltip_ApplyToAll;
var localized string strTooltip_MergeTints;

function UIPanel_WeaponCustomization_Options InitOptionsPanel(name InitName)
{
	InitPanel(InitName);

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	BGFrame = Spawn(class'UIBGBox', self);
	BGFrame.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	BGFrame.InitBG('theBG');
	BGFrame.SetAlpha(80);
	BGFrame.SetSize(700, 170);
//	BGFrame.SetOutline(true);

	OptionsListContainer = Spawn(class'UIPanel', self);
	OptionsListContainer.bAnimateOnInit = false;
	
	OptionsListRow1 = Spawn(class'UIList', self);
	OptionsListRow1.InitList('OptionsList1MC');
	OptionsListRow1.SetSize(330, 150);
	OptionsListRow1.SetPosition(5, 50);
	OptionsListRow1.bStickyHighlight	= false;
	OptionsListRow1.bAutosizeItems		= false;
	OptionsListRow1.bAnimateOnInit		= false;
	OptionsListRow1.bSelectFirstAvailable = false;
	OptionsListRow1.ItemPadding = 0;
	OptionsListRow1.Navigator.LoopSelection = false;	
//	//INS: - JTA 2016/3/2
//	OptionsListRow1.bLoopSelection = false;
//	OptionsListRow1.Navigator.LoopOnReceiveFocus = true;
//	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
//	OptionsListRow1.bCascadeFocus = true;
//	OptionsListRow1.bPermitNavigatorToDefocus = true;
//
	OptionsListRow2 = Spawn(class'UIList', self);
	OptionsListRow2.InitList('OptionsList2MC');
	OptionsListRow2.SetSize(330, 150);
	OptionsListRow2.SetPosition(355, 50);
	OptionsListRow2.bStickyHighlight	= false;
	OptionsListRow2.bAutosizeItems		= false;
	OptionsListRow2.bAnimateOnInit		= false;
	OptionsListRow2.bSelectFirstAvailable = false;
	OptionsListRow2.ItemPadding = 0;
	OptionsListRow2.Navigator.LoopSelection = false;	
//	//INS: - JTA 2016/3/2
//	OptionsListRow2.bLoopSelection = false;
//	OptionsListRow2.Navigator.LoopOnReceiveFocus = true;
//	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
//	OptionsListRow2.bCascadeFocus = true;
//	OptionsListRow2.bPermitNavigatorToDefocus = true;

	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('', strHeader, "");
	TitleHeader.SetPosition(5, 1);
	TitleHeader.SetHeaderWidth(BGFrame.Width);

	BuildMenuList();
}

function BuildMenuList()
{
	local UIMechaListItem_ColorEditor	ListItem;

	ListItem = CreateMechListItem(0);
	ListItem.UpdateDataButtonSmall(strOption_ApplyToAll, strButton_ApplyToAll, OnButtonClicked_ApplyToAll);
	ListItem.BG.SetTooltipText(strTooltip_ApplyToAll);

	SwapTintMaskItem = CreateMechListItem(0);
	SwapTintMaskItem.UpdateDataCheckbox(strOption_SwapMasks	, "", bSwapTintMasks, OnSwapTintMaskChecked);
	MergeTintMaskItem.BG.SetTooltipText(strTooltip_SwapMasks);

	MergeTintMaskItem = CreateMechListItem(0);
	MergeTintMaskItem.UpdateDataCheckbox(strOption_MergeTints, "", bMergeTintMasks, OnMergeTintMaskChecked);
	MergeTintMaskItem.BG.SetTooltipText(strTooltip_MergeTints);

	UTextureCoordItem = CreateMechListItem(1);
	UTextureCoordItem.UpdateDataSliderTextFrontAndBack(strOption_TexCoord_U, "" $ USize , int((USize / 32) * 100),, OnSliderChanged_TexCoordU);
	UTextureCoordItem.Desc.SetWidth(20);
	UTextureCoordItem.Desc2.SetX(ListItem.Width - 70);

	VTextureCoordItem = CreateMechListItem(1);
	VTextureCoordItem.UpdateDataSliderTextFrontAndBack(strOption_TexCoord_V, "" $ VSize, int((VSize / 32) * 100),, OnSliderChanged_TexCoordV);
	VTextureCoordItem.Desc.SetWidth(20);
	VTextureCoordItem.Desc2.SetX(ListItem.Width - 70);
//	ListItem.Desc2.SetX(Width - 25);

	RotTextureCoordItem = CreateMechListItem(1);
	RotTextureCoordItem.UpdateDataSliderTextFrontAndBack(strOption_TexCoord_Rotation, "" $ TexRot , float(TexRot / 360) * 100,, OnSliderChanged_TexCoordRot);
	RotTextureCoordItem.Desc.SetWidth(45);
	RotTextureCoordItem.Desc2.SetX(ListItem.Width - 70);
//	ListItem.Desc2.SetX(Width - 25);
}

function UIMechaListItem_ColorEditor CreateMechListItem(int Row)
{
	local UIMechaListItem_ColorEditor	ListItem;

	if (Row == 0)
		ListItem = Spawn(class'UIMechaListItem_ColorEditor', OptionsListRow1.ItemContainer );	
	else
		ListItem = Spawn(class'UIMechaListItem_ColorEditor', OptionsListRow2.ItemContainer );
	
	ListItem.bAnimateOnInit = false;
	ListItem.InitListItem();
//	ListItem.OnMouseEventDelegate = DetailItemMouseEvent;
	ListItem.bShouldPlayGenericUIAudioEvents = false;

	return ListItem;
}

function UpdateBooleans(bool bSwapMasksChecked, bool bMergeMasksChecked)
{
	SwapTintMaskItem.Checkbox.SetChecked(bSwapMasksChecked, false);
	MergeTintMaskItem.Checkbox.SetChecked(bMergeMasksChecked, false);
}

function UpdateUSize(float newUSize)
{
	USize = newUSize;

	UTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(USize), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	UTextureCoordItem.Slider.SetPercent(int((USize / 32) * 100));
}

function UpdateVSize(float newVSize)
{
	VSize = newVSize;

	VTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(VSize), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	VTextureCoordItem.Slider.SetPercent(int((VSize / 32) * 100));
}

function UpdateRotAngle(int newRot)
{
	TexRot = newRot;

	RotTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ TexRot, class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));
	RotTextureCoordItem.Slider.SetPercent(float((TexRot / 360) * 100));
}

// Execute function that sets same tinting on every other part
function OnButtonClicked_ApplyToAll(UIButton ButtonSource)
{
	if (OnApplyAllButtonPressed != none)
		OnApplyAllButtonPressed();
}

function OnSwapTintMaskChecked(UICheckbox checkboxControl)
{
	bSwapTintMasks = CheckboxControl.bChecked;

	`LOG("[" $ GetFuncName() $ "] Swap Tint " $ bSwapTintMasks,, 'WotC_Gameplay_Misc_WeaponGunsmith');


	if (OnSwapMasksChecked != none)
	{
		`LOG("[" $ GetFuncName() $ "] Executing Delegate",, 'WotC_Gameplay_Misc_WeaponGunsmith');
		OnSwapMasksChecked(bSwapTintMasks);
	}
}

function OnMergeTintMaskChecked(UICheckbox checkboxControl)
{
	bMergeTintMasks = CheckboxControl.bChecked;

	if (OnMergeMasksChecked != none)
		OnMergeMasksChecked(bMergeTintMasks);
}

function OnSliderChanged_TexCoordU(UISlider SliderControl)
{
	if (SliderControl.Percent < 5)
		SliderControl.Percent = 1;

	USize = Round(FClamp(SliderControl.Percent * 0.32f, 0.5, 32.0f));

	UTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(USize), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));

	if (OnTexUSizeChanged != none)
		OnTexUSizeChanged(USize);
}

function OnSliderChanged_TexCoordV(UISlider SliderControl)
{
	if (SliderControl.Percent < 5)
		SliderControl.Percent = 1;

	VSize = Round(FClamp(SliderControl.Percent * 0.32f, 0.5, 32.0f));

	VTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ int(VSize), class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));

	if (OnTexVSizeChanged != none)
		OnTexVSizeChanged(VSize);
}

function OnSliderChanged_TexCoordRot(UISlider SliderControl)
{
	if (SliderControl.Percent < 5)
		SliderControl.Percent = 0;

	TexRot = Clamp(SliderControl.Percent * 0.36f, 0, 36) * 10;

	RotTextureCoordItem.Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("" $ TexRot, class'UIMechaListItem_ColorEditor'.const.COLORFONTSIZE));

	if (OnTexRotSizeChanged != none)
		OnTexRotSizeChanged(TexRot);
}

defaultproperties
{
	USize = 2.0f
	VSize = 2.0f
	TexRot = 0
}