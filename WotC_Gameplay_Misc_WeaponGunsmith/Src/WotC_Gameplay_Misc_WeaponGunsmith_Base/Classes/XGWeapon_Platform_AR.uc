//---------------------------------------------------------------------------------------
//  FILE:    XGWeapon.uc  
//  PURPOSE: Visualizer class for items / weapons in X2
//           
//           Adds psuedo part system seen in MW'19/22, where sockets in skeletal meshes 
//           of certain parts dictate where other parts go. 
//
//           (E.g different barrels has different locations for muzzle breaks)
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

	if (`TACTICALRULES != none)
	{
		LoadFiringSound(); // Load in the Firing Sound if we're in tactical
		
		// Override firing archetypes' default animation name if the receiver template has one
		if (ReceiverTemplate != none)
		{
			if (ReceiverTemplate.Pawn_WeaponFireAnimSequenceName != '')
				kNewWeapon.WeaponFireAnimSequenceName				= ReceiverTemplate.Pawn_WeaponFireAnimSequenceName;

			if (ReceiverTemplate.Pawn_WeaponSuppressionFireAnimSequenceName != '')
				kNewWeapon.WeaponSuppressionFireAnimSequenceName	= ReceiverTemplate.Pawn_WeaponSuppressionFireAnimSequenceName;

			if (ReceiverTemplate.AdditionalPawnAnimSets_Male.Length > 0)
				AppendAnimations(kNewWeapon, false, ReceiverTemplate.AdditionalPawnAnimSets_Male);

			if (ReceiverTemplate.AdditionalPawnAnimSets_Female.Length > 0)
				AppendAnimations(kNewWeapon, true, ReceiverTemplate.AdditionalPawnAnimSets_Female);
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
function AssembleWeaponParts(XComWeapon kNewWeapon, SkeletalMeshComponent WeaponMesh, SkeletalMeshComponent PawnMesh)
{
	local int i;
	local array<WeaponAttachment>		WeaponAttachments;
	local StaticMeshComponent			MeshComp;
	local SkeletalMeshComponent			SkelMeshComp;
    local WeaponPartAttachment			IterWeaponAttachment, ReceiverWPNAtt;

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

	`LOG("Weapon " $ ObjectID $ " has Rifle Grip: " $ bUseRifleGrip ,, 'WotC_Gameplay_Misc_WeaponGunsmith');

	//
	// RECEIVER
	//
	if (ReceiverTemplate != none && WeaponMesh.GetSocketByName(ReceiverTemplate.MainComponent.AttachSocket) != none)
	{
		AttachUpgradeToSkeletalComponent(kNewWeapon, WeaponMesh, ReceiverWPNAtt, ReceiverComponent);
		//`LOG("Weapon Archetype " $ kNewWeapon.PathName $ " has Socket " $ ReceiverTemplate.MainComponent.AttachSocket $ " on main mesh",, 'WotC_Gameplay_Misc_WeaponGunsmith');
	}
	else
		`LOG("Archetype " $ kNewWeapon.PathName $ " missing socket " $ ReceiverTemplate.MainComponent.AttachSocket $ " on Mesh for Receiver",, 'WotC_Gameplay_Misc_WeaponGunsmith');

	//
	// BARREL
	//
	if (BarrelTemplate != none && ReceiverComponent.GetSocketByName(BarrelTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, BarrelTemplate.MainComponent, BarrelComponent);

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
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, HandguardTemplate.MainComponent, HandguardComponent);
	}

	//
	// STOCK
	//
	if (StockTemplate != none && ReceiverComponent.GetSocketByName(StockTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, StockTemplate.MainComponent, StockComponent);

	//
	// MAGAZINE
	//
	if (MagazineTemplate != none && ReceiverComponent.GetSocketByName(MagazineTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, MagazineTemplate.MainComponent, MagazineComponent);

	//
	// REARGRIP
	//
	if (ReargripTemplate != none && ReceiverComponent.GetSocketByName(ReargripTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, ReargripTemplate.MainComponent, ReargripComponent);

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
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, UnderbarrelTemplate.MainComponent, UnderbarrelComponent);
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
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, OpticsTemplate.MainComponent, OpticComponent);
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
			AttachUpgradeToSkeletalComponent(kNewWeapon, SkelMeshComp, LaserTemplate.MainComponent, LaserComponent);
	}

	//
	// MUZZLE
	//
	if (MuzzleTemplate != none && BarrelComponent.GetSocketByName(MuzzleTemplate.MainComponent.AttachSocket) != none)
		AttachUpgradeToSkeletalComponent(kNewWeapon, BarrelComponent, MuzzleTemplate.MainComponent, MuzzleComponent);

	// STEP 2
	// Now attach the rest of the objects together
	// This is done at this part since there might be sockets that depend on other parts existing first (i.e. Scopes)
	foreach ReceiverTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReceiverComponent, IterWeaponAttachment);

	foreach BarrelTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, BarrelComponent, IterWeaponAttachment);
	
	foreach HandguardTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, HandguardComponent, IterWeaponAttachment);

	foreach StockTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, StockComponent, IterWeaponAttachment);

	foreach MagazineTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, MagazineComponent, IterWeaponAttachment);

	foreach ReargripTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, ReargripComponent, IterWeaponAttachment);

	foreach UnderbarrelTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, UnderbarrelComponent, IterWeaponAttachment);

	foreach OpticsTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, OpticComponent, IterWeaponAttachment);

	foreach LaserTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, LaserComponent, IterWeaponAttachment);

	foreach MuzzleTemplate.arrAttachments(IterWeaponAttachment)
		AttachUpgradeToSkeletalComponent(kNewWeapon, MuzzleComponent, IterWeaponAttachment);

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

function AttachUpgradeToSkeletalComponent(XComWeapon kNewWeapon, SkeletalMeshComponent SkelMeshReceiver, WeaponPartAttachment WPNAttachment, optional out SkeletalMeshComponent AttachmentMesh)
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
			UpdateMaterials(SkelMeshComp);

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
			//{
				SkelMeshReceiver.AttachComponentToSocket(SkelMeshComp, WPNAttachment.AttachSocket);
			//}	

			AttachmentMesh = SkelMeshComp;
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
	// - RECEIVER
	arrMeshes.Length = 0;
	arrMeshes.AddItem(LaserComponent);
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
// Update every component that's tied to this gamedata
// 
simulated function SetAppearance( const out TWeaponAppearance kAppearance, optional bool bRequestContent=true )
{
	m_kAppearance = kAppearance;
	if (bRequestContent)
	{
		ApplyAppearanceOnWeapon();
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
	}

	return Result;
}

function bool IsNoOpticsEquipped()
{
	return (OpticsTemplate.DataName == 'PT_SPECIAL_OPTIC_NONE');
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