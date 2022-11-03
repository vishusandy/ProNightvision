#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <pro_equip/ProEquip.inc>
#define REQUIRE_PLUGIN

// Based on GAMMA CASE's plugin: http://steamcommunity.com/id/_GAMMACASE_/
public Plugin myinfo = { name = "Pro Nightvision", author = "Vishus", description = "Custom nightivision plugin", version = "0.1.0", url = "" };

#define INTENSITY_INCREMENT 0.2
#define MAX_LINE_LEN 106
#define NV_MENU_TIME 20

#define NV_OFF -1
#define NV_NORMAL 0

bool late_loaded = false;
bool equip_loaded = false;
Database db;
StringMap filter_names;

// https://developer.valvesoftware.com/wiki/Color_Correction
// https://developer.valvesoftware.com/wiki/Color_correction_(entity)

enum struct CCFilter {
    int id;
    char name[64];
    char file[PLATFORM_MAX_PATH];
}

methodmap CCList < ArrayList {
    public CCList(int size) {
        return view_as<CCList>(new ArrayList(size));
    }
    public bool name(int filter_index, char[] buffer, int size) {
        CCFilter filter;
        if(filter_index < 0 || this.GetArray(filter_index, filter) == 0) {
            return false;
        }
        strcopy(buffer, size, filter.name);
        return true;
    }
    public bool file(int filter_index, char[] buffer, int size) {
        CCFilter filter;
        if(filter_index < 0 || this.GetArray(filter_index, filter) == 0) {
            return false;
        }
        strcopy(buffer, size, filter.file);
        return true;
    }
    public bool get(int filter_index, CCFilter filter) {
        if(filter_index < 0 || this.GetArray(filter_index, filter) == 0) {
            return false;
        }
        return true;
    }
}

CCList filter_list;



int entities[MAXPLAYERS][2];

enum struct PlayerCC {
    bool on;
    bool light;
    int filter_id;
    float intensity;
    
    void reset() {
        this.on = false;
        this.light = false;
        this.filter_id = NV_NORMAL;
        this.intensity = 1.0;
    }
    void debug(int client) {
        LogAction(-1, -1, "%N nv: on=%i light=%i filter_id=%i intensity=%.2f", client, this.on, this.light, this.filter_id, this.intensity);
    }
}

PlayerCC player_cc[MAXPLAYERS];


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    late_loaded = late;
    RegPluginLibrary("pro_nightvision");
    CreateNative("ProNightvision_NightvisionMenu", Native_NightvisionMenu);
    CreateNative("ProNightvision_DisplayNightvision", Native_DisplayNightvision);
    CreateNative("ProNightvision_GetFilterId", Native_GetFilterId);
    CreateNative("ProNightvision_SetFilter", Native_SetFilter);
    CreateNative("ProNightvision_ResetFilter", Native_ResetFilter);
    CreateNative("ProNightvision_ListFilters", Native_ListFilters);
}

public void OnPluginStart() {
    filter_names = new StringMap();
    Database.Connect(DbConnCallback, "pro_nightvision");
    filter_list = new CCList(sizeof(CCFilter));
    HookEvent("player_spawn", EventPlayerSpawn);
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_connect", EventPlayerConnect);
    RegConsoleCmd("nv", NightvisionCommand);
    RegConsoleCmd("nightvision", NightvisionCommand);
    for(int i; i < sizeof(entities); i++) {
        entities[i][0] = INVALID_ENT_REFERENCE;
        entities[i][1] = INVALID_ENT_REFERENCE;
    }
    if(late_loaded) {
        for(int i=1; i < MaxClients; i++) {
            player_cc[i].reset();
        }
    }
}

public void OnPluginEnd() {
    for(int i=1; i < MaxClients; i++) {
        int ent = EntRefToEntIndex(entities[i][0]);
        if(ent > 0 && IsValidEntity(ent)) {
            remove_cc(i);
        }
        ent = EntRefToEntIndex(entities[i][1]);
        if(ent > 0 && IsValidEntity(ent)) {
            remove_light(i);
        }
    }
    delete db;
}

public void OnAllPluginsLoaded() {
    equip_loaded = LibraryExists("pro_equip");
}

public void OnLibraryRemoved(const char[] name) {
    if(StrEqual(name, "pro_equip")) {
        equip_loaded = false;
    }
}

public void OnLibraryAdded(const char[] name) {
    if(StrEqual(name, "pro_equip")) {
        equip_loaded = true;
    }
}

