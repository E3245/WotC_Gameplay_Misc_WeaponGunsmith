//---------------------------------------------------------------------------------------
//  FILE:    XGWeapon.uc  
//  PURPOSE: Visualizer class for items / weapons in X2
//           
//           Adds psuedo part system seen in MW'19/22, where sockets in skeletal meshes 
//           of certain parts dictate where other parts go. 
//
//           (E.g different barrels has different locations for muzzle breaks)
//
//			 V1.005: SetApperance() implementation for separate parts
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGWeapon_Platform_AR extends XGWeapon;

var XCGS_WeaponGunsmith GunsmithStateDirty;	// For visualizing upgrades when previewing them in the armory

// Main templates for each weapon. Weapons will always consist of these parts.
var X2ConfigWeaponPartTemplate ReceiverTemplate;
var X2ConfigWeaponPartTemplate BarrelTemplate;
var X2ConfigWeaponPartTemplate HandguardTemplate;
var X2ConfigWeaponPartTemplate StockTemplate;
var X2ConfigWeaponPartTemplate MagazineTemplate;
var X2ConfigWeaponPartTemplate ReargripTemplate;
var X2ConfigWeaponPartTemplate UnderbarrelTemplate;
var X2ConfigWeaponPartTemplate OpticsTemplate;
var X2ConfigWeaponPartTemplate LaserTemplate;
var X2ConfigWeaponPartTemplate MuzzleTemplate;

var protected SkeletalMeshComponent ReceiverComponent;
var protected SkeletalMeshComponent BarrelComponent;
var protected SkeletalMeshComponent HandguardComponent;
var protected SkeletalMeshComponent StockComponent;
var protected SkeletalMeshComponent MagazineComponent;
var protected SkeletalMeshComponent ReargripComponent;
var protected SkeletalMeshComponent UnderbarrelComponent;
var protected SkeletalMeshComponent OpticComponent;
var protected SkeletalMeshComponent LaserComponent;
var protected SkeletalMeshComponent MuzzleComponent;

var SoundCue FireSound;

var bool	 bUseRifleGrip;

var array<WeaponCustomizationData>	arrWeaponCustomizationData;

var array<name>	ReceiverMaterialNames;
var array<name>	BarrelMaterialNames;
var array<name>	HandguardMaterialNames;
var array<name>	StockMaterialNames;
var array<name>	MagazineMaterialNames;
var array<name>	ReargripMaterialNames;
var array<name>	UnderbarrelMaterialNames;
var array<name>	OpticMaterialNames;
var array<name>	LaserMaterialNames;
var array<name>	MuzzleMaterialNames;

const CylinderLaserCapSocket = 'PT_LASER_CAP';

// Only used to preview upgrades since components aren't actually updated unlike base objects
// Do not use it for anything else
simulated static function XGItem CreatePreviewVisualizer(	XComGameState_Item ItemState, 
													bool bSetAsVisualizer=true, 
													optional XComUnitPawn UnitPawnOverride = None, 
													optional XCGS_WeaponGunsmith GunsmithOverride = None)
{
	local class<XGItem> ItemClass;
	local XGItem CreatedItem;
	local XGWeapon CreatedWeapon;
	local XComGameReplicationInfo GRI;

	GRI = `XCOMGRI;
	ItemClass = ItemState.GetMyTemplate().GetGameplayInstanceClass();

	if( ItemClass != none ) //Not every item has a visualizer - armor, for example, does not
	{
		CreatedItem = class'Engine'.static.GetCurrentWorldInfo().Spawn( ItemClass, GRI.m_kGameCore  );
		CreatedItem.ObjectID = ItemState.ObjectID;
		CreatedWeapon = XGWeapon(CreatedItem);
		if( CreatedWeapon != none )
		{
			if (GunsmithOverride != None)
				XGWeapon_Platform_AR(CreatedWeapon).GunsmithStateDirty = GunsmithOverride;

			//UnitPawnOverride is used when making cosmetic soldiers for the UI (main menu, armory).
			//The owner's pawn won't actually be accessible through the history when the weapon is initialized - set it here.
			if (UnitPawnOverride != None)
				CreatedWeapon.UnitPawn = UnitPawnOverride;

			CreatedWeapon.Init(ItemState);
		}

		if(bSetAsVisualizer)
		{
			`XCOMHISTORY.SetVisualizer(ItemState.ObjectID, CreatedItem);
		}

		return CreatedItem;
	}

	return none;
}

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	//  this is called by the native Init function
	local XComWeapon kNewWeapon;
	local XComWeapon Template;
	local Actor kOwner;	
	local SkeletalMeshComponent WeaponMesh, PawnMesh;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_Item AppearanceWeapon;
	local X2WeaponTemplate WeaponTemplate;
	local TWeaponAppearance WeaponAppearance;
	local string strArchetype;
	local X2UnifiedProjectile Projectile;

	if(Role != ROLE_Authority)
	{
		return none;
	}

	InternalWeaponState = ItemState;
	History = `XCOMHISTORY;
	if(InternalWeaponState == none)
	{
		InternalWeaponState = XComGameState_Item(History.GetGameStateForObjectID(ObjectID));
	}

	if (UnitPawn != none)
		kOwner = UnitPawn;
	else
	{
		m_kOwner = XGUnit(History.GetVisualizer(ItemState.OwnerStateObject.ObjectID)); //Attempt to locate the owner of this item
		kOwner = m_kOwner != none ? m_kOwner.GetPawn() : none;
	}
	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InternalWeaponState.OwnerStateObject.ObjectID));
	WeaponTemplate = X2WeaponTemplate(InternalWeaponState.GetMyTemplate());
	if (WeaponTemplate != none)
	{
		strArchetype = WeaponTemplate.DetermineGameArchetypeForUnit(InternalWeaponState, UnitState, XComHumanPawn(kOwner).m_kAppearance);
		Template = XComWeapon(`CONTENT.RequestGameArchetype(strArchetype));
	}

	if (Template == none)           //  if the weapon is a cosmetic unit, for example
		return none;

	// Copy the parts of the weapon from the template or component state
	CopyWeaponPartTemplates();

 	kNewWeapon = Spawn(Template.Class, kOwner,,,,Template);

	// Start Issue #281
	DLCInfoAddSockets(kNewWeapon, InternalWeaponState);
	// End Issue #281
	
	WeaponMesh = SkeletalMeshComponent(kNewWeapon.Mesh);

	if (XComUnitPawn(kOwner) != none)
		PawnMesh = XComUnitPawn(kOwner).Mesh;

    // Handled in child classes
    AssembleWeaponParts(kNewWeapon, WeaponMesh, PawnMesh);

	kNewWeapon.SetGameData(self);

	//Physics must be set to none, the weapon entity is purely visual until it gets dropped.
	if(kNewWeapon.Physics != PHYS_None)
	{
		kNewWeapon.SetPhysics(PHYS_None);
	}

	m_kEntity = kNewWeapon;

	//Make sure we initialize with the correct flashlight state
	UpdateFlashlightState();

	if(ItemState != none)
	{
		// Start with the default appearance on this item
		WeaponAppearance = ItemState.WeaponAppearance;
		
		// V1.005: Check if we have custom customization active
		if (arrWeaponCustomizationData.Length > 0)
		{
			SetAppearanceIndividual(arrWeaponCustomizationData);
		}
		else
		{
			if (UnitState != none)
			{				
				// Get the unit's primary weapon appearance
				AppearanceWeapon = UnitState.GetPrimaryWeapon();
				if (AppearanceWeapon != none)
				{
					// If the primary weapon exists, set it as the default
					WeaponAppearance = AppearanceWeapon.WeaponAppearance;

					// But if this item is a weapon which uses armor appearance data, save the tint and pattern from the unit instead
					if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
					{
						WeaponAppearance.iWeaponTint = UnitState.kAppearance.iArmorTint;
						WeaponAppearance.nmWeaponPattern = UnitState.kAppearance.nmPatterns;
					}
					else
					{
						// If not, check to see if the primary tints from the unit. If it does, grab the secondary weapon appearance instead.
						WeaponTemplate = X2WeaponTemplate(AppearanceWeapon.GetMyTemplate());
						if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
						{
							AppearanceWeapon = UnitState.GetSecondaryWeapon();
							WeaponAppearance = AppearanceWeapon.WeaponAppearance;
						}
					}
				}
			}

			SetAppearance(WeaponAppearance);
		}
	}

	if (`TACTICALRULES != none)
	{
		LoadFiringSound(); // Load in the Firing Sound if we're in tactical
		
		// Override firing archetypes' default animation name if the receiver template has one
		if (ReceiverTemplate != none)
		{
			// V1.005: Added boolean to clear previous pawn animations
			if (ReceiverTemplate.bReplacePawnAnimSets)
			{
				kNewWeapon.CustomUnitPawnAnimsetsFemale.Length = 0;
				kNewWeapon.CustomUnitPawnAnimsets.Length = 0;
			}

			if (ReceiverTemplate.Pawn_WeaponFireAnimSequenceName != '')
				kNewWeapon.WeaponFireAnimSequenceName				= ReceiverTemplate.Pawn_WeaponFireAnimSequenceName;

			if (ReceiverTemplate.Pawn_WeaponSuppressionFireAnimSequenceName != '')
				kNewWeapon.WeaponSuppressionFireAnimSequenceName	= ReceiverTemplate.Pawn_WeaponSuppressionFireAnimSequenceName;

			if (ReceiverTemplate.AdditionalPawnAnimSets_Male.Length > 0)
				AppendAnimations(kNewWeapon, false, ReceiverTemplate.AdditionalPawnAnimSets_Male);

			if (ReceiverTemplate.AdditionalPawnAnimSets_Female.Length > 0)
				AppendAnimations(kNewWeapon, true, ReceiverTemplate.AdditionalPawnAnimSets_Female);

			// V1.006: Projectile Override
			if (ReceiverTemplate.OverrideProjectileTemplate != "")
			{
				Projectile = X2UnifiedProjectile(`CONTENT.RequestGameArchetype(ReceiverTemplate.OverrideProjectileTemplate));

				if (Projectile != none)
					kNewWeapon.DefaultProjectileTemplate = Projectile;
			}
		}
	}
	
	//`LOG("Adding Rifle Grip to ObjectID [" $ ObjectID $ "]: " $ bUseRifleGrip,, 'WotC_Gameplay_Misc_WeaponGunsmith');
	
	// Rifle grip animations
	//if (bUseRifleGrip)
	//{
	//	AddRifleGripAnimations(kNewWeapon);
	//}

	// Start Issue #245
	DLCInfoInit(InternalWeaponState);
	// End Issue #245

	InternalWeaponState = None;
	
	return kNewWeapon;
}

