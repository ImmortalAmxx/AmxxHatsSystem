/**
	История изменений:
		1.0 (15.05.2022) by ImmortalAmxx
			- Первый релиз;

	Благодарности: b0t, 6u3oH.
*/

new const PLUGIN_NAME[] = "[ReAPI] Menu: Hats";
new const VERSION[] = "1.0";

#include <amxmodx>
#include <reapi>
#include <reapi_v>

enum _:PlayerData {
	CURRENT_HAT,
	ENTITY_HAT
};

new const g_szPathFile[] = "re_hatsmenu.ini";

new g_pPlayerData[33][PlayerData];

new Array:g_szArrayItemName, Array:g_szHatsName, Array:g_szHatsFlag, Array:g_iModelsHatsIndex;

public client_disconnected(pPlayer) {
	if(!is_nullent(g_pPlayerData[pPlayer][ENTITY_HAT]))
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_flags, FL_KILLME);
}

public client_putinserver(pPlayer)
	g_pPlayerData[pPlayer][CURRENT_HAT] = NULLENT;

public plugin_init() {
	register_plugin(PLUGIN_NAME, VERSION, "Base code: b0t, 6u3oH / Edit: ImmortalAmxx");
	register_dictionary("AmxxHats.txt");

	UTIL_RegisterClCmd("hats", "ShowMenuHats");   
}

public plugin_precache() {
	Func_ReadFile();

	new szName[128], iIndexPrecache, iCase;

	for(iCase = 0; iCase < ArraySize(g_szHatsName); iCase++) {
		ArrayGetString(g_szHatsName, iCase, szName, charsmax(szName));
        if(szName[0] != EOS) {
            iIndexPrecache = precache_model(fmt("models/%s.mdl", szName));
            ArrayPushCell(g_iModelsHatsIndex, iIndexPrecache);
        }
        else {
            server_print("%s - Pleasse, Enter Model Name.", PLUGIN_NAME);
            server_print("%s - Pause Plugin.", PLUGIN_NAME);
            pause("d");
        }
	}
}

public ShowMenuHats(pPlayer) {
	new szName[128], szFlags[32], iCase;

	new iMenu = menu_create(fmt("%L", LANG_PLAYER, "HMENU_TITLE"), "MenuHandler");
	menu_additem(iMenu, fmt("%L", LANG_PLAYER, "HMENU_REMOVE"), "CmdRemove");
	
	for(iCase = 0; iCase < ArraySize(g_szArrayItemName); iCase++) {
		ArrayGetString(g_szArrayItemName, iCase, szName, charsmax(szName));
		ArrayGetString(g_szHatsFlag, iCase, szFlags, charsmax(szFlags));

		menu_additem(iMenu, szName, fmt("%i", iCase), read_flags(szFlags));
	}

	UTIL_RegisterMenu(pPlayer, iMenu);
}

public MenuHandler(pPlayer, iMenu, iItem) {
	if(iItem == MENU_EXIT)
		return menu_destroy(iMenu);
	
	new iAccess, szData[64], szName[64];
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), szName, charsmax(szName));
	menu_destroy(iMenu);

	if(equal(szData, "CmdRemove")) {
		if(is_nullent(g_pPlayerData[pPlayer][ENTITY_HAT]))
			client_print_color(pPlayer, print_team_default, "%l %l", "H_TAG", "H_NO_HATS");
		else {
			g_pPlayerData[pPlayer][CURRENT_HAT] = NULLENT;
			set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_flags, FL_KILLME);
			client_print_color(pPlayer, print_team_default, "%l %l", "H_TAG", "H_REMOVE");	
		}
	}
	else {
		g_pPlayerData[pPlayer][CURRENT_HAT] = iItem - 1;
		
		UTIL_SetUserHats(pPlayer);
	}

	return PLUGIN_HANDLED;
}

public UTIL_SetUserHats(pPlayer) {
	if(is_nullent(g_pPlayerData[pPlayer][ENTITY_HAT])) {
		g_pPlayerData[pPlayer][ENTITY_HAT] = rg_create_entity("func_illusionary");

		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_classname, "hat");
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_aiment, pPlayer);
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_owner, pPlayer);
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_movetype, MOVETYPE_FOLLOW);
	}
			
	set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_modelindex, ArrayGetCell(g_iModelsHatsIndex, g_pPlayerData[pPlayer][CURRENT_HAT]));

	new szNameHats[128];
	ArrayGetString(g_szArrayItemName, g_pPlayerData[pPlayer][CURRENT_HAT], szNameHats, charsmax(szNameHats));
	client_print_color(pPlayer, print_team_default, "%l %l", "H_TAG", "H_SET", szNameHats);
}

public Func_ReadFile() {
	g_szArrayItemName = ArrayCreate(128);
	g_szHatsName = ArrayCreate(128);
	g_szHatsFlag = ArrayCreate(32);
	g_iModelsHatsIndex = ArrayCreate(1, 1);

	new szData[256],f;
	formatex(szData, charsmax(szData), "addons/amxmodx/configs/%s", g_szPathFile);

	f = fopen(szData, "r");

	new szItemName[128], szHatsName[128], szFlags[32];
	
	while(!feof(f)) {
		fgets(f, szData, charsmax(szData));
		trim(szData);

		if(szData[0] == EOS || szData[0] == ';' || szData[0] == '/' && szData[1] == '/')
			continue;

		if(szData[0] == '"') {
			parse(szData,
				szItemName, charsmax(szItemName),
				szHatsName, charsmax(szHatsName),
				szFlags, charsmax(szFlags)
			);

			ArrayPushString(g_szArrayItemName, szItemName);
			ArrayPushString(g_szHatsName, szHatsName);
			ArrayPushString(g_szHatsFlag, szFlags);

			continue;
		}

		continue;
	}
	fclose(f);
}