public Action EventPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsFakeClient(client)) {
        return;
    }
    CreateTimer(0.2, TimerDelayedNightvision, client);
}

public Action EventPlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    remove_light(client);
    remove_cc(client);
}

public Action EventPlayerConnect(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    player_cc[client].reset();
}

public void OnClientDisconnect(int client) {
    if(IsFakeClient(client)) {
        return;
    }
    player_cc[client].reset();
    remove_cc(client);
}

public void DbConnCallback(Database database, const char[] error, any data) {
    if(strlen(error) > 0) {
        LogAction(-1, -1, "Skipping custom filters.  Database not connected: %s", error);
        return;
    }
    db = database;
    LoadFilters();
}

public void LoadFilters() {
    char query[] = "SELECT id, name, file FROM pro_nightvision ORDER BY ordering, id";
    db.Query(LoadFiltersCallback, query);
}

public void LoadFiltersCallback(Database d, DBResultSet result, const char[] error, any data) {
    if(strlen(error) > 0) {
        LogAction(-1, -1, "LoadFilters error: %s", error);
        return;
    }
    if(result == null) {
        return;
    }
    filter_list.Clear();
    while(result.FetchRow()) {
        CCFilter cur_filter;
        cur_filter.id = result.FetchInt(0);
        result.FetchString(1, cur_filter.name, 64);
        result.FetchString(2, cur_filter.file, PLATFORM_MAX_PATH);
        filter_list.PushArray(cur_filter);
        AddFileToDownloadsTable(cur_filter.file);
        StringToLower(cur_filter.name);
        filter_names.SetValue(cur_filter.name, filter_list.Length-1);
    }
    LogAction(-1, -1, "Nightvision: loaded %i filters", filter_list.Length);
}







// ensure each player can only see their own nightvision light
public Action CCTransmitHook(int entity, int client) {
    SetEdictFlags(entity, GetEdictFlags(entity) & ~FL_EDICT_ALWAYS);
    if(EntRefToEntIndex(entities[client][0]) != entity) {
        return Plugin_Handled;
    }
    SetEdictFlags(entity, GetEdictFlags(entity) | FL_EDICT_DONTSEND);
    return Plugin_Continue;
}

