class UIMechaListItem_ColorEditor extends UIMechaListItem;

const	COLORFONTSIZE = 24;

var UIText Desc2;

simulated function UpdateDataSliderWithColorBlocks(string _HTMLColorChip,
									 String _SliderLabel,
									 optional int _SliderPosition,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none,
									 optional delegate<OnSliderChangedCallback> _OnSliderChangedDelegate = none)
{
	SetWidgetType(EUILineItemType_Slider);

	if( ColorChip == none )
	{
		ColorChip = Spawn(class'UIBGBox', self);
		ColorChip.bAnimateOnInit = false;
		ColorChip.bIsNavigable = false;
		ColorChip.InitBG('ColorChipMC');
		ColorChip.SetSize(20, 20);
		ColorChip.SetPosition(5, 7);
		ColorChip.SetColor(_HTMLColorChip);
		ColorChip.Show();
	}

	if( Slider == none )
	{
		Slider = Spawn(class'UISlider', self);
		Slider.bIsNavigable = false;
		Slider.bAnimateOnInit = false;
		Slider.InitSlider('SliderMC');
		Slider.Navigator.HorizontalNavigation = true;
		//Slider.SetPosition(width - 420, 0);
		Slider.SetX(width - 490);
	}

	if (_SliderLabel != "")
	{
		Desc.SetWidth(width);
		Desc.SetX(Width - 60);
		Desc.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(_SliderLabel, COLORFONTSIZE));
		Desc.Show();
	}

	OnClickDelegate = _OnClickDelegate;
	OnSliderChangedCallback = _OnSliderChangedDelegate;
	Slider.onChangedDelegate = _OnSliderChangedDelegate;
}

simulated function UpdateDataSliderTextFrontAndBack(string _Desc,
									 String _SliderLabel,
									 optional int _SliderPosition,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none,
									 optional delegate<OnSliderChangedCallback> _OnSliderChangedDelegate = none)
{
	SetWidgetType(EUILineItemType_Slider);

	if( Slider == none )
	{
		Slider = Spawn(class'UISlider', self);
		Slider.bIsNavigable = false;
		Slider.bAnimateOnInit = false;
		Slider.InitSlider('SliderMC');
		Slider.Navigator.HorizontalNavigation = true;
		//Slider.SetPosition(width - 420, 0);
		Slider.SetX(width - 490);
	}

	Slider.SetPercent(_SliderPosition);
	//Slider.SetText(_SliderLabel);
	Slider.Show();

	Desc.SetWidth(width - 350);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	if (Desc2 == none && _SliderLabel != "")
	{
		Desc2 = Spawn(class'UIText', self);
		Desc2.InitText('2ndTextBoxAMC');
		Desc2.bIsNavigable = false;
		Desc2.bAnimateOnInit = bAnimateOnInit;

		Desc2.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(_SliderLabel, COLORFONTSIZE));

		Desc2.SetX(width - 100);
		Desc2.SetY(Desc2.Y + 1);

		Desc2.Show();
	}

	OnClickDelegate = _OnClickDelegate;
	OnSliderChangedCallback = _OnSliderChangedDelegate;
	Slider.onChangedDelegate = _OnSliderChangedDelegate;
}

// Adds text over the Hexadecimal 
simulated function UIMechaListItem UpdateDataColorChipWithText(string _Desc,
										LinearColor _HTMLColorChip,
										optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_ColorChip);

	if( ColorChip == none )
	{
		ColorChip = Spawn(class'UIBGBox', self);
		ColorChip.bAnimateOnInit = false;
		ColorChip.bIsNavigable = false;
		ColorChip.InitBG('ColorChipMC');
		ColorChip.SetSize(165, 20);
		ColorChip.SetPosition(width - 170, 7);
		//ColorChip.SetX(width - 170);
	}

	ColorChip.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(_HTMLColorChip));
	ColorChip.Show();

	Desc.SetWidth(width - 170);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	if (Desc2 == none)
	{
		Desc2 = Spawn(class'UIText', self);
		Desc2.InitText('2ndTextBoxAMC');
		Desc2.bIsNavigable = false;
		Desc2.bAnimateOnInit = bAnimateOnInit;

		Desc2.SetHTMLText(UpdateAndInverseTextColor(_HTMLColorChip));
		//Desc2.SetHTMLText("Test");

		Desc2.SetX(width - 100);
		Desc2.SetY(Desc2.Y + 1);

		Desc2.Show();
	}

	OnClickDelegate = _OnClickDelegate;
	return self;
}

static function string UpdateAndInverseTextColor(LinearColor OldColor)
{
	local LinearColor	InvColor;
	local string		StrInvertedColor, StrStdColor, HTML;

	HTML = "<font size='" $ COLORFONTSIZE $ "' color='#";

	// Get inverse of the color chip colors
	InvColor = class'GunsmithDataStructures'.static.InvertLinearColor(OldColor);

	StrInvertedColor	= Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(InvColor), "0x00", "");
	StrStdColor			= Repl(class'UIUtilities_Colors'.static.LinearColorToFlashHex(OldColor), "0x00", "");

	return HTML $ StrInvertedColor $ "'> #" $ StrStdColor;
}

simulated function UIMechaListItem UpdateDataButtonSmall(string _Desc,
								 	 string _ButtonLabel,
								 	 delegate<OnButtonClickedCallback> _OnButtonClicked = none,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Button);

	if (Button == none)
	{
		Button = Spawn(class'UIButton', self);
		Button.bAnimateOnInit = false;
		Button.bIsNavigable = false;
		Button.InitButton('ButtonMC', "", OnButtonClickDelegate);
		Button.SetX(width - 175);
		Button.SetY(0);
		Button.SetHeight(34);
		Button.MC.SetNum("textY", 2);
		Button.OnSizeRealized = UpdateButtonX;
	}

	Button.SetText(_ButtonLabel);
	RefreshButtonVisibility();

	Desc.SetWidth(width - 150);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnButtonClickedCallback = _OnButtonClicked;
	return self;
}

simulated function UpdateButtonX()
{
	if (Button != none)
	{
		Button.SetX(width - Button.Width - 5);
	}
}

static function OpenInputBox(string InputBoxText, 
								string Title, 
								delegate<UIInputDialogue.TextInputAcceptedCallback> AcceptedFn,
								delegate<XComPresentationLayerBase.delActionAccept> VKOnAccept)
{
	local TInputDialogData kData;

	//bsg-jedwards (1.25.17): Added condition to enable virtual keyboard
	if(!`ISCONSOLE)
	{
		kData.strTitle = Title;
		kData.iMaxChars = 6;
		kData.strInputBoxText = InputBoxText;
		kData.fnCallback = AcceptedFn;

		`PRESBASE.UIInputDialog(kData);
	}
	else
	{
		`PRESBASE.UIKeyboard( Title, 
			InputBoxText, 
			VKOnAccept, 
			VirtualKeyboard_OnInputBoxCancelled,
			false, 
			6
		);
	}
	//bsg-jedwards (1.25.17): end
}

function VirtualKeyboard_OnInputBoxCancelled()
{
	// Empty, do nothing
}