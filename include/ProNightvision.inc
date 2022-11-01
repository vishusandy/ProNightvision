#if defined _pro_nightvision_included
    #endinput
#endif
#define _pro_nightvision_included

public SharedPlugin __pl_pro_nightvision = 
{
    name = "pro_nightvision",
    file = "ProNightvision.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_pro_nightvision_SetNTVOptional()
{
    MarkNativeAsOptional("ProNightvision_NightvisionMenu");
    MarkNativeAsOptional("ProNightvision_DisplayNightvision");
    MarkNativeAsOptional("ProNightvision_GetFilterId");
    MarkNativeAsOptional("ProNightvision_SetFilter");
    // MarkNativeAsOptional("ProNightvision_SetFilterName");
    MarkNativeAsOptional("ProNightvision_ResetFilter");
    MarkNativeAsOptional("ProNightvision_ListFilters");
}

/**
 * Display the nightvision menu for the client
 * 
 * @param client    The client index
 */
native void ProNightvision_NightvisionMenu(int client);

/**
 * Turns nightvision on or off for the specified client.
 * When turning on, this uses the filter id the player has set.
 * 
 * @param client    Client index
 * @param on        Whether to turn nightvision on or off
 * @return          Returns whether successful or not
 */
native bool ProNightvision_DisplayNightvision(int client, bool on);

/**
 * Returns the filter id for the given filter name
 * 
 * @param name      Filter name
 * @return          Returns the filter id or -1 if the filter was not found.
 */
native int ProNightvision_GetFilterId(const char[] name);

/**
 * Set a nightvision vision for the specified player by filter id.
 * Optionally turns the nightvision on
 * 
 * @param client        Client index
 * @param filter_id     Filter id
 * @param on            Whether to turn the nightvision on
 * @return              Returns if successful or not
 */
native bool ProNightvision_SetFilter(int client, int filter_id, bool on);

/**
 * Reset nightvision to the normal nightvision
 * 
 * @param client    Client index
 * @return          Returns if successful or not
 */
native bool ProNightvision_ResetFilter(int client);

/**
 * Print out a list of the available custom nightvision filters to chat
 * 
 * @param client    Client index
 */
native void ProNightvision_ListFilters(int client);

// native bool ProNightvision_SetFilterName(int client, const char[] name);

// native bool ProNightvision_HasFilterID(int filter_id);
// native int ProNightvision_NumFilters();


