class GunsmithDataStructures extends Object;

// Parts that a weapon is comprised of.
// Certain Parts are hardcoded to have certain sockets. This is absolute.
enum WeaponPartType
{
	PT_NONE,		// Error Checking
	PT_RECEIVER,
	PT_BARREL,		// Has left_hand. Hardcoded.
	PT_HANDGUARD,
	PT_STOCK,
	PT_MAGAZINE,
	PT_REARGRIP,
	PT_MUZZLE,		// Has gun_fire. Hardcoded.
	PT_UNDERBARREL,	// Has left_hand. Hardcoded.
	PT_LASER,
	PT_OPTIC,
	PT_SPECIAL_1,	// Usually Bolts, Stock/Saddle Combos, etc.
	PT_SPECIAL_2,
	PT_MAX
};

struct WeaponPartAttachment {
	var() string	Type;
	var() string	Tier;
	var() name		AttachSocket;
	var() name		UIArmoryCameraPointTag;
	var() string	AttachMeshName;
	var() string	ProjectileName;
	var() name		MatchWeaponTemplate;
	var() bool		AttachToPawn;
	var() string	IconName;
	var() string	InventoryIconName;
	var() string	InventoryCategoryIcon;
	var() name		AttachmentFn;
	var Object		LoadedObject;
	var() string	AnimSetPath;		// Path to the AnimSet linked for this attachment
};

struct WeaponCustomizationData
{
	var name		CamoTemplateName;
	var int			iPrimaryTintPaletteIdx;
	var int			iSecondaryTintPaletteIdx;
	var LinearColor	PrimaryTintColor;
	var LinearColor	SecondaryTintColor;
	var LinearColor TertiaryTintColor;
	var LinearColor EmissiveColor;
	var float		fEmissivePower;
	var bool		bSwapMasks;
	var bool		bMergeMasks;
	var float		fTexUSize;
	var float		fTexVSize;
	var int			iTexRot;

	structdefaultproperties
	{
		iPrimaryTintPaletteIdx		= -1;
		iSecondaryTintPaletteIdx	= -1;
		fTexUSize					= 2.0f;
		fTexVSize					= 2.0f;
		iTexRot						= 0;
		PrimaryTintColor			= (R=1, G=0, B=0, A=1);
		SecondaryTintColor			= (R=0, G=1, B=0, A=1);
		TertiaryTintColor			= (R=0, G=0, B=1, A=1);
		EmissiveColor				= (R=1, G=1, B=1, A=0);
		fEmissivePower				= 1.0f;
	}
};

//V1.005: Alternate sockets for main components
struct AltReceiverSockets
{
	var name SocketName;
	var name ReceiverName;
};

// Handle Customization import error strings
var localized string strCustomizationImport_Fail_BadDecode_DialogueTitle;
var localized string strCustomizationImport_Fail_BadDecode_DialogueText;			

var localized string strCustomizationImport_Fail_EmptyWeapon_DialogueTitle;
var localized string strCustomizationImport_Fail_EmptyWeapon_DialogueText;

var localized string strCustomizationImport_Fail_EmptyReceiver_DialogueTitle;
var localized string strCustomizationImport_Fail_EmptyReceiver_DialogueText;

var localized string strCustomizationImport_Fail_InvalidReceiver_DialogueTitle;
var localized string strCustomizationImport_Fail_InvalidReceiver_DialogueText;

/*
struct AdditionalAnimSetsByUnit
{
	var name UnitTemplateName;
	var bool bFemale;			// Only 
	var string AnimSet;
}
*/
delegate delFloatValue(float newFloat);
delegate delIntValue(int newInt);
delegate delOnClicked();
delegate delNameValue(name newName);
delegate delBoolValue(bool bToggle);
delegate delColorValue(LinearColor newColor);

//
// CONVERSION FUNCTIONS
static function Color		HexStringToByteColor(string Hex)
{
	local int iColor, R, G, B;
	// String to Int does not support hex, so attempt to convert each value into bytes
	iColor = HexFromStringConversion(Hex);

	// Only the first 6 bytes are considered
	R = (iColor & 0xFF0000) >> 16;
	G = (iColor & 0x00FF00) >> 8;
	B = (iColor & 0x0000FF);

	return MakeColor(R, G, B, 255);
}

static function LinearColor HexStringToLinearColor(string Hex)
{
	local int iColor, R, G, B;
	// String to Int does not support hex, so attempt to convert each value into bytes
	iColor = HexFromStringConversion(Hex);
	
	// Only the first 6 bytes are considered
	R = (iColor & 0xFF0000) >> 16;
	G = (iColor & 0x00FF00) >> 8;
	B = (iColor & 0x0000FF);
	
	// Turn integers into Linear Color by normalizing the resultants
	return MakeLinearColor( R / 255.0f, G / 255.0f, B / 255.0f, 1.0f);
}

static function int HexFromStringConversion(string toHex)
{
	local int iColor, i, Character;
	local string Text;

	iColor = 0;
	Text = toHex;

	while (Len(Text) > 0)
	{
		i = Len(Text) - 1;
		// Pull the first character
		Character = Asc(Left(Text, 1));

		// Consume letter
		Text = Mid(Text, 1);

		switch(Character)
		{
			// A
			case 0x41:
			// a
			case 0x61:
				iColor += 10 << 4 * i;
				break;
			// B
			case 0x42:
			// b
			case 0x62:
				iColor += 11 << 4 * i;
				break;
			// C
			case 0x43:
			// c
			case 0x63:
				iColor += 12 << 4 * i;
				break;
			// D
			case 0x44:
			// d
			case 0x64:
				iColor += 13 << 4 * i;
				break;
			// E
			case 0x45:
			// e
			case 0x65:
				iColor += 14 << 4 * i;
				break;
			// F
			case 0x46:
			// f
			case 0x66:
				iColor += 15 << 4 * i;
				break;
			default:
				iColor += int(Chr(Character)) << 4 * i;
				break;
		}
	}

	//`LOG("Got: " $ iColor $ ", from Hex Value: " $ toHex,,'EyeTest');

	return iColor;
}

static function LinearColor InvertLinearColor(LinearColor RGB)
{
	local LinearColor IC;

	IC.R = FClamp(1.0f - RGB.R, 0.0f, 1.0f);
	IC.G = FClamp(1.0f - RGB.G, 0.0f, 1.0f);
	IC.B = FClamp(1.0f - RGB.B, 0.0f, 1.0f);

	return IC;
}