function AddRifleGripAnimations(XComWeapon kWeapon)
{
	local string	AnimPath;
	local AnimSet	AnimSetContent;

	if (ReceiverTemplate.AdditionalPawnAnimSets_RifleGrip_M.Length > 0)
	{
		kWeapon.CustomUnitPawnAnimsets.Length = 0;
		
		foreach ReceiverTemplate.AdditionalPawnAnimSets_RifleGrip_M(AnimPath)
		{
			AnimSetContent = AnimSet(`CONTENT.RequestGameArchetype(AnimPath, class'AnimSet'));

			if (AnimSetContent != none)
				kWeapon.CustomUnitPawnAnimsets.AddItem(AnimSetContent);
		}
	}

	if (ReceiverTemplate.AdditionalPawnAnimSets_RifleGrip_F.Length > 0)
	{
		kWeapon.CustomUnitPawnAnimsetsFemale.Length = 0;

		foreach ReceiverTemplate.AdditionalPawnAnimSets_RifleGrip_F(AnimPath)
		{
			AnimSetContent = AnimSet(`CONTENT.RequestGameArchetype(AnimPath, class'AnimSet'));

			if (AnimSetContent != none)
				kWeapon.CustomUnitPawnAnimsetsFemale.AddItem(AnimSetContent);
		}
	}
}

