/**
	История изменений:
		1.0 (15.05.2022) by ImmortalAmxx
			- Первый релиз;
		1.1 (22.07.2022) by ImmortalAmxx
			- Переделка кода;

	Благодарности: b0t, 6u3oH.
*/

#include <amxmodx>
#include <reapi_v>

public const PluginName[] = "[ReAPI] Menu: Hats";
public const PluginVersion[] = "1.1";
public const PluginAuthor[] = "Base code: b0t, 6u3oH / Edit: ImmortalAmxx";
public const PluginFile[] = "re_hatsmenu.ini";

enum _:PlayerData {
	CURRENT_HAT,
	ENTITY_HAT
};

enum _:ArrayData {
	ITEM_NAME[64],
	ITEM_MODELNAME[64],
	ITEM_ACCESS[3],
	MODEL_INDEX	
};

new g_pPlayerData[33][PlayerData];

new Array:g_aHatData;

public client_disconnected(pPlayer) {
	if(!is_nullent(g_pPlayerData[pPlayer][ENTITY_HAT])) {
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_flags, FL_KILLME);
		g_pPlayerData[pPlayer][ENTITY_HAT] = NULLENT;
	}
}

public client_putinserver(pPlayer)
	g_pPlayerData[pPlayer][CURRENT_HAT] = NULLENT;

public plugin_init() {
	register_plugin(
		.plugin_name = PluginName, 
		.version = PluginVersion, 
		.author = PluginAuthor
	);
	
	register_dictionary(.filename = "AmxxHats.txt");

	UTIL_RegisterClCmd(.szCmd = "hats", .szFunc = "@ClientCommand_MenuHats");   
}

public plugin_precache() {
	g_aHatData = ArrayCreate(ArrayData);
	
	@ReadFile();
}

@ClientCommand_MenuHats(pPlayer) {
	new aData[ArrayData], iCase;

	new iMenu = menu_create(fmt("%L", LANG_PLAYER, "HMENU_TITLE"), "@MenuHandler");
	menu_additem(iMenu, fmt("%L", LANG_PLAYER, "HMENU_REMOVE"), "CmdRemove");
	
	for(iCase = 0; iCase < ArraySize(g_aHatData); iCase++) {
		ArrayGetArray(g_aHatData, iCase, aData);
		menu_additem(iMenu, aData[ITEM_NAME], fmt("%i", iCase), read_flags(aData[ITEM_ACCESS]));
	}

	UTIL_RegisterMenu(pPlayer, iMenu);
}

@MenuHandler(pPlayer, iMenu, iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, szData[64];
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData));
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
		
		@SetUserHats(pPlayer);
	}

	return PLUGIN_HANDLED;
}

@SetUserHats(pPlayer) {
	new aData[ArrayData];
	ArrayGetArray(g_aHatData, g_pPlayerData[pPlayer][CURRENT_HAT], aData);
	
	if(is_nullent(g_pPlayerData[pPlayer][ENTITY_HAT])) {
		g_pPlayerData[pPlayer][ENTITY_HAT] = rg_create_entity("func_illusionary");

		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_classname, "hat");
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_aiment, pPlayer);
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_owner, pPlayer);
		set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_movetype, MOVETYPE_FOLLOW);
	}

	set_entvar(g_pPlayerData[pPlayer][ENTITY_HAT], var_modelindex, aData[MODEL_INDEX]);

	client_print_color(pPlayer, print_team_default, "%l %l", "H_TAG", "H_SET", aData[ITEM_NAME]);
}

@ReadFile() {
    new szData[256], f, aData[ArrayData];
    formatex(szData, charsmax(szData), "addons/amxmodx/configs/%s", PluginFile);

    f = fopen(szData, "r");
    
    while(!feof(f)) {
        fgets(f, szData, charsmax(szData));
        trim(szData);

        if(szData[0] == EOS || szData[0] == ';' || szData[0] == '/' && szData[1] == '/')
            continue;

        if(szData[0] == '"') {
            parse(szData,
                aData[ITEM_NAME], charsmax(aData),
                aData[ITEM_MODELNAME], charsmax(aData),
                aData[ITEM_ACCESS], charsmax(aData)
            );

            if(file_exists(fmt("models/%s.mdl", aData[ITEM_MODELNAME])))
                aData[MODEL_INDEX] = precache_model(fmt("models/%s.mdl", aData[ITEM_MODELNAME]));
            else {
                server_print("%s - Bad load model: models/%s.mdl", PluginName, aData[ITEM_MODELNAME]);
                server_print("%s - Plugin paused.", PluginName);
                
                pause("d");
                break;
            }

            ArrayPushArray(g_aHatData, aData);
        }
        else
            continue;
    }
    fclose(f);
}
