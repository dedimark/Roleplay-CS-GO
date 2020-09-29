/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://vr-hosting.fr - benitalpa1020@gmail.com
*/

//*********************************************************************
//*                       CORE MAIN NATIVES                           *
//*********************************************************************

/**
 * @brief Get a client integer value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The integer variable(SEE int_user_data enum).
 **/
native int rp_GetClientInt(int client, int_user_data prop);

/**
 * @brief Get a client boolean value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The boolean variable(SEE bool_user_data enum).
 **/
native bool rp_GetClientBool(int client, bool_user_data prop);

/**
 * @brief Get a client float value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The float variable(SEE float_user_data enum).
 **/
native any rp_GetClientFloat(int client, float_user_data prop);

/**
 * @brief Get a client string value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The string variable(SEE sz_user_data enum).
 * @param value             Buffer to store value of the variable.
 * @param maxlen            Maximum length of buffer where the variable is stored.
 **/
native void rp_GetClientString(int client, sz_user_data prop, const char[] value, int maxlen);

/**
 * @brief Get a client gang string value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The integer variable(SEE enum_group_data enum).
 * @param value             Buffer to store value of the variable.
 * @param maxlen            Maximum length of buffer where the variable is stored.
 **/
native void rp_GetGroupString(int groupID, enum_group_data prop, const char[] value, int maxlen);

/**
 * @brief Set a client integer value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The integer variable(SEE int_user_data enum).
 * @param value             The value to set to the variable(INTEGER).
 **/
native void rp_SetClientInt(int client, int_user_data prop, int value);

/**
 * @brief Set a client boolean value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The boolean variable(SEE bool_user_data enum).
 * @param value             The value to set to the variable(BOOLEAN).
 **/
native void rp_SetClientBool(int client, bool_user_data prop, bool value);

/**
 * @brief Set a client float value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The float variable(SEE float_user_data enum).
 * @param value             The value to set to the variable(FLOAT).
 **/
native any rp_SetClientFloat(int client, float_user_data prop, float value);

/**
 * @brief Set a client string value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The string variable(SEE sz_user_data enum).
 * @param value             The value to store in the selected variable.
 * @param maxlen            Maximum length of the value.
 **/
native void rp_SetClientString(int client, sz_user_data prop, const char[] value, int length);

/**
 * @brief Set a client gang string value
 *
 * @param client            The client index(INTEGER).
 * @param prop              The string variable(SEE enum_group_data enum).
 * @param value             The value to store in the selected variable.
 * @param maxlen            Maximum length of the value.
 **/
native void rp_SetGroupString(int groupID, enum_group_data prop, const char[] value, int length);

/**
 * @brief Set a weapon ammunition type
 *
 * @param wepID             The weapon index(INTEGER).
 * @param typeID            The ball type variable(SEE enum_ball_type enum).
 **/
native void rp_SetWeaponBallType(int wepID, enum_ball_type typeID);

/**
 * @brief Get a weapon ammunition type
 *
 * @param wepID             The weapon index(INTEGER).
 **/
native enum_ball_type rp_GetWeaponBallType(int wepID);

/**
 * @brief Set a item total value available
 *
 * @param prop              The item variable.
 * @param value             The total value to set to the item indexed(SEE stock_item_builded enum).
 **/
native int rp_SetStock(stock_item_builded prop, int value);

/**
 * @brief Get a item total value available
 *
 * @param prop              The item variable(SEE enum_ball_type enum).
 **/
native int rp_GetStock(stock_item_builded prop);


/**
 * @brief Set event type
 *
 * @param typeID             The item variable(SEE enum_event_type enum).
 **/
native void rp_SetEventType(enum_event_type typeID);

/**
 * @brief Get event type
 **/
native enum_event_type rp_GetEventType();

/**
 * @brief Get event type
 *
 * @param &hndl              The handle to close
 **/
native bool rp_CloseHandle(Handle &hndl);

/**
 * @brief Get licence of the server
 * @return true if licence is valid or false if licence is invalid.
 **/
native bool rp_licensing_isValid();

/**
 * @brief Give Salary to everyone
 *
 **/
native int rp_GiveSalaire();