// The logic can switch between battle/sniper rifle platforms (Remington 700, M14) and modern AR-15/AK-pattern platforms
// Override as needed
// If you update this part, please update ApplyIndividualAppearanceOnWeapon() as well!
function AssembleWeaponParts(XComWeapon kNewWeapon, SkeletalMeshComponent WeaponMesh, SkeletalMeshComponent PawnMesh)
{
	local int i, Idx;
	local array<WeaponAttachment>		WeaponAttachments;
	local StaticMeshComponent			MeshComp;
	local SkeletalMeshComponent			SkelMeshComp;
    local WeaponPartAttachment			IterWeaponAttachment, ReceiverWPNAtt, PartWPNAtt;

    WeaponAttachments = InternalWeaponState.GetWeaponAttachments();

	//`LOG("Building Visualizer for Weapon Template " $ InternalWeaponState.GetMyTemplate().DataName $ ", State ObjectID: " $ InternalWeaponState.ObjectID $ ", Visualizer Object ID " $ ObjectID,, 'WotC_Gameplay_Misc_WeaponGunsmith');

	// STEP 1
	// Assemble the main components from their respective weapon part template

	// Copy struct since receiver might needs new position
	ReceiverWPNAtt = ReceiverTemplate.MainComponent;

	if (StockTemplate.bActivateRifleGrip || ReargripTemplate.bActivateRifleGrip)
	{
		// Preload Animations
		AddRifleGripAnimations(kNewWeapon);
		ReceiverWPNAtt.AttachSocket = ReceiverTemplate.RifleGripSocketName;
	}

	//`LOG("Weapon " $ ObjectID $ " has Rifle Grip: " $ bUseRifleGrip ,, 'WotC_Gameplay_Misc_WeaponGunsmith');

	//
	// RECEIVER
	//
	if (ReceiverTemplate != none && WeaponMesh.GetSocketByName(ReceiverTemplate.MainComponent.AttachSocket) != none)
	{
		AttachUpgradeToSkeletalComponent(kNewWeapon, WeaponMesh, ReceiverWPNAtt, ReceiverComponent, PT_RECEIVER);
		//`LOG("Weapon Archetype " $ kNewWeapon.PathName $ " has Socket " $ ReceiverTemplate.MainComponent.AttachSocket $ " on main mesh",, 'WotC_Gameplay_Misc_WeaponGunsmith');
	}
	else
		`LOG("Archetype " $ kNewWeapon.PathName $ " missing socket " $ ReceiverTemplate.MainComponent.AttachSocket $ " on Mesh for Receiver",, 'WotC_Gameplay_Misc_WeaponGunsmith');

	//
	// BARREL
	//
	if (BarrelTemplate != none && ReceiverComponent.GetSocketByName(BarrelTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, BarrelTemplate.MainComponent, BarrelComponent, PT_BARREL);

	//
	// HANDGUARD
	// -----
	// Also used for pumps on shotguns
	if (HandguardTemplate != none)
	{
		SkelMeshComp = none;
		
		if (BarrelComponent.GetSocketByName(HandguardTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = BarrelComponent;
		else if (ReceiverComponent.GetSocketByName(HandguardTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = ReceiverComponent;

		if (SkelMeshComp != none)
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, HandguardTemplate.MainComponent, HandguardComponent, PT_HANDGUARD);
	}

	//
	// STOCK
	//
	if (StockTemplate != none)
	{
		// V1.005: Reduce clutter by having parts have alternate sockets. Stocks only supported for now.
		PartWPNAtt = StockTemplate.MainComponent;
		
		if (StockTemplate.AltSocketWithReceiver.Length > 0)
		{
			Idx = StockTemplate.AltSocketWithReceiver.Find('ReceiverName', ReceiverTemplate.DataName);

			if (Idx != INDEX_NONE)
				PartWPNAtt.AttachSocket = StockTemplate.AltSocketWithReceiver[Idx].SocketName;
		}

		// V1.005: Fail to attach if the socket doesnt exist on the weapon
		if (ReceiverComponent.GetSocketByName(PartWPNAtt.AttachSocket) != none)
			AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, PartWPNAtt, StockComponent, PT_STOCK);
	}

	//
	// MAGAZINE
	//
	if (MagazineTemplate != none && ReceiverComponent.GetSocketByName(MagazineTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, MagazineTemplate.MainComponent, MagazineComponent, PT_MAGAZINE);

	//
	// REARGRIP
	//
	if (ReargripTemplate != none && ReceiverComponent.GetSocketByName(ReargripTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, ReargripTemplate.MainComponent, ReargripComponent, PT_REARGRIP);

	//
	// UNDERBARREL
	// -----
	// Certain barrels (such as the ARES-16 and other LMGs) may not have sockets for these, so check the receiver too
	if (UnderbarrelTemplate != none)
	{
		SkelMeshComp = none;

		if (HandguardComponent.GetSocketByName(UnderbarrelTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = HandguardComponent;
		else if (BarrelComponent.GetSocketByName(UnderbarrelTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = BarrelComponent;
		else if (ReceiverComponent.GetSocketByName(UnderbarrelTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = ReceiverComponent;

		if (SkelMeshComp != none)
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, UnderbarrelTemplate.MainComponent, UnderbarrelComponent, PT_UNDERBARREL);
	}

	//
	// OPTICS
	// -----
	// Handguards (such as the SR-25) can affect the location of all optics
	if (OpticsTemplate != none)
	{
		SkelMeshComp = none;

		if (HandguardComponent.GetSocketByName(OpticsTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = HandguardComponent;
		else if (BarrelComponent.GetSocketByName(OpticsTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = BarrelComponent;
		else if (ReceiverComponent.GetSocketByName(OpticsTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = ReceiverComponent;
		
		if (SkelMeshComp != none)
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, OpticsTemplate.MainComponent, OpticComponent, PT_OPTIC);
	}

	//
	// LASER
	// -----
	// Barrels (such as the ARES-16 and other LMGs) or Handguards changes the location of the laser socket
	// If not, fall back to the receiver component
	if (LaserTemplate != none)
	{
		SkelMeshComp = none;

		if (HandguardComponent.GetSocketByName(LaserTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = HandguardComponent;
		else if (BarrelComponent.GetSocketByName(LaserTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = BarrelComponent;
		else if (ReceiverComponent.GetSocketByName(LaserTemplate.MainComponent.AttachSocket) != none)
			SkelMeshComp = ReceiverComponent;

		if (SkelMeshComp != none)
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, LaserTemplate.MainComponent, LaserComponent, PT_LASER);
	}

	//
	// MUZZLE
	//
	if (MuzzleTemplate != none && BarrelComponent.GetSocketByName(MuzzleTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, BarrelComponent, MuzzleTemplate.MainComponent, MuzzleComponent, PT_MUZZLE);

	// STEP 2
	// Now attach the rest of the objects together
	// This is done at this part since there might be sockets that depend on other parts existing first (i.e. Scopes)
	foreach ReceiverTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, IterWeaponAttachment,, PT_RECEIVER);

	foreach BarrelTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, BarrelComponent, IterWeaponAttachment,, PT_BARREL);
	
	foreach HandguardTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, HandguardComponent, IterWeaponAttachment,, PT_HANDGUARD);

	foreach StockTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, StockComponent, IterWeaponAttachment,, PT_STOCK);

	foreach MagazineTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, MagazineComponent, IterWeaponAttachment,, PT_MAGAZINE);

	foreach ReargripTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReargripComponent, IterWeaponAttachment,, PT_REARGRIP);

	foreach UnderbarrelTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, UnderbarrelComponent, IterWeaponAttachment,, PT_UNDERBARREL);

	foreach OpticsTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, OpticComponent, IterWeaponAttachment,, PT_OPTIC);

	foreach LaserTemplate.arrAttachments(IterWeaponAttachment)
	{
		if (BarrelTemplate.bBarrel_DisableLaserCap && IterWeaponAttachment.AttachSocket == CylinderLaserCapSocket)	// V1.005: Barrels can disable the laser cap attachment if needed
			continue;

		AttachUpgradeToSkeletalComponent(kNewWeapon, LaserComponent, IterWeaponAttachment,, PT_LASER);
	}

	foreach MuzzleTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, MuzzleComponent, IterWeaponAttachment,, PT_MUZZLE);

	// Reset component for loop
	SkelMeshComp = none;

	// Rest of the upgrades. Only applies to the Main Weapon mesh.
	for (i = 0; i < WeaponAttachments.Length; ++i)
	{
		if (WeaponAttachments[i].AttachToPawn && PawnMesh == none)
			continue;

		if (WeaponAttachments[i].LoadedObject != none)
		{
			if( InternalWeaponState.CosmeticUnitRef.ObjectID < 1 ) //Don't attach items that have a cosmetic unit associated with them
			{
				if (WeaponAttachments[i].LoadedObject.IsA('StaticMesh'))
				{
					MeshComp = new(kNewWeapon) class'StaticMeshComponent';
					MeshComp.SetStaticMesh(StaticMesh(WeaponAttachments[i].LoadedObject));
					MeshComp.bCastStaticShadow = false;
					if (WeaponAttachments[i].AttachToPawn)
					{
						PawnMesh.AttachComponentToSocket(MeshComp, WeaponAttachments[i].AttachSocket);
						PawnAttachments.AddItem(MeshComp);
					}
					else
					{
						WeaponMesh.AttachComponentToSocket(MeshComp, WeaponAttachments[i].AttachSocket);
					}					
				}
				else if (WeaponAttachments[i].LoadedObject.IsA('SkeletalMesh'))
				{
					SkelMeshComp = new(kNewWeapon) class'SkeletalMeshComponent';
					SkelMeshComp.SetSkeletalMesh(SkeletalMesh(WeaponAttachments[i].LoadedObject));
					SkelMeshComp.bCastStaticShadow = false;

					if (WeaponAttachments[i].AttachToPawn)
					{
						PawnMesh.AttachComponentToSocket(SkelMeshComp, WeaponAttachments[i].AttachSocket);
						PawnAttachments.AddItem(SkelMeshComp);
					}
					else
					{
						WeaponMesh.AttachComponentToSocket(SkelMeshComp, WeaponAttachments[i].AttachSocket);
					}					
				}
			}
		}
	}

	// Check the templates if there's a left_hand and gun_fire socket, and re-create them on the main mesh
	CreateDefaultSocketsOnMainMesh(WeaponMesh);
}

function AttachUpgradeToSkeletalComponent(XComWeapon kNewWeapon, SkeletalMeshComponent SkelMeshReceiver, WeaponPartAttachment WPNAttachment, optional out SkeletalMeshComponent AttachmentMesh, optional WeaponPartType Part)
{
	local SkeletalMeshComponent			SkelMeshComp;
	local AnimSet						LinkedAnimSet;
	// TODO: Do we need this?
	//if (WPNAttachment.AttachToPawn && PawnMesh == none)
	//	continue;

	if (WPNAttachment.AttachMeshName == "")
	{
		return;
	}

	// Determine if we can even add this attachment
	if (WPNAttachment.AttachmentFn != '' && !FilterAttachmentFn(WPNAttachment))
	{
		return;
	}

	if (WPNAttachment.LoadedObject == none)
	{
		WPNAttachment.LoadedObject = `CONTENT.RequestGameArchetype(WPNAttachment.AttachMeshName);

		if (WPNAttachment.LoadedObject == none)
		{
			`LOG("ERROR, Mesh " $ WPNAttachment.AttachMeshName $ " is invalid or missing!",, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
			return;
		}
	}
	
	if( InternalWeaponState.CosmeticUnitRef.ObjectID < 1 ) //Don't attach items that have a cosmetic unit associated with them
	{
		// Must be a skeletal mesh at this point
		if (WPNAttachment.LoadedObject.IsA('SkeletalMesh'))
		{
			SkelMeshComp = new(kNewWeapon) class'SkeletalMeshComponent';
			SkelMeshComp.SetSkeletalMesh(SkeletalMesh(WPNAttachment.LoadedObject));
			SkelMeshComp.bCastStaticShadow = false;
			
			// Update materials before attaching component
			UpdateMaterialsAndGatherList(SkelMeshComp, Part);

			// If a part has an AnimSet linked, then we need to load it in and initialize the AnimTree
			if (WPNAttachment.AnimSetPath != "")
			{
				LinkedAnimSet = AnimSet(`CONTENT.RequestGameArchetype(WPNAttachment.AnimSetPath, class'AnimSet'));

				// All parts inherit the same AnimTree nodes if they have an AnimSet
				if (LinkedAnimSet != none)
				{
					SkelMeshComp.SetAnimTreeTemplate(SkeletalMeshComponent(kNewWeapon.Mesh).AnimTreeTemplate);	
					SkelMeshComp.AnimSets.AddItem(LinkedAnimSet);
					SkelMeshComp.UpdateAnimations();	// Initialize

					// Set up AnimTree stuff in the weapon archetype so it plays properly when called
					XComWeapon_Gunsmith(kNewWeapon).SetUpAnimTreeNodes(SkelMeshComp);

					//`LOG("AnimSet " $ WPNAttachment.AnimSetPath $ " loaded.",, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
				}
				else
					`LOG("ERROR, AnimSet " $ WPNAttachment.AnimSetPath $ " is invalid or missing!",, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
			}

			//`LOG("Component Mesh " $ WPNAttachment.AttachMeshName $ " has " $ SkelMeshComp.Sockets.Length $ " sockets",, 'WotC_Gameplay_Misc_WeaponGunsmith');

			//if (WPNAttachment.AttachToPawn)
			//{
			//	PawnMesh.AttachComponentToSocket(SkelMeshComp, WPNAttachment.AttachSocket);
			//	PawnAttachments.AddItem(SkelMeshComp);
			//}
			//else
			//
				AttachmentMesh = SkelMeshComp;
				SkelMeshReceiver.AttachComponentToSocket(SkelMeshComp, WPNAttachment.AttachSocket);
			//}	


		}
	}
}

