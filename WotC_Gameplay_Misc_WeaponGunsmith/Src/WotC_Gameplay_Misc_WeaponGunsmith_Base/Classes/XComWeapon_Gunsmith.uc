// Can't avoid this dependson unfortunately
class XComWeapon_Gunsmith extends XComWeapon dependson(XGWeapon_Platform_AR);

var array<XComAnimNodeBlendDynamic> arrDynamicNodes;			// List of all dynamic nodes on all weapon parts
var array<XComAnimNodeBlendDynamic> arrAdditiveDynamicNodes;	// List of all additive dyn nodes on all weapon parts
var array<AnimNodeAdditiveBlending> arrAdditiveNodes;			// List of all pure additive nodes on all weapon parts

var array<SkeletalMeshComponent>	arrMeshes;

// Copy the AnimTree and paste in onto the rest of the components
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	//local XGWeapon_Platform_AR	CustomWeapon;

	//CustomWeapon = XGWeapon_Platform_AR(m_kGameWeapon);

	if (SkelComp == Mesh)
	{
		// Primary AnimTree nodes
		DynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('BlendDynamic'));
		AdditiveDynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('AdditiveBlendDynamic'));
		AdditiveNode = AnimNodeAdditiveBlending(SkelComp.Animations.FindAnimNode('AdditiveBlend'));
		AimOffset = AnimNodeAimOffset(SkelComp.Animations.FindAnimNode('AimOffset'));

		if( AdditiveDynamicNode != None )
		{
			AdditiveDynamicNode.SetAdditive(true);
		}

		if( AdditiveNode != None )
		{
			AdditiveNode.SetBlendTarget(1.0f, 0.0f);
		}

		if( AimOffset != None )
		{
			AimOffset.Aim.X = 0.0f;
			AimOffset.Aim.Y = 0.0f;
		}

		arrDynamicNodes.AddItem(DynamicNode);
		arrAdditiveDynamicNodes.AddItem(AdditiveDynamicNode);
		arrAdditiveNodes.AddItem(AdditiveNode);

		arrMeshes.AddItem(SkelComp);
	}

//	// Iterate through the rest of the components and pull the nodes from them
//	if (CustomWeapon.GetPartComponent(PT_RECEIVER).AnimSets.Length > 0)
//	{
//		SetUpAnimTreeNodes(CustomWeapon.GetPartComponent(PT_RECEIVER));
//	}
//
//	if (CustomWeapon.GetPartComponent(PT_BARREL).AnimSets.Length > 0)
//	{
//		SetUpAnimTreeNodes(CustomWeapon.GetPartComponent(PT_BARREL));
//	}

	// Don't think we need animations for the rest of the parts. This might change later on though

	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
	//SetUpAnimTreeNodes(CustomWeapon.ReceiverComponent);
}

function SetUpAnimTreeNodes(SkeletalMeshComponent SkelComp)
{
	local XComAnimNodeBlendDynamic newDynamicNode, newAdditiveDynamicNode;
	local AnimNodeAdditiveBlending newAdditiveNode;

	newDynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('BlendDynamic'));
	newAdditiveDynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('AdditiveBlendDynamic'));
	newAdditiveNode = AnimNodeAdditiveBlending(SkelComp.Animations.FindAnimNode('AdditiveBlend'));

	if( newAdditiveDynamicNode != None )
	{
		newAdditiveDynamicNode.SetAdditive(true);
	}

	if( newAdditiveNode != None )
	{
		newAdditiveNode.SetBlendTarget(1.0f, 0.0f);
	}

	arrDynamicNodes.AddItem(newDynamicNode);
	arrAdditiveDynamicNodes.AddItem(newAdditiveDynamicNode);
	arrAdditiveNodes.AddItem(newAdditiveNode);

	arrMeshes.AddItem(SkelComp);
}