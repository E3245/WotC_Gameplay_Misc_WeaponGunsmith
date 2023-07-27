class UIPanel_WeaponCustomization_Share extends UIPanel;

var UIBGBox		BGFrame;
var UIPanel		ShareListContainer;
var UIButton	ShareButton;
var UIButton	ImportButton;

var delegate<GunsmithDataStructures.delOnClicked>	OnShareButtonPressed;
var delegate<GunsmithDataStructures.delOnClicked>	OnImportButtonPressed;

var localized string ShareButtonLabel;
var localized string ImportButtonLabel;

var localized string strCustomizationShare_Success_DialogueTitle;
var localized string strCustomizationShare_Success_DialogueText;

var localized string strCustomizationImport_Success_DialogueTitle;
var localized string strCustomizationImport_Success_DialogueText;

var int CachedTooltipId_Share;

function UIPanel_WeaponCustomization_Share InitSharePanel(name InitName)
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
	BGFrame.SetSize(390, 40);
//	BGFrame.SetOutline(true);
	
	ShareButton		= Spawn(class'UIButton', self).InitButton('ShareButtonMC', ShareButtonLabel, OnClickShare);
	ShareButton.bAnimateOnInit = false;
	ShareButton.SetPosition(3, 5);

	ImportButton	= Spawn(class'UIButton', self).InitButton('ImportButtonMC', ImportButtonLabel, OnClickImport);
	ImportButton.bAnimateOnInit = false;
	ImportButton.SetPosition(180, 5);
}

function OnClickShare(UIButton Button)
{
	local UITextTooltip Tooltip;

	if (OnShareButtonPressed != none)
		OnShareButtonPressed();

	ShareButton.SetToolTipText("Copied to Clipboard!", , 0, 0, , class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT, , 0.0f);
	
	//Tooltip = UITextTooltip(Movie.Pres.m_kTooltipMgr.GetTooltipByID(ShareButton.CachedTooltipId));

	//if (Tooltip != none)
	//{
	//	Tooltip.SetDelay(0.0);
	//	Tooltip.SetFollowMouse(false);
	//	Movie.Pres.m_kTooltipMgr.ActivateTooltip(Tooltip);
	//}

	ShareSuccessDialogue();

//	SetTimer(6.0f, false, nameof(RemoveTooltip));
}

function OnClickImport(UIButton Button)
{
	if (OnImportButtonPressed != none)
		OnImportButtonPressed();

	ShareButton.SetToolTipText("Import Successful!",,,,,,,0.0f);

//	SetTimer(6.0f, false, nameof(RemoveTooltip));
}

simulated function ShareSuccessDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Normal;

	kDialogData.strTitle = strCustomizationShare_Success_DialogueTitle;
	kDialogData.strText = strCustomizationShare_Success_DialogueText;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

static function ImportSuccessDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Normal;

	kDialogData.strTitle = default.strCustomizationImport_Success_DialogueTitle;
	kDialogData.strText = default.strCustomizationImport_Success_DialogueText;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

//function RemoveTooltip()
//{
//	ShareButton.RemoveTooltip();
//	ImportButton.RemoveTooltip();
//}