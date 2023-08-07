class X2ConfigWeaponPartTemplate extends X2ItemTemplate config (WeaponPart);

// Main Variables
var config WeaponPartType			ePartName;

var config WeaponPartAttachment			MainComponent;				// Primary component that will check for valid sockets. Only 1 main attachment point per part.
var config array<WeaponPartAttachment>	arrAttachments;				// Additional components that have no error checking.
var config name							RifleGripSocketName;		// If the weapon has an attachment that uses the rifle grip animations, use this socket name
																	// instead of the one set in MainComponent.

var config array<AltReceiverSockets>	AltSocketWithReceiver;		// V1.005: Alternate sockets if a particular receiver is equipped. 
																	// Used on every other class but receivers

var config bool						bDisableGunsmith;				// Will lock players from swapping parts but can still access the Apperance customization menu.
var config bool						bDisableCustomization;			// Will lock players out from customizing the weapon.

// Receiver only variables
var config array<name>				arrWeaponTemplateWhitelist; // List of weapons this upgrade can apply to. Whitelists override Blacklists.
var config array<name>				arrWeaponTemplateBlacklist;	// List of weapons this upgrade cannot apply to.

var config array<name>				ValidParts_Barrel;
var config array<name>				ValidParts_Handguard;
var config array<name>				ValidParts_Stock;
var config array<name>				ValidParts_Magazine;
var config array<name>				ValidParts_Reargrip;

var config array<name>				ValidParts_Muzzle;
var config array<name>				ValidParts_Optics;
var config array<name>				ValidParts_Laser;
var config array<name>				ValidParts_Underbarrel;

var config array<int>				UnlockedCategories;				// Array of PT_MAX elements that indicate if the receiver enables customization on this slot

var config float					ShotInterval;
var config int						NumShots;
var config string					DefaultFiringSoundCue;			// Default firing sound effect.
var config string					SuppressedFiringSoundCue;		// If a muzzle with bIsSuppressor is installed, change the sound to this instead
var config name						Pawn_WeaponFireAnimSequenceName;	// Name of the AnimSequence to play instead of the default one in the archetype. Only overriden on Tactical start.
var config name						Pawn_WeaponSuppressionFireAnimSequenceName; // Same as above, but for weapon suppression.


var config bool						bReplacePawnAnimSets;			// V1.005: Clear previously set animations

var config string					OverrideProjectileTemplate;		// V1.006: If overridden, weapon will use this projectile archetype instead of the base one when visualized

// TODO: Expand for different unit templates that's not just Soldiers/Reapers/Skirmishers/Templars
var config array<string>			AdditionalPawnAnimSets_Male;
var config array<string>			AdditionalPawnAnimSets_Female;

var config array<string>			AdditionalPawnAnimSets_RifleGrip_M; // Same as above but only if the weapon uses Rifle Grip animatons
var config array<string>			AdditionalPawnAnimSets_RifleGrip_F;

// Barrel only variables
var config bool						bBarrel_IgnoreValidParts;		// Barrels can ignore Muzzle attachments (Usually for Integrated Suppressors)
var config bool						bBarrel_IsShort;				// Swaps to Mini GL if barrel is a short barrel
var config bool						bBarrel_PreventUBWeap;			// V1.005: Prevents UB weapons from being equipped (for Short short barrels)
var config bool						bBarrel_PreventUBGrips;			// V1.005: Same as above, but for grips.
var config bool						bBarrel_DisableLaserCap;		// V1.005: This barrel will disable the laser cap when a laser is equipped

// Barrel/Muzzle variables
var config bool						bIsSuppressor;					// Changes sound to suppressed version and swaps muzzle flash

// Stock/Reargrip variables
var config bool						bActivateRifleGrip;				// Activates Rifle Grip animations if this part is equipped. 
var config bool						bStock_Modular;					// Has modular stock that can attach to most weapons

// V1.005: Optic variables
var config bool						bOptics_WithMount;				// Optic comes with its own mount (PSG-1 Scopes, etc.)

// V1.005: Underbarrel variables
var config bool						bUnderbarrel_IsWeap;
var config bool						bUnderbarrel_IsGrip;
var config bool						bUnderbarrel_IsBipod;

// V1.005: Customization Options
var config bool						bCustomization_Emissive;		// Has Emissives
var config bool						bCustomization_TertiaryColor;	// Has Tertiary Color
var config bool						bCustomization_Disable;			// No customization on this weapon

// Localized string must be last. Config values get ignored under localized strings
var localized array<string>			m_strReceiverFriendlyName;		// Receivers can change the default friendly name of a weapon template 

// V1.003: Certain receiver templates may change the name of categories. Must have WeaponPartType::PT_MAX Elements or it will not show up
var localized array<string>			m_strReceiverOverridePartCategoryName;

DefaultProperties
{
	ItemCat="weapon_part" // Make sure to not allow XCom to ever get these as valid items
}