// Go through specific components and check if they have the default sockets on them
// Then create said socket on main mesh
function CreateDefaultSocketsOnMainMesh(SkeletalMeshComponent WeaponMesh)
{
	local SkeletalMeshSocket 			AttachSocket, UBFXSocket;
	local array<SkeletalMeshSocket>		NewSockets;
	local array<SkeletalMeshComponent>	arrMeshes;

	// Get gun_fire socket
	// In Order
	// - MUZZLE
	// - HANDGUARD
	// - BARREL
	// - RECEIVER
	arrMeshes.Length = 0;
	arrMeshes.AddItem(MuzzleComponent);
	arrMeshes.AddItem(HandguardComponent);
	arrMeshes.AddItem(BarrelComponent);
	arrMeshes.AddItem(ReceiverComponent);

	AttachSocket = CreateSocketForMainWeaponMesh(arrMeshes, 'gun_fire');

	// Append the new Socket to the array
	if (AttachSocket != none)
		NewSockets.AddItem(AttachSocket);

	// Get left_hand socket
	// In Order
	// - UNDERBARREL
	// - HANDGUARD
	// - BARREL
	// - STOCK
	// - RECEIVER
	arrMeshes.Length = 0;
	arrMeshes.AddItem(UnderbarrelComponent);
	arrMeshes.AddItem(HandguardComponent);
	arrMeshes.AddItem(BarrelComponent);
	arrMeshes.AddItem(StockComponent);
	arrMeshes.AddItem(ReceiverComponent);

	AttachSocket = CreateSocketForMainWeaponMesh(arrMeshes, 'left_hand');

	// Append the new Socket to the array
	if (AttachSocket != none)
		NewSockets.AddItem(AttachSocket);

	// Get FlashLight socket
	// In Order
	// - LASER
	// - BARREL (V1.005)
	// - RECEIVER
	arrMeshes.Length = 0;
	arrMeshes.AddItem(LaserComponent);
	arrMeshes.AddItem(BarrelComponent);	// V1.005: Included Barrels
	arrMeshes.AddItem(ReceiverComponent);

	AttachSocket = CreateSocketForMainWeaponMesh(arrMeshes, 'FlashLight');

	// Append the new Socket to the array
	if (AttachSocket != none)
		NewSockets.AddItem(AttachSocket);

	// Get socket location of `underbarrel_fire` and `underbarrel_FX_Core` from our meshes and replace the one that's already spawned in our
	// main weapon mesh via Iridar's Underbarrel Attachments mod.
	// In Order
	// - UNDERBARREL
	// - RECEIVER
	arrMeshes.Length = 0;
	arrMeshes.AddItem(UnderbarrelComponent);
	arrMeshes.AddItem(ReceiverComponent);

	AttachSocket = CreateSocketForMainWeaponMesh(arrMeshes, 'underbarrel_fire');
	UBFXSocket = CreateSocketForMainWeaponMesh(arrMeshes, 'underbarrel_FX_Core');

	// Append the new Socket to the array
	if (AttachSocket != none)
		NewSockets.AddItem(AttachSocket);
	
	if (UBFXSocket != none)
		NewSockets.AddItem(UBFXSocket);

	// Submit the new sockets to the main weapon mesh
	if (NewSockets.Length > 0)
		WeaponMesh.AppendSockets(NewSockets, true);
}