/**
 * @brief Get a job capital money amount
 *
 * @param jobID             The jobID index(SEE jobs.cfg in /configs/).
 **/
native int rp_GetJobCapital(int jobID);			

/**
 * @brief Set a job capital money amount
 *
 * @param jobID             The jobID index(SEE jobs.cfg in /configs/).
 * @param amount            The amount to set.
 **/
native int rp_SetJobCapital(int jobID, int amount);

/**
 * @brief Loads zones timer for a client.
 *
 * @param client             The index client(INTEGER).
 **/
native void rp_GetZoneName(int client);

/**
 * @brief Get a item from the indexed client.
 *
 * @param client             The client index(INTEGER).
 * @param prop               The item variable(SEE item_list enum).
 **
native int rp_GetClientItem(int client, item_list prop);*/

/**
 * @brief Set a item from the indexed client.
 *
 * @param client             The client index(INTEGER).
 * @param prop               The item variable(SEE item_list enum).
 * @param prop               The value to set(INTEGER).
 *
native int rp_ClientGiveItem(int client, item_list prop, int value);*/

native void rp_GetItemData(int itemID, rp_item_type typeID, char[] str, int length);
native void rp_SetItemData(int itemID, rp_item_type typeID, char[] str, int length);

native int rp_GetClientItem(int client, int itemID);				/* Combien fois un joueur possède un certain item? MAX 300. */
native void rp_ClientGiveItem(int client, int itemID, int amount=1); 	/* Donne un item à un joueur. La valeur peut être négative */

/**
 * @brief Send the indexed client to the default job spawn.
 *
 * @param client             The client index(INTEGER).
 **/
native int rp_ClientSendToSpawn(int client);

/**
 * @brief Init the murder event.
 *
 **/
native int rp_InitMurder();

/**
 * @brief Shutdown the murder event.
 *
 **/
native void rp_ShutDownMurder();

/**
 * @brief Load minimap stored in SQL database
 * 
 * @param eventtype			The event name(SEE rp_event_minimap plugin)
 **/
native int rp_InitEventMinimap(char[] eventtype);

/**
 * @brief Get the actualy job perquisition
 * 
 **/
native int rp_GetJobPerqui();

/**
 * @brief Set the actualy job perquisition
 * 
 * @param jobID				The jobID(INTEGER | SEE jobs.cfg in /configs/).
 **/
native int rp_SetJobPerqui(int jobID);

/**
 * @brief Check if the job zone can be perquisitioned
 * 
 * @param jobID				The jobID(INTEGER | SEE jobs.cfg in /configs/).
 **/
native bool rp_CanPerquisition(int jobID);

/**
 * @brief Set job on perquisition to false or true
 * 
 * @param jobID				The jobID(INTEGER | SEE jobs.cfg in /configs/).
 **/
native bool rp_SetPerquisitionStat(int jobID, bool value);

/**
 * @brief Set perquisition max time before end
 * 
 * @param delay				The time delay(INTEGER)
 **/
native bool rp_SetPerquisitionTime(int delay);

/**
 * @brief Get perquisition max time before end
 * 
 * @param delay				The time delay(INTEGER)
 **/
native bool rp_GetPerquisitionTime();

/**
 * @brief Get a job note
 * 
 * @param jobID				The jobID(INTEGER | SEE jobs.cfg in /configs/).
 * @param value             Buffer to store value of the variable.
 * @param maxlen            Maximum length of buffer where the variable is stored.
 **/
native void rp_GetJobNote(int jobID, const char[] value, int maxlen);

/**
 * @brief Set a job note
 * 
 * @param jobID				The jobID(INTEGER | SEE jobs.cfg in /configs/).
 * @param value             Buffer to set value of the variable.
 * @param maxlen            Maximum length of buffer where the variable is stored.
 **/
native void rp_SetJobNote(int jobID, const char[] value, int maxlen);

/**
 * @brief Get a vehicle data
 *
 * @param vehicle           The vehicle index(INTEGER).
 * @param prop              The integer variable(SEE int_user_data enum).
 **/
