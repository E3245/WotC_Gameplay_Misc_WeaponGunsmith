class X2ConfigWeaponPartTemplate extends X2ItemTemplate config (WeaponPart);

// Main Variables
var config WeaponPartType			ePartName;

var config WeaponPartAttachment			MainComponent;				// Primary component that will check for valid sockets. Only 1 main attachment point per part.
var config array<WeaponPartAttachment>	arrAttachments;				// Additional components that have no error checking.
var config name							RifleGripSocketName;		// If the weapon has an attachment that uses the rifle grip animations, use this socket name
																	// instead of the one set in MainComponent.

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

// TODO: Expand for different unit templates that's not just Soldiers/Reapers/Skirmishers/Templars
var config array<string>			AdditionalPawnAnimSets_Male;
var config array<string>			AdditionalPawnAnimSets_Female;

var config array<string>			AdditionalPawnAnimSets_RifleGrip_M; // Same as above but only if the weapon uses Rifle Grip animatons
var config array<string>			AdditionalPawnAnimSets_RifleGrip_F;

// Barrel only variables
var config bool						bBarrel_IgnoreValidParts;		// Barrels can ignore Muzzle attachments (Usually for Integrated Suppressors)
var config bool						bBarrel_IsShort;					// Swaps to Mini GL if barrel is a short barrel

// Barrel/Muzzle variables
var config bool						bIsSuppressor;					// Changes sound to suppressed version and swaps muzzle flash

// Stock/Reargrip variables
var config bool						bActivateRifleGrip;				// Activates Rifle Grip animations if this part is equipped. 

// Localized string must be last. Config values get ignored under localized strings
var localized array<string>			m_strReceiverFriendlyName;		// Receivers can change the default friendly name of a weapon template 

// V1.003: Certain receiver templates may change the name of categories. Must have WeaponPartType::PT_MAX Elements or it will not show up
var localized array<string>			m_strReceiverOverridePartCategoryName;

DefaultProperties
{
	ItemCat="weapon_part" // Make sure to not allow XCom to ever get these as valid items
}