// Given an array of skeletal meshes `arrMeshes`, finds if a socket `SocketToSearchFor` exists. If there is such socket, pull the World Vector and Rotation
// and create a new socket based on said information, using `SocketToSearchFor` as the SocketName.
function SkeletalMeshSocket CreateSocketForMainWeaponMesh(array<SkeletalMeshComponent> arrMeshes, name SocketToSearchFor)
{
	local SkeletalMeshSocket 		AttachSocket;
	local SkeletalMeshComponent		ItMesh;
	local Vector			 		SocketVect, SocketScale;
	local Rotator			 		SocketRot;
	local bool						bFoundSocket;

	// Will always be 1.0f else game crashes
	SocketScale.X = 1.0f;
	SocketScale.Y = 1.0f;
	SocketScale.Z = 1.0f;

	bFoundSocket = false;

	foreach arrMeshes(ItMesh)
	{
		// Adjust XYZ and PYR based on the location of the socket
		if (ItMesh.GetSocketByName(SocketToSearchFor) != none)
		{
			ItMesh.GetSocketWorldLocationAndRotation(SocketToSearchFor, SocketVect, SocketRot);
			bFoundSocket = true;
			break;
		}
	}

	// Do nothing if there is no socket
	if (!bFoundSocket)
		return none;

	// Create socket
	AttachSocket = new class'SkeletalMeshSocket';

	AttachSocket.BoneName		= 'Root';
	AttachSocket.SocketName		= SocketToSearchFor;

	AttachSocket.RelativeLocation 	= SocketVect;
	AttachSocket.RelativeRotation 	= SocketRot;
	AttachSocket.RelativeScale 		= SocketScale;

	return AttachSocket;
}

//
// WEAPON CUSTOMIZATION
//

// Original hook to update appearance
simulated function SetAppearance( const out TWeaponAppearance kAppearance, optional bool bRequestContent=true)
{
	m_kAppearance = kAppearance;
	if (bRequestContent)
	{
		ApplyAppearanceOnWeapon();		// Apply default camo on everything
	}
}

simulated function SetAppearanceIndividual(array<WeaponCustomizationData> newCustomizationData, optional bool bRequestContent=true)
{
	arrWeaponCustomizationData = newCustomizationData;

	if (bRequestContent)
	{
		ApplyIndividualAppearanceOnWeapon();
	}
}