//native int rp_GetVehicleInt(int vehicle, int vehicleStruct[sizeof(vehicle_data)]); TODO
native int rp_GetVehicleInt(int vehicle, vehicle_data data);

/**
 * @brief Set a vehicle data
 *
 * @param vehicle           The vehicle index(INTEGER).
 * @param prop              The integer variable(SEE int_user_data enum).
 * @param value             The integer value to set.
 **/
native int rp_SetVehicleInt(int vehicle, vehicle_data prop, int value);

/**
 * @brief Get a vehicle float data
 *
 * @param vehicle           The vehicle index(INTEGER).
 * @param prop              The float variable(SEE vehicle_data enum).
 **/
//native int rp_GetVehicleInt(int vehicle, int vehicleStruct[sizeof(vehicle_data)]); TODO
native float rp_GetVehicleFloat(int vehicle, vehicle_data data);

/**
 * @brief Set a vehicle float data
 *
 * @param vehicle           The vehicle index(INTEGER).
 * @param prop              The float variable(SEE vehicle_data enum).
 * @param value             The integer value to set.
 **/
native float rp_SetVehicleFloat(int vehicle, vehicle_data prop, float value);

/**
 * @brief Get the database Handle
 *
 **/
native Database rp_GetDatabase();

/**
 * @brief Get a time data
 *
 * @param prop              The integer variable(SEE time_data enum).
 **/
native int rp_GetTime(time_data prop);

/**
 * @brief Set a time data
 *
 * @param prop              The integer variable(SEE time_data enum).
 * @param value             The integer value to set.
 **/
native void rp_SetTime(time_data prop, int value);

/**
 * @brief Get a appartement data
 *
 * @param appid             The AppartementID(integer).
 * @param prop              The integer variable(SEE appart_data enum).
 **/
native int rp_GetAppartementInt(int appid, appart_data prop);

/**
 * @brief Set a appartement data
 *
 * @param appid             The AppartementID(integer).
 * @param prop              The integer variable(SEE appart_data enum).
 * @param value             The integer value to set.
 **/
native void rp_SetAppartementInt(int appid, appart_data prop, int value);

/**
 * @brief Get clients appartements key access
 *
 * @param appid             The AppartementID(integer).
 * @param prop              The integer variable(SEE appart_data enum).
 **/
native bool rp_GetClientKeyAppartement(int client, int appid);

/**
 * @brief Set a appartement key access
 *
 * @param client            The indexed client(integer).
 * @param appid             The appartement id(integer).
 * @param value             The boolean value to set.
 **/
native bool rp_SetClientKeyAppartement(int client, int appid, bool value);

/**
 * @brief Get client vehicle key access
 *
 * @param appid             The AppartementID(integer).
 * @param prop              The integer variable(SEE appart_data enum).
 **/
native bool rp_GetClientKeyVehicle(int client, int entcar);

/**
 * @brief Set client vehicle key access
 *
 * @param appid             The AppartementID(integer).
 * @param prop              The integer variable(SEE appart_data enum).
 * @param value             The integer value to set.
 **/
native bool rp_SetClientKeyVehicle(int client, int entcar, bool value);

/**
 * @brief Check if client can use the specific itemid
 *
 * @param client            The indexed client(integer).
 * @param itemID            The integer itemID(see item_list enum or items.cfg file)
 **/
native bool rp_GetCanUseItem(int client, int itemID);

/**
 * @brief Check if client can use the specific itemid
 *
 * @param client            The indexed client(integer).
 * @param prop              The integer itemID(see item_list enum or items.cfg file)
 * @param value             The boolean value to set if client can use the specified itemID.
 **/
native bool rp_SetCanUseItem(int client, int itemID, bool value);

/**
 * @brief Check if client item its already on reset delay  timer
 *
 * @param client            The indexed client(integer).
 * @param prop              The integer itemID(see item_list enum or items.cfg file)
 * @param value             The boolean value to set if client can use the specified itemID.
 **/
native bool rp_SetClientDelayItemStat(int client, int itemID, bool value);

native void rp_GetPhoneData(int client, rp_phone_type typeID, char[] str, int length);
native void rp_SetPhoneData(int client, rp_phone_type typeID, char[] str, int length);