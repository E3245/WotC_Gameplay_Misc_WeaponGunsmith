class UIListener_MCMOptions_GS extends UIScreenListener config(MCM_GunsmithModOptions_User);

`include(ModConfigMenuAPI/MCM_API_Includes.uci)
`include(ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

// Applying upgrades unlocks a category for upgraded weapon
var config bool bUpgradesUnlockWeaponPartCategory;

// Disables filtering on weapons, making every part available to equip on any weapons.
var config bool bCursedWeaponMode;

var config int CONFIG_VERSION;

var localized string m_strGunsmithMod_TabLabel;
var localized string m_strGunsmithMod_PageTitle;

var localized string m_strGunsmithMod_Group1Options_Title;

var localized string m_strOption_GunsmithModPage_Title;
var localized string m_strOption_GunsmithModPage_Desc;

var localized string m_strOption_UpgradeUnlocksCategory_Title;
var localized string m_strOption_UpgradeUnlocksCategory_Tooltip;

var localized string m_strOption_CursedGunMode_Title;
var localized string m_strOption_CursedGunMode_Tooltip;

event OnInit(UIScreen Screen)
{
	// Everything out here runs on every UIScreen. Not great but necessary.
	if (MCM_API(Screen) != none)
	{
		// Everything in here runs only when you need to touch MCM.
		`MCM_API_Register(Screen, GunsmithClientModCB);
	}
}

simulated function GunsmithClientModCB(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;
    
    LoadSavedSettings();
    
    Page = ConfigAPI.NewSettingsPage(default.m_strGunsmithMod_TabLabel);
    Page.SetPageTitle(default.m_strGunsmithMod_PageTitle);
    Page.SetSaveHandler(SaveButtonClicked);
    
    Group = Page.AddGroup('Group1', default.m_strGunsmithMod_Group1Options_Title);

    Group.AddCheckbox('checkbox', default.m_strOption_UpgradeUnlocksCategory_Title, default.m_strOption_UpgradeUnlocksCategory_Tooltip, bUpgradesUnlockWeaponPartCategory, bUpgradesUnlockWeaponPartCategorySaveHandler);  
    Group.AddCheckbox('checkbox', default.m_strOption_CursedGunMode_Title, default.m_strOption_CursedGunMode_Tooltip, bCursedWeaponMode, bCursedWPNModeSaveHandler);

    Page.ShowSettings();
}

`MCM_CH_VersionChecker(class'MCM_GunsmithModOptions_Defaults'.default.VERSION, CONFIG_VERSION)

simulated function LoadSavedSettings()
{
    bCursedWeaponMode					= `MCM_CH_GetValue(class'MCM_GunsmithModOptions_Defaults'.default.bCursedWeaponMode, bCursedWeaponMode);
	bUpgradesUnlockWeaponPartCategory	= `MCM_CH_GetValue(class'MCM_GunsmithModOptions_Defaults'.default.bUpgradesUnlockWeaponPartCategory, bUpgradesUnlockWeaponPartCategory);
}

`MCM_API_BasicCheckboxSaveHandler(bCursedWPNModeSaveHandler,					bCursedWeaponMode)
`MCM_API_BasicCheckboxSaveHandler(bUpgradesUnlockWeaponPartCategorySaveHandler, bUpgradesUnlockWeaponPartCategory)

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}

defaultproperties
{
    ScreenClass = none;
}