simulated private function ApplyAppearanceOnWeapon()
{
	local MeshComponent MeshComp;
	local XComLinearColorPalette Palette;
	local X2BodyPartTemplate PartTemplate;
	local X2BodyPartTemplateManager PartManager;
	
	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	PartTemplate = PartManager.FindUberTemplate(string('Patterns'), m_kAppearance.nmWeaponPattern);

	if (PartTemplate != none)
	{
		PatternsContent = XComPatternsContent(`CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, none, false));
	}
	else
	{
		PatternsContent = none;
	}

	NumPossibleTints = 0;
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	NumPossibleTints = Palette.Entries.Length;

	if(XComWeapon(m_kEntity) != none)
	{
		MeshComp = XComWeapon(m_kEntity).Mesh;
		UpdateMaterials(MeshComp);
	}

	if (SkeletalMeshComponent(MeshComp) != none)
		UpdateComponentMaterial(SkeletalMeshComponent(MeshComp));

	// Update every other component
	if (ReceiverComponent != none)
		UpdateComponentMaterial(ReceiverComponent);

	if (BarrelComponent != none)
		UpdateComponentMaterial(BarrelComponent);

	if (HandguardComponent != none)
		UpdateComponentMaterial(HandguardComponent);

	if (StockComponent != none)
		UpdateComponentMaterial(StockComponent);

	if (MagazineComponent != none)
		UpdateComponentMaterial(MagazineComponent);

	if (ReargripComponent != none)
		UpdateComponentMaterial(ReargripComponent);

	if (UnderbarrelComponent != none)
		UpdateComponentMaterial(UnderbarrelComponent);

	if (LaserComponent != none)
		UpdateComponentMaterial(LaserComponent);

	if (OpticComponent != none)
		UpdateComponentMaterial(OpticComponent);

	if (MuzzleComponent != none)
		UpdateComponentMaterial(MuzzleComponent);

}

function UpdateComponentMaterial(SkeletalMeshComponent MeshComp)
{
	local MeshComponent AttachedComponent;
	local int i;

	for(i = 0; i < MeshComp.Attachments.Length; ++i)
	{
		AttachedComponent = MeshComponent(MeshComp.Attachments[i].Component);
		if(AttachedComponent != none)
		{
			UpdateMaterials(AttachedComponent);
		}
	}
}

// Iterate through the array of weapon customization elements and apply to each part
function ApplyIndividualAppearanceOnWeapon()
{
	local MeshComponent				MeshComp;

	// PT_NONE (Usually the main mesh of the weapon)
	if(XComWeapon(m_kEntity) != none)
	{
		MeshComp = XComWeapon(m_kEntity).Mesh;
		UpdateAllWeaponCustomizationMaterials(MeshComp, PT_RECEIVER);
	}

	// Receiver part
	if (SkeletalMeshComponent(MeshComp) != none)
		UpdateComponentMaterial_WeaponCustomization(SkeletalMeshComponent(MeshComp), PT_RECEIVER);

	// Update every other component
	// If there's multiple function calls, that means that potentially there's another place a part can exist in
	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_RECEIVER);

	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_BARREL);
	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_BARREL);

	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_HANDGUARD);
	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_HANDGUARD);
	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_HANDGUARD);
	UpdateComponentMaterial_WeaponCustomization(HandguardComponent, PT_HANDGUARD);

	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent,	PT_STOCK);
	UpdateComponentMaterial_WeaponCustomization(StockComponent,		PT_STOCK);

	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_MAGAZINE);
	UpdateComponentMaterial_WeaponCustomization(MagazineComponent, PT_MAGAZINE);

	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_REARGRIP);
	UpdateComponentMaterial_WeaponCustomization(ReargripComponent, PT_REARGRIP);

	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_UNDERBARREL);
	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_UNDERBARREL);
	UpdateComponentMaterial_WeaponCustomization(HandguardComponent, PT_UNDERBARREL);
	UpdateComponentMaterial_WeaponCustomization(UnderbarrelComponent, PT_UNDERBARREL);

	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_LASER);
	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_LASER);
	UpdateComponentMaterial_WeaponCustomization(HandguardComponent, PT_LASER);
	UpdateComponentMaterial_WeaponCustomization(LaserComponent, PT_LASER);

	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_OPTIC);
	UpdateComponentMaterial_WeaponCustomization(ReceiverComponent, PT_OPTIC);
	UpdateComponentMaterial_WeaponCustomization(HandguardComponent, PT_OPTIC);
	UpdateComponentMaterial_WeaponCustomization(OpticComponent, PT_OPTIC);

	UpdateComponentMaterial_WeaponCustomization(BarrelComponent, PT_MUZZLE);
	UpdateComponentMaterial_WeaponCustomization(MuzzleComponent, PT_MUZZLE);
}

function UpdateComponentMaterial_WeaponCustomization(SkeletalMeshComponent MeshComp, WeaponPartType Part)
{
	local MeshComponent AttachedComponent;
	local int i;

	// Do nothing if there's empty meshes
	if (MeshComp == none)
		return;

	for(i = 0; i < MeshComp.Attachments.Length; ++i)
	{
		AttachedComponent = MeshComponent(MeshComp.Attachments[i].Component);

		if(AttachedComponent != none)
		{
			UpdateAllWeaponCustomizationMaterials(AttachedComponent, Part);
		}
	}
}

simulated private function UpdateAllWeaponCustomizationMaterials(MeshComponent MeshComp, WeaponPartType Part)
{
	local int i;
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC, NewMIC;
	local array<name> PartMaterialNames;

	PartMaterialNames = GetMaterialNames(Part);
	
	if (MeshComp != none)
	{
		for (i = 0; i < MeshComp.GetNumElements(); ++i)
		{
			Mat = MeshComp.GetMaterial(i);
			MIC = MaterialInstanceConstant(Mat);

			// Skip over if our material doesn't exist for this part
			if (PartMaterialNames.Find(MIC.Parent.Name) == INDEX_NONE)
				continue;

			// It is possible for there to be MITVs in these slots, so check
			if (MIC != none)
			{
				// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
				// on each other between units.
				if (InStr(MIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
				{
					NewMIC = new (self) class'MaterialInstanceConstant';
					NewMIC.SetParent(MIC);
					MeshComp.SetMaterial(i, NewMIC);
					MIC = NewMIC;
				}
				
				ParentMat = MIC.Parent;
				while (!ParentMat.IsA('Material'))
				{
					ParentMIC = MaterialInstanceConstant(ParentMat);
					if (ParentMIC != none)
						ParentMat = ParentMIC.Parent;
					else
						break;
				}

				UpdateSingleWeaponCustomizationMaterial(MeshComp, MIC, Part);
			}
		}
	}	
}

// Logic largely based off of UpdateArmorMaterial in XComHumanPawn
simulated function UpdateSingleWeaponCustomizationMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC, WeaponPartType Part)
{
	local XComLinearColorPalette	Palette;
	local LinearColor				PrimaryTint, SecondaryTint;
	local X2BodyPartTemplate		PartTemplate;
	local X2BodyPartTemplateManager PartManager;	
	local WeaponCustomizationData	SinglePartWC;
	local float						Rad;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	// Fallback to PT_RECEIVER if were on PT_NONE
	if (Part == PT_NONE)
		SinglePartWC = arrWeaponCustomizationData[PT_RECEIVER];
	else
		SinglePartWC = arrWeaponCustomizationData[Part];

	PatternsContent = none;
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);

	if (SinglePartWC.iPrimaryTintPaletteIdx != INDEX_NONE)
	{
		PrimaryTint = Palette.Entries[SinglePartWC.iPrimaryTintPaletteIdx].Primary;
		MIC.SetVectorParameterValue('Primary Color', PrimaryTint);
	}
	else
		MIC.SetVectorParameterValue('Primary Color', SinglePartWC.PrimaryTintColor);

	// Merging masks will disable the secondary color (XCom 2 default camo application)
	if (SinglePartWC.bMergeMasks)
	{
		MIC.SetScalarParameterValue('PrimaryAsSecondaryColor', 1);
	}
	else
	{
		MIC.SetScalarParameterValue('PrimaryAsSecondaryColor', 0);

		if (SinglePartWC.iSecondaryTintPaletteIdx != INDEX_NONE)
		{
			SecondaryTint = Palette.Entries[SinglePartWC.iSecondaryTintPaletteIdx].Secondary;
			MIC.SetVectorParameterValue('Secondary Color', SecondaryTint);
		}
		else
		{
			MIC.SetVectorParameterValue('Secondary Color', SinglePartWC.SecondaryTintColor);
		}
	}

	if (SinglePartWC.TertiaryTintColor.A > 0)
	{
		MIC.SetScalarParameterValue('UseTertiaryColor', 1);
		MIC.SetVectorParameterValue('Tertiary Color', SinglePartWC.TertiaryTintColor);
	}

	// Modify Emissives if they exist
	if (SinglePartWC.EmissiveColor.A > 0)
	{
		MIC.SetVectorParameterValue('Emissive Color', SinglePartWC.EmissiveColor);
		MIC.SetScalarParameterValue('EmissiveScale', SinglePartWC.fEmissivePower);
	}
	
	// Swaps main camo mask (Swaps R channel to G channel and vise versa)
	if (SinglePartWC.bSwapMasks)
		MIC.SetScalarParameterValue('SwapTintMask', 1);
	else
		MIC.SetScalarParameterValue('SwapTintMask', 0);
	
	PartTemplate = PartManager.FindUberTemplate(string('Patterns'), SinglePartWC.CamoTemplateName);

	if (PartTemplate != none)
		PatternsContent = XComPatternsContent(`CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, none, false));
	
	if(PatternsContent != none)
	{
		if (PatternsContent.Diffuse != none)
		{
			MIC.SetScalarParameterValue('PatternUse', 1);	
			MIC.SetScalarParameterValue('NoPatternTinting', 0);	// Diffuse-based camos (no tinting)	
			MIC.SetTextureParameterValue('Pattern', PatternsContent.Diffuse);
		}
		else if (PatternsContent.Texture != none)
		{		
			MIC.SetScalarParameterValue('PatternUse', 1);		
			MIC.SetTextureParameterValue('Pattern', PatternsContent.Texture);
		}
		else
		{
			MIC.SetScalarParameterValue('PatternUse', 0);
			MIC.SetTextureParameterValue('Pattern', none);
		}
	}

	if (SinglePartWC.fTexUSize > 0)
		MIC.SetScalarParameterValue('UScale', SinglePartWC.fTexUSize);

	if (SinglePartWC.fTexVSize > 0)
		MIC.SetScalarParameterValue('VScale', SinglePartWC.fTexVSize);

	if (SinglePartWC.iTexRot >= 0)
	{
		Rad = SinglePartWC.iTexRot * DegToRad;

		MIC.SetScalarParameterValue('Rotation', Rad);
	}
}

