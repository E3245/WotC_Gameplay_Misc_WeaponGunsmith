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

/*
struct AdditionalAnimSetsByUnit
{
	var name UnitTemplateName;
	var bool bFemale;			// Only 
	var string AnimSet;
}
*/