//
// Recreation of AnimNotify_PlayWeaponAnims
//
class AnimNotify_PlayWeaponAnims_GS extends AnimNotify_Scripted;

var() Name AnimName; // Only supports playing a single non-looping animation

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn					Pawn;
	local XComWeapon_Gunsmith			Weapon;

	local CustomAnimParams			AnimParams;
	local AnimSequence				FoundAnimSeq;
	local SkeletalMeshComponent		Mesh;
	local int i;

	Pawn = XComUnitPawn(Owner);
    if (Pawn == none)
		return;
	
	Weapon = XComWeapon_Gunsmith(Pawn.Weapon);
	if (Weapon == none)
		return;

	AnimParams.AnimName = AnimName;
	AnimParams.Looping	= false;
	AnimParams.Additive = false;

	foreach Weapon.arrMeshes(Mesh, i)
	{
		FoundAnimSeq = Mesh.FindAnimSequence(AnimParams.AnimName);
		
		if( FoundAnimSeq == None )
		{
			`log("ERROR, Mesh " $ i $ " has no Anim Sequence: " $ AnimParams.AnimName , , 'WotC_Gameplay_Misc_WeaponGunsmith_Base');
			continue;
		}

		//Tell our weapon to play its fire animation
		if( Weapon.arrDynamicNodes[i] != None )
		{
			Weapon.arrDynamicNodes[i].PlayDynamicAnim(AnimParams);
		}
	}
}

defaultproperties
{
	NotifyColor=(R=0,G=0,B=128,A=255)
}