public Action LightTransmitHook(int entity, int client) {
    if(EntRefToEntIndex(entities[client][1]) != entity) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action NightvisionCommand(int client, int args) {
    if(IsFakeClient(client)) {
        return Plugin_Continue;
    }
    if(args == 0) {
        player_cc[client].on = !player_cc[client].on;
        CreateTimer(0.1, TimerDelayedNightvision, client);
        display_main_menu(client, args);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public bool custom_nightvision(int client) {
    remove_cc(client);
    if(player_cc[client].filter_id > NV_NORMAL) {
        if(IsFakeClient(client)) {
            return false;
        }
        normal_nightvision(client, false);
        if(player_cc[client].on) {
            return create_cc(client, player_cc[client].filter_id-1);
        }
    } else if (player_cc[client].filter_id == NV_NORMAL) {
        return normal_nightvision(client, player_cc[client].on);
    }
    return false;
}

bool normal_nightvision(int client, bool on) {
    if(on) {
        SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1);
        create_light(client);
    } else {
         SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
         remove_light(client);
    }
    return true;
}

bool create_light(int client) {
    if(!player_cc[client].light) {
        return false;
    }
    float pos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    pos[0] += 0;
    int ent = CreateEntityByName("light_dynamic");
    SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);
    DispatchKeyValue(ent, "inner_cone", "0");
    DispatchKeyValueFloat(ent, "spotlight_radius", 90.0);
    DispatchKeyValue(ent, "brightness", "1");
    DispatchKeyValue(ent, "_light", "0 255 0 5000");
    DispatchKeyValueFloat(ent, "distance", 200.0);
    float angles[3];
    GetClientAbsAngles(client, angles);
    TeleportEntity(ent, pos, angles, NULL_VECTOR);
    DispatchSpawn(ent);
    AcceptEntityInput(ent, "TurnOn");
    SetVariantString("!activator");
    AcceptEntityInput(ent, "SetParent", client);
    SetEdictFlags(ent, GetEdictFlags(ent) & ~FL_EDICT_ALWAYS);
    SDKHook(ent, SDKHook_SetTransmit, LightTransmitHook);
    entities[client][1] = EntIndexToEntRef(ent);
    return true;
}
void remove_light(int client) {
    if(entities[client][1] == INVALID_ENT_REFERENCE) {
        return;
    }
    int ent = EntRefToEntIndex(entities[client][1]);
    if(ent <= 0 || !IsValidEntity(ent)) {
        return;
    }
    SDKUnhook(ent, SDKHook_SetTransmit, LightTransmitHook);
    RemoveEntity(ent);
    entities[client][1] = INVALID_ENT_REFERENCE;
}

bool create_cc(int client, int filter_index) {
    CCFilter filter;
    if(filter_index < 0 || filter_index >= filter_list.Length || filter_list.GetArray(filter_index, filter) == 0) {
        LogAction(-1, -1, "Cannot create cc for %N", client);
        return false;
    }
    int ent = CreateEntityByName("color_correction");
    if(ent == -1) {
        LogAction(-1, -1, "Failed to create entity for %N", client);
        return false;
    }
    DispatchKeyValue(ent, "StartDisabled", "0");
    DispatchKeyValue(ent, "maxweight", "1.0");
    DispatchKeyValue(ent, "maxfalloff", "-1.0");
    DispatchKeyValue(ent, "minfalloff", "0.0");
    DispatchKeyValue(ent, "filename", filter.file);
    
    DispatchSpawn(ent);
    ActivateEntity(ent);
    
    SetEntPropFloat(ent, Prop_Send, "m_flCurWeight", player_cc[client].intensity);
    SetEdictFlags(ent, GetEdictFlags(ent) & ~FL_EDICT_ALWAYS);
    SDKHook(ent, SDKHook_SetTransmit, CCTransmitHook);
    entities[client][0] = EntIndexToEntRef(ent);
    create_light(client);
    return true;
}

void remove_cc(int client) {
    remove_light(client);
    if(entities[client][0] == INVALID_ENT_REFERENCE) {
        return;
    }
    int ent = EntRefToEntIndex(entities[client][0]);
    if(ent <= 0 || !IsValidEntity(ent)) {
        return;
    }
    SDKUnhook(ent, SDKHook_SetTransmit, CCTransmitHook);
    RemoveEntity(ent);
    entities[client][0] = INVALID_ENT_REFERENCE;
}











public Action display_main_menu(int client, int args) {
    if(!IsClientInGame(client) || IsFakeClient(client)) {
        return;
    }
    char filter_buff[64+8];
    filter_buff = "Filter: ";
    char intensity[32];
    FormatEx(intensity, sizeof(intensity)-11, "Intensity: %.2f", player_cc[client].intensity);
    Menu main_menu = new Menu(menu_handler_main, MENU_ACTIONS_DEFAULT);
    main_menu.ExitButton = true;
    main_menu.ExitBackButton = true;
    main_menu.SetTitle("Nightvision");
    
    switch(player_cc[client].filter_id) {
        case NV_OFF: {
            strcopy(filter_buff[8], sizeof(filter_buff)-8, "None");
        }
        case NV_NORMAL: {
            strcopy(filter_buff[8], sizeof(filter_buff)-8, "Normal");
        }
        default: {
            filter_list.name(player_cc[client].filter_id-1, filter_buff[8], sizeof(filter_buff)-8);
        }
    }
    int intensity_style = (player_cc[client].filter_id <= NV_NORMAL)? ITEMDRAW_DISABLED: ITEMDRAW_DEFAULT;
    if(player_cc[client].on) {
        main_menu.AddItem("on", "Nightvision: On");
    } else {
        main_menu.AddItem("on", "Nightvision: Off");
    }
    main_menu.AddItem("filter", filter_buff);
    main_menu.AddItem("", "", ITEMDRAW_SPACER);
    main_menu.AddItem("intensity", intensity, ITEMDRAW_DISABLED);
    main_menu.AddItem("int_incr", "  Increase intensity", (player_cc[client].intensity >= 1.0)? ITEMDRAW_DISABLED: intensity_style);
    main_menu.AddItem("int_decr", "  Decrease intensity", (player_cc[client].intensity <= 0.0)? ITEMDRAW_DISABLED: intensity_style);
    main_menu.AddItem("light", (player_cc[client].light)? "Light: On": "Light: Off");
    
    main_menu.Display(client, NV_MENU_TIME);
}

public int menu_handler_main(Menu menu, MenuAction action, int client, int param) {
    switch(action) {
        case MenuAction_End: {
            delete menu;
        }
        case MenuAction_Cancel: {
            if(param == MenuCancel_ExitBack && equip_loaded) {
                ProEquip_DisplayMainMenu(client);
            }
        }
        case MenuAction_Select: {
            char buff[16];
            menu.GetItem(param, buff, sizeof(buff));
            if(StrEqual(buff, "on")) {
                player_cc[client].on = !player_cc[client].on;
                custom_nightvision(client);
            } else if(StrEqual(buff, "int_incr")) {
                player_cc[client].intensity = clamp(player_cc[client].intensity + INTENSITY_INCREMENT);
                update_intensity(client);
            } else if(StrEqual(buff, "int_decr")) {
                player_cc[client].intensity = clamp(player_cc[client].intensity - INTENSITY_INCREMENT);
                update_intensity(client);
            } else if(StrEqual(buff, "filter")) {
                player_cc[client].filter_id++;
                if(player_cc[client].filter_id > filter_list.Length) {
                    player_cc[client].filter_id = NV_NORMAL;
                }
                custom_nightvision(client);
            } else if(StrEqual(buff, "light")) {
                player_cc[client].light = !player_cc[client].light;
                if(player_cc[client].on) {
                    remove_light(client);
                    create_light(client);
                }
            }
            display_main_menu(client, 0);
        }
    }
}


public float clamp(float val) {
    return (val > 1.0)? 1.0: (val < 0.0)? 0.0: val;
}

bool update_intensity(int client) {
    int ent = EntRefToEntIndex(entities[client][0]);
    if(ent > 0 && IsValidEntity(ent)) {
        SetEntPropFloat(ent, Prop_Send, "m_flCurWeight", player_cc[client].intensity);
        SetEdictFlags(ent, GetEdictFlags(ent) & ~FL_EDICT_ALWAYS & ~FL_EDICT_DONTSEND);
        return true;
    }
    return false;
}



public Action TimerDelayedNightvision(Handle timer, int client) {
    custom_nightvision(client);
}






public int Native_NightvisionMenu(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    display_main_menu(client, 0);
}

public int Native_DisplayNightvision(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    bool on = GetNativeCell(2);
    player_cc[client].on = on;
    return custom_nightvision(client);
}
public int Native_SetFilter(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    int filter_id = GetNativeCell(2);
    bool on = GetNativeCell(3);
    
    if(filter_id < 0 || filter_id > filter_list.Length) {
        return false;
    }
    
    player_cc[client].filter_id = filter_id;
    if(on) {
        player_cc[client].on = true;
    }
    if(player_cc[client].on) {
        return custom_nightvision(client);
    }
    return true;
}

public int find_filter_id(const char[] name) {
    
    if(strlen(name) == 0 || StrEqual(name, "normal", false) || StrEqual(name, "on", false)) {
        return NV_NORMAL;
    }
    
    int filter_index = -1;
    if(!filter_names.GetValue(name, filter_index) || filter_index < 0 || filter_index >= filter_list.Length) {
        return -1;
    }
    return filter_index + 1;
}

public int Native_GetFilterId(Handle plugin, int numParams) {
    int len;
    GetNativeStringLength(1, len);
    char[] name = new char[len+1];
    if(len <= 0) {
        strcopy(name, len+1, "normal\0");
    } else {
        GetNativeString(1, name, len+1);
        StringToLower(name);
    }
    return find_filter_id(name);
}

public int Native_ResetFilter(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    player_cc[client].filter_id = NV_NORMAL;
}
public int Native_ListFilters(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    char buffer[MAX_LINE_LEN+4];
    buffer = "  Normal, ";
    int line_len = strlen(buffer);
    int item_len = 0;
    
    ReplyToCommand(client, "\x07ffffffFilters:\x01");
    
    // list filters, appending each filter to the line and not exceeding MAX_LINE_LEN
    // print the line when full or at the end of the list
    for(int i=0; i < filter_list.Length; i++) {
        CCFilter cur_filter;
        filter_list.GetArray(i, cur_filter);
        item_len = strlen(cur_filter.name);
        
        if(line_len + item_len + 2 < MAX_LINE_LEN) { // ensure enough room for these two chars: ", "
            if(i != 0) {
                StrCat(buffer, sizeof(buffer), ", ");
                line_len += 2;
            }
        } else {
            ReplyToCommand(client, "%s", buffer);
            buffer = "  ";
            line_len = strlen(buffer);
        }
        StrCat(buffer, sizeof(buffer), cur_filter.name);
        line_len += item_len;
    }
    ReplyToCommand(client, "%s", buffer);
}


void StringToLower(char[] string) {
    int len = strlen(string);
    for(int i=0; i < len; i++) {
        string[i] = CharToLower(string[i]);
    }
}