// Original UpdateMaterial Function but also gathers material names of specific parts for cross reference later on
simulated function UpdateMaterialsAndGatherList(MeshComponent MeshComp, WeaponPartType Part)
{
	local int i;
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC, NewMIC;
	
	if (MeshComp != none)
	{
		for (i = 0; i < MeshComp.GetNumElements(); ++i)
		{
			Mat = MeshComp.GetMaterial(i);
			MIC = MaterialInstanceConstant(Mat);

			// It is possible for there to be MITVs in these slots, so check
			if (MIC != none)
			{
				// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
				// on each other between units.
				if (InStr(MIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
				{
					NewMIC = new (self) class'MaterialInstanceConstant';
					NewMIC.SetParent(MIC);
					MeshComp.SetMaterial(i, NewMIC);
					MIC = NewMIC;
				}
				
				ParentMat = MIC.Parent;
				while (!ParentMat.IsA('Material'))
				{
					ParentMIC = MaterialInstanceConstant(ParentMat);
					if (ParentMIC != none)
						ParentMat = ParentMIC.Parent;
					else
						break;
				}

				StoreToMaterialsArray(MIC.Parent.Name, Part);

				UpdateWeaponMaterial(MeshComp, MIC);
			}
		}

		// Start Issue #246
		DLCInfoUpdateWeaponMaterial(MeshComp);
		// End Issue #246
	}
}

function StoreToMaterialsArray(name MaterialName, WeaponPartType Part)
{
	switch(Part)
	{
		case PT_RECEIVER:
			ReceiverMaterialNames.AddItem(MaterialName);
			break;
		case PT_BARREL:
			BarrelMaterialNames.AddItem(MaterialName);
			break;
		case PT_HANDGUARD:
			HandguardMaterialNames.AddItem(MaterialName);
			break;
		case PT_STOCK:
			StockMaterialNames.AddItem(MaterialName);
			break;
		case PT_MAGAZINE:
			MagazineMaterialNames.AddItem(MaterialName);
			break;
		case PT_REARGRIP:
			ReargripMaterialNames.AddItem(MaterialName);
			break;
		case PT_UNDERBARREL:
			UnderbarrelMaterialNames.AddItem(MaterialName);
			break;
		case PT_LASER:
			LaserMaterialNames.AddItem(MaterialName);
			break;
		case PT_OPTIC:
			OpticMaterialNames.AddItem(MaterialName);
			break;
		case PT_MUZZLE:
			MuzzleMaterialNames.AddItem(MaterialName);
			break;
		default:
			break;
	}
}

function array<name> GetMaterialNames(WeaponPartType Part)
{
	local array<name> EmptyNames;

	switch(Part)
	{
		case PT_RECEIVER:
			return ReceiverMaterialNames;
			break;
		case PT_BARREL:
			return BarrelMaterialNames;
			break;
		case PT_HANDGUARD:
			return HandguardMaterialNames;
			break;
		case PT_STOCK:
			return StockMaterialNames;
			break;
		case PT_MAGAZINE:
			return MagazineMaterialNames;
			break;
		case PT_REARGRIP:
			return ReargripMaterialNames;
			break;
		case PT_UNDERBARREL:
			return UnderbarrelMaterialNames;
			break;
		case PT_LASER:
			return LaserMaterialNames;
			break;
		case PT_OPTIC:
			return OpticMaterialNames;
			break;
		case PT_MUZZLE:
			return MuzzleMaterialNames;
			break;
		default:
			break;
	}

	return EmptyNames;
}

// Logic largely based off of UpdateArmorMaterial in XComHumanPawn
simulated function UpdateWeaponMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC)
{
	// If the player has enabled

	local XComLinearColorPalette Palette;
	local LinearColor PrimaryTint;
	local LinearColor SecondaryTint;

	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	if (Palette != none)
	{
		if(m_kAppearance.iWeaponTint != INDEX_NONE)
		{
			PrimaryTint = Palette.Entries[m_kAppearance.iWeaponTint].Primary;
			MIC.SetVectorParameterValue('Primary Color', PrimaryTint);
		}
		if(m_kAppearance.iWeaponDeco != INDEX_NONE)
		{
			SecondaryTint = Palette.Entries[m_kAppearance.iWeaponDeco].Secondary;
			MIC.SetVectorParameterValue('Secondary Color', SecondaryTint);
		}
	}
	
	if(PatternsContent != none && PatternsContent.Texture != none)
	{		
		MIC.SetScalarParameterValue('PatternUse', 1);		
		MIC.SetTextureParameterValue('Pattern', PatternsContent.Texture);
	}
	else
	{
		MIC.SetScalarParameterValue('PatternUse', 0);
		MIC.SetTextureParameterValue('Pattern', none);
	}
}

//
// UTILITIES
//
function CopyWeaponPartTemplates()
{
	local XCGS_WeaponGunsmith WeaponGunsmithState;

	// Get cosmetic data from the component state, if it exists. 
	// If we're in the armory previewing upgrades, copy the state and get the templates from there instead
	if (GunsmithStateDirty != none)
		WeaponGunsmithState = GunsmithStateDirty;
	else 
		WeaponGunsmithState = XCGS_WeaponGunsmith(InternalWeaponState.FindComponentObject(class'XCGS_WeaponGunsmith'));

	//`LOG("Gunsmith State " $ WeaponGunsmithState.ObjectID $ "\n" $ WeaponGunsmithState.ToString(),, 'WotC_Gameplay_Misc_WeaponGunsmith');

	if (WeaponGunsmithState.ObjectID > 0)
	{
		ReceiverTemplate			= WeaponGunsmithState.GetPartTemplate(PT_RECEIVER);
		BarrelTemplate				= WeaponGunsmithState.GetPartTemplate(PT_BARREL);
		HandguardTemplate			= WeaponGunsmithState.GetPartTemplate(PT_HANDGUARD);
		StockTemplate				= WeaponGunsmithState.GetPartTemplate(PT_STOCK);
		MagazineTemplate			= WeaponGunsmithState.GetPartTemplate(PT_MAGAZINE);
		ReargripTemplate			= WeaponGunsmithState.GetPartTemplate(PT_REARGRIP);
		UnderbarrelTemplate			= WeaponGunsmithState.GetPartTemplate(PT_UNDERBARREL);
		LaserTemplate				= WeaponGunsmithState.GetPartTemplate(PT_LASER);
		OpticsTemplate				= WeaponGunsmithState.GetPartTemplate(PT_OPTIC);
		MuzzleTemplate				= WeaponGunsmithState.GetPartTemplate(PT_MUZZLE);

		// Copy customization data from game state
		arrWeaponCustomizationData	= WeaponGunsmithState.arrWeaponCustomizationParts;
	}
	else
	{
		`LOG("ERROR, Component State for ObjectID : " $ ObjectID $ " does not exist! Weapon will not be visualized properly!",, 'WotC_Gameplay_Misc_WeaponGunsmith');
	}
}

function bool FilterAttachmentFn(WeaponPartAttachment WPNAttachment)
{
	local bool Result;

	switch (WPNAttachment.AttachmentFn)
	{
		case 'NoOpticsEquipped':
			Result = IsNoOpticsEquipped();
			break;
		case 'OpticsEquipped':
			Result = !IsNoOpticsEquipped();
			break;
		case 'NoLaserEquipped':
			Result = IsNoLaserEquipped();
			break;
		case 'LaserEquipped':
			Result = !IsNoLaserEquipped();
			break;
		case 'NoMuzzleEquipped':
			Result = IsNoMuzzleEquipped();
			break;
		case 'MuzzleEquipped':
			Result = !IsNoMuzzleEquipped();
			break;
		case 'NoUnderbarrelEquipped':
			Result = IsNoUnderbarrelEquipped();
			break;
		case 'UnderbarrelEquipped':
			Result = !IsNoUnderbarrelEquipped();
			break;
		case 'NoShortBarrelEquipped':
			Result = !IsBarrelShort();
			break;
		case 'ShortBarrelEquipped':
			Result = IsBarrelShort();
			break;
		// V1.005: Allows receivers to attachs scopes with mounts, instead of the default mount
		case 'OpticWithMountEquipped':
			Result = (!IsNoOpticsEquipped() && IsOpticWithMountEquipped());
			break;
		case 'NoOpticWithMountEquipped':
			Result = (!IsNoOpticsEquipped() && !IsOpticWithMountEquipped());
			break;
		// V1.005: Bipod Handling
		case 'BipodEquipped':
			Result = IsBipodEquipped();
			break;
		case 'NoBipodEquipped':
			Result = !IsBipodEquipped();
			break;
		case 'ModularStockEquipped':
			Result = IsModularStockEquipped();
			break;
		case 'NoModularStockEquipped':
			Result = !IsModularStockEquipped();
			break;
		// V1.008: Handguard Logic
		case 'HandguardEquipped':
			Result = IsHandguardEquipped();
			break;
		case 'NoHandguardEquipped':
			Result = !IsHandguardEquipped();
			break;
	}

	return Result;
}

function bool IsNoOpticsEquipped()
{
	return (OpticsTemplate.DataName == 'PT_SPECIAL_OPTIC_NONE');
}

function bool IsOpticWithMountEquipped()
{
	return (OpticsTemplate.bOptics_WithMount);
}

function bool IsNoLaserEquipped()
{
	return (LaserTemplate.DataName == 'PT_SPECIAL_LASER_NONE');
}

function bool IsNoMuzzleEquipped()
{
	return (MuzzleTemplate.DataName == 'PT_SPECIAL_MUZZLE_NONE');
}

function bool IsNoUnderbarrelEquipped()
{
	return (UnderbarrelTemplate.DataName == 'PT_SPECIAL_UNDERBARREL_NONE');
}

function bool IsAnyPartSuppressor()
{
	return (BarrelTemplate.bIsSuppressor || MuzzleTemplate.bIsSuppressor);
}

function bool IsBarrelShort()
{
	return (BarrelTemplate.bBarrel_IsShort);
}

function bool IsBipodEquipped()
{
	return (UnderbarrelTemplate.bUnderbarrel_IsBipod);
}

function bool IsModularStockEquipped()
{
	return (StockTemplate.bStock_Modular);
}

function bool IsHandguardEquipped()
{
	return (HandguardTemplate.DataName == 'PT_SPECIAL_HANDGUARD_NONE');
}

/*
function SkeletalMeshComponent GetPartComponent(WeaponPartType PartType)
{
	switch(PartType)
	{
		case PT_RECEIVER:
			return ReceiverComponent; break;
		case PT_BARREL:
			return BarrelComponent; break;
		case PT_NONE:
		case PT_MAX:
			break;
	}

	return none;
}
*/

// Sounds
function LoadFiringSound()
{
	// Check if we have a muzzle or a barrel that has Suppressor flag on it
	if ( IsAnyPartSuppressor() )
		FireSound = SoundCue(`CONTENT.RequestGameArchetype(ReceiverTemplate.SuppressedFiringSoundCue, class'SoundCue'));
	else
		FireSound = SoundCue(`CONTENT.RequestGameArchetype(ReceiverTemplate.DefaultFiringSoundCue, class'SoundCue'));

//	`LOG("Loaded sound: " $ FireSound,, 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
}

// Animations
function AppendAnimations(XComWeapon kWeapon, bool bIsFemale, array<string> AnimSetPaths)
{
	local string AnimPath;

	foreach AnimSetPaths(AnimPath)
	{
		if (bIsFemale)
			kWeapon.CustomUnitPawnAnimsetsFemale.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimPath)));
		else
			kWeapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimPath)));

	}
}

defaultproperties
{

}