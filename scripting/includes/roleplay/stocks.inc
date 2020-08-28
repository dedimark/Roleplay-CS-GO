/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.revolution-team.be - benitalpa1020@gmail.com
*/

//*********************************************************************
//*                       CORE MAIN STOCKS                            *
//*********************************************************************

stock bool rp_ClientCanDrawMenu(int client)
{
	if(!rp_GetClientBool(client, b_menuOpen))
		return true;
	else
		return false;
}	

stock void NoCommandAcces(int client)
{
	if(IsClientValid(client))
	{
		char translate[64];
		Format(STRING(translate), "%T", "Command_NoAcces", LANG_SERVER);
		CPrintToChat(client, "%s %s", TEAM, translate);
	}	
}	

stock void GameCheck()
{
	EngineVersion g_Game;
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}	
	
	//PluginRequirements();
}

stock void PluginRequirements()
{
	if(!LibraryExists("rp_nativeregister"))
		SetFailState("Plugin: rp_nativeregister nécessaire");
	else if(!LibraryExists("rp_licence"))
		SetFailState("Plugin: rp_licence nécessaire");	
	else if(!LibraryExists("rp_globalforwards"))
		SetFailState("Plugin: rp_nativeregister nécessaire");	
}		

stock bool IsClientValid(int client = -1, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}

stock float Distance(int client, int target)
{
	float origin1[3], origin2[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin1);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin2);
	return GetVectorDistance(origin1, origin2);
}

stock int EmitCashSound(int client, int value)
{
	if(IsClientValid(client))
	{
		if(value < 0)
			PrintCenterText(client, "-%i$", value);			
		else
			PrintCenterText(client, "+%i$", value);			
		PrecacheSound("roleplay/cash.mp3");
		EmitSoundToClient(client, "roleplay/cash.mp3", client, _, _, _, 1.0);
	}
}	
 
stock void TrashTimer(Handle & hTimer, bool bIsRepeat = false) 
{
	if (hTimer != null) 
	{
		if (bIsRepeat) 
			KillTimer(hTimer);
		else 
			delete hTimer;
		hTimer = null;
	}
}

stock int GetAimEnt(int client, bool type = false, bool wall = true)
{
	int ent = GetClientAimTarget(client, type);
	if(wall && LookAtWall(client))
		return -1;
	return ent;
}

stock bool LookAtWall(int client)
{
	float angles[3], origin[3], anglesVec[3], endOrigin[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, origin);
	GetAngleVectors(angles, anglesVec, NULL_VECTOR, NULL_VECTOR);
	
	endOrigin[0] = origin[0] + (anglesVec[0] * 100000.0);
	endOrigin[1] = origin[1] + (anglesVec[1] * 100000.0);
	endOrigin[2] = origin[2] + (anglesVec[2] * 100000.0);
	
	Handle trace = TR_TraceRayFilterEx(origin, endOrigin, MASK_SHOT, RayType_EndPoint, RayDontHitClient, client);
	if(TR_DidHit(trace))
	{
		int ent = TR_GetEntityIndex(trace);
		CloseHandle(trace);
		if(ent == 0)
			return true;
		else
			return false;
	}
	CloseHandle(trace);
	return true;
}

stock bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}	

stock bool RayDontHitClient(int entity, int contentsMask, any data)
{
	return entity != data;
}

stock int StringTime(int temps, char[] strFormat, int maxLen)
{
	int jours = temps / 60 / 60 / 24;
	int heures = temps / 60 / 60 / 60;
	int minutes = temps / 60 / 60 / 60 / 60;
	
	if(jours == 0)
	{
		if(heures == 0)
		{
			Format(strFormat, maxLen, "%i Minutes", minutes);	
		}	
		else
		{
			Format(strFormat, maxLen, "%i Heures %i Minutes", heures, minutes);	
		}	
	}	
	else
	{
		if(heures == 0)
		{
			Format(strFormat, maxLen, "%i Minutes", minutes);		
		}	
		else
		{
			Format(strFormat, maxLen, "%i Jours %i Heures %i Minutes", jours, heures, minutes);	
		}
	}	
}

stock int IsBenito(int client)
{
	char SteamId[64];
	GetClientAuthId(client, AuthId_Steam2, STRING(SteamId));
	
	if (StrEqual(SteamId, "STEAM_1:1:512215951"))
		return true;
	else
		return false;
}

stock void rp_ShowOverlay(int client, char[] path, float lifetime)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
		return;

	ClientCommand(client, "r_screenoverlay \"%s.vtf\"", path);

	if (lifetime != 0.0)
		CreateTimer(lifetime, rp_DeleteOverlay, GetClientUserId(client));
}

stock void rp_ShowOverlayAll(char[] path, float lifetime)
{
	LoopClients(i)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i) || IsClientReplay(i))
			continue;

		ClientCommand(i, "r_screenoverlay \"%s.vtf\"", path);

		if (lifetime != 0.0)
			CreateTimer(lifetime, rp_DeleteOverlay, GetClientUserId(i));
	}
}

stock Action rp_DeleteOverlay(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
		return;

	ClientCommand(client, "r_screenoverlay \"\"");
}

stock void rp_SetLogFile(char LogFile[PLATFORM_MAX_PATH], char[] FolderName, char[] FileName)
{
	char sDate[12];
	FormatTime(STRING(sDate), "%y-%m-%d");
	Format(STRING(LogFile), "logs/%s/%s-%s.log", FolderName, FileName, sDate);

	BuildPath(Path_SM, STRING(LogFile), LogFile);
}

stock void rp_SetClientAmmo(int client, int weaponEnt, int clip = -1, int ammo = -1)
{
	if (weaponEnt == INVALID_ENT_REFERENCE)
		return;

	if (clip != -1)
	{
		SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);		
	}	

	if (ammo != -1)
	{
		SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);		
	}	
}

stock Action rp_SetDefaultClientColor(int client) 
{
	if (IsClientValid(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

stock int ScreenFade(int client, int duration, int color[4])
{
	if(IsClientValid(client) && !rp_GetClientBool(client, b_isBlind))
	{
		int clients[2];
		clients[0] = client;
		Handle message = StartMessage("Fade", clients, 1);
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration * 1000);
		pb.SetInt("hold_time", 1);
		pb.SetInt("flags", 0);
		pb.SetColor("clr", color);
		EndMessage();
	}
}

stock int Handler_NullCancel(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select) 
	{
		switch (param2) 
		{
			default: // cancel
			{
				return;
			}
		}
	}

	return;
}

stock int GetAdminRankName(int adminRank, char[] rankName, int maxLen)
{
	switch(adminRank)
	{
		case 1:strcopy(rankName, maxLen, "Fondateur");
		case 2:strcopy(rankName, maxLen, "Staff");
		case 3:strcopy(rankName, maxLen, "Admin");
		case 4:strcopy(rankName, maxLen, "Membre");
		default:strcopy(rankName, maxLen, "Joueur");
	}
}

stock int GetGroupeName(Database db, int client, char[] groupename, int maxLen)
{
	char buff[256], clientgroupe[64];
	Format(STRING(buff), "SELECT groupename FROM rp_groupes WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(db, buff);
	
	if(query)
	{
		while (query.FetchRow())
		{
			query.FetchString(0, STRING(clientgroupe));
			strcopy(groupename, maxLen, clientgroupe);
		}	
	}
	delete query;
}

stock void rp_SetSkin(int client, char[] model)
{
	PrecacheModel(model);
	SetEntityModel(client, model);
}	

stock void rp_SetArms(int client, char[] arms)
{
	PrecacheModel(arms);
	SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
}

stock void rp_SetWeaponSkin(int client, char[] weapon, char[] v_model, char[] w_model, char[] drop_model)
{
	int view = PrecacheModel(v_model, true);
	int world = PrecacheModel(w_model, true);
	
	FPVMI_AddViewModelToClient(client, weapon, view);
	FPVMI_AddWorldModelToClient(client, weapon, world);
	FPVMI_AddDropModelToClient(client, weapon, drop_model);
}	

stock int PerformListeJoueur(Menu menu, int client, bool admin = false, bool alive = true, bool moi = false)
{
	char strMenu[64], strFormat[64];
	if(admin)
	{
		if(moi && alive && IsPlayerAlive(client)
		|| moi & !alive)
			menu.AddItem("@moi", "Moi");
		menu.AddItem("@civil", "Tous les civils");
		menu.AddItem("@police", "Toutes les forces de l'ordre");
		menu.AddItem("@tous", "Tout le monde");
	}
	for(int i = 1 ; i <= MaxClients ; i++)
	{
		if(IsClientValid(i))
		{
			GetClientName(i, STRING(strFormat));
			if(alive && !IsPlayerAlive(i))
			{
				Format(STRING(strMenu), "%s [mort]", strFormat);
				menu.AddItem("", strMenu, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(STRING(strMenu), "%i", i);
				if(!moi || moi && client != i)
					menu.AddItem(strMenu, strFormat);
			}
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

stock int PerformRaison(Menu menu, int client, char[] commande)
{
	char strFormat[128];
	Format(STRING(strFormat), "%s Non respect du règlement.", commande);
	menu.AddItem(strFormat, "Non respect du règlement.");
	Format(STRING(strFormat), "%s Pas de fairplay.", commande);
	menu.AddItem(strFormat, "Pas de fairplay.");
	Format(STRING(strFormat), "%s Manque de respect.", commande);
	menu.AddItem(strFormat, "Manque de respect.");
	Format(STRING(strFormat), "%s Insultes..", commande);
	menu.AddItem(strFormat, "Insultes.");
	Format(STRING(strFormat), "%s Racisme.", commande);
	menu.AddItem(strFormat, "Racisme.");
	Format(STRING(strFormat), "%s Abus.", commande);
	menu.AddItem(strFormat, "Abus.");
	Format(STRING(strFormat), "%s Utilise un bug.", commande);
	menu.AddItem(strFormat, "Utilise un bug.");
	Format(STRING(strFormat), "%s Flood.", commande);
	menu.AddItem(strFormat, "Flood.");
	menu.AddItem("", ">> Autre raison :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Utiliser la commande pour écrire une raison.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Aucune raison.");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

stock int PointVision(int client, float position[3])
{
	float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		delete trace;
		return;
	}
	delete trace;
}

stock int UnloadPlugin()
{
	char namePlugin[256];
	Handle plugin = GetMyHandle();
	GetPluginFilename(plugin, STRING(namePlugin));
	ServerCommand("sm plugins unload %s", namePlugin);
	PrintToServer("> Licence Invalide!!! <");
	SetFailState("Licence Invalide");
}

stock int IsADMIN(int client)
{
	if(client == 0 || rp_GetClientInt(client, i_AdminLevel) == 1 || rp_GetClientInt(client, i_AdminLevel) == 2 || rp_GetClientInt(client, i_AdminLevel) == 3)
		return true;
	else
		return false;
}

stock int FindJoueur(int client, char[] arg, bool alive = false)
{
	int joueur[MAXPLAYERS + 1];
	if(StrContains(arg, "@") != -1)
	{
		if(!StrEqual(arg, "@moi")
		&& !StrEqual(arg, "@cible")
		&& !StrEqual(arg, "@police")
		&& !StrEqual(arg, "@civil")
		&& !StrEqual(arg, "@tous")
		&& !StrEqual(arg, "@vie")
		&& !StrEqual(arg, "@mort"))
		{
			if(client > 0)
				CPrintToChat(client, "%s Vous devez écrire un {yellow}pseudo\x01/{yellow}Steam ID\x01 ou un filtre de recherche {yellow}@moi @cible @civil @police @tous @vie @mort\x01.", TEAM);
			else
				PrintToServer("[ADMIN] Vous devez ecrire un pseudo/Steam ID ou un filtre de recherche @moi @cible @civil @police @tous @vie @mort.");
			joueur[0] = -1;
			return joueur;
		}
	}
	
	if(StrEqual(arg, "@moi") || StrEqual(arg, "@cible"))
	{
		if(client == 0)
		{
			PrintToServer("[ADMIN] Vous ne pouvez pas utiliser @moi et @cible avec la console.");
			joueur[0] = -1;
			return joueur;
		}
		
		if(!alive || alive && IsPlayerAlive(client))
		{
			if(StrEqual(arg, "@moi"))
				joueur[client] = client;
			else if(StrEqual(arg, "@cible"))
			{
				int aim = GetClientAimTarget(client, true);
				if(IsValidEntity(aim))
					joueur[aim] = aim;
				else
				{
					CPrintToChat(client, "%s Aucun joueur détecté sur votre viseur.", TEAM);
					joueur[0] = -1;
				}
			}
		}
		else
		{
			CPrintToChat(client, "%s Impossible étant mort.", TEAM);
			joueur[0] = -1;
		}
	}
	else if(StrEqual(arg, "@mort") && alive)
	{
		if(client > 0)
			CPrintToChat(client, "%s Vous ne pouvez pas chercher les joueurs morts.", TEAM);
		else
			PrintToServer("[ADMIN] Vous ne pouvez pas chercher les joueurs morts.");
		joueur[0] = -1;
	}
	else if(StrContains(arg, "STEAM_") != -1)
	{
		int target = Client_FindBySteamId(arg);
		if(target != -1)
			joueur[target] = target;
		else
		{
			if(client > 0)
				CPrintToChat(client, "%s Le Steam ID est invalide.", TEAM);
			else
				PrintToServer("[ADMIN] Le Steam ID est invalide.");
		}
	}
	else
	{
		int count, result;
		char name[32];
		LoopClients(i)
		{
			GetClientName(i, STRING(name));
			if(StrEqual(arg, "@police") && GetClientTeam(i) == CS_TEAM_CT
			|| StrEqual(arg, "@civil") && GetClientTeam(i) == CS_TEAM_T
			|| StrEqual(arg, "@tous")
			|| StrEqual(arg, "@vie") && IsPlayerAlive(i)
			|| StrEqual(arg, "@mort") && !IsPlayerAlive(i))
			{
				if(!alive || alive && IsPlayerAlive(i))
				{
					joueur[i] = i;
					count++;
				}
			}
			else if(StrContains(name, arg, false) != -1)
			{
				if(!alive || alive && IsPlayerAlive(i))
				{
					joueur[i] = i;
					result++;
				}
				else
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N\x01 est mort.", TEAM, i);
					else
						PrintToServer("[ADMIN] %N est mort.", i);
					joueur[0] = -1;
				}
			}
			else if(result > 1)
			{
				CPrintToChat(client, "%s Plusieurs joueurs correspondent à la recherche '%s', réessayez.", TEAM, arg);
				joueur[0] = -1;
				break;
			}
			else
				joueur[i] = -1;
		}
		if(joueur[0] == -1 || count == 0 && result == 0)
		{
			joueur[0] = -1;
			CPrintToChat(client, "%s Aucun joueur ne correspond à la recherche '%s'.", TEAM, arg);
		}
	}
	
	return joueur;
}

stock int GetWeaponEntClass(char[] arg, char strEnt[64])
{
	if(StrContains(arg, "p2000", false) != -1 || StrContains(arg, "hkp2000", false) != -1)
		strEnt = "weapon_hkp2000";
	else if(StrContains(arg, "usp", false) != -1)
		strEnt = "weapon_usp_silencer";
	else if(StrContains(arg, "tec", false) != -1)
		strEnt = "weapon_tec9";
	else if(StrContains(arg, "glock", false) != -1)
		strEnt = "weapon_glock";
	else if(StrContains(arg, "p250", false) != -1)
		strEnt = "weapon_p250";
	else if(StrContains(arg, "desert", false) != -1 || StrContains(arg, "eagle", false) != -1)
		strEnt = "weapon_deagle";
	else if(StrContains(arg, "five", false) != -1 || StrContains(arg, "seven", false) != -1)
		strEnt = "weapon_fiveseven";
	else if(StrContains(arg, "elite", false) != -1 || StrContains(arg, "dual", false) != -1 || StrContains(arg, "berettas", false) != -1)
		strEnt = "weapon_elite";
	else if(StrContains(arg, "cz75", false) != -1)
		strEnt = "weapon_cz75a";
	else if(StrContains(arg, "mac", false) != -1)
		strEnt = "weapon_mac10";
	else if(StrContains(arg, "mp9", false) != -1)
		strEnt = "weapon_mp9";
	else if(StrContains(arg, "pp", false) != -1 || StrContains(arg, "bizon", false) != -1)
		strEnt = "weapon_bizon";
	else if(StrContains(arg, "ump", false) != -1)
		strEnt = "weapon_ump45";
	else if(StrContains(arg, "mp7", false) != -1)
		strEnt = "weapon_mp7";
	else if(StrContains(arg, "p90", false) != -1)
		strEnt = "weapon_p90";
	else if(StrContains(arg, "sawed", false) != -1)
		strEnt = "weapon_sawedoff";
	else if(StrContains(arg, "nova", false) != -1)
		strEnt = "weapon_nova";
	else if(StrContains(arg, "mag", false) != -1)
		strEnt = "weapon_mag7";
	else if(StrContains(arg, "xm1014", false) != -1)
		strEnt = "weapon_xm1014";
	else if(StrContains(arg, "galil", false) != -1)
		strEnt = "weapon_galilar";
	else if(StrContains(arg, "famas", false) != -1)
		strEnt = "weapon_famas";
	else if(StrContains(arg, "ak", false) != -1)
		strEnt = "weapon_ak47";
	else if(StrContains(arg, "m4a4", false) != -1)
		strEnt = "weapon_m4a1_silencer";
	else if(StrContains(arg, "aug", false) != -1 || StrContains(arg, "steayr", false) != -1)
		strEnt = "weapon_aug";
	else if(StrContains(arg, "sg556", false) != -1)
		strEnt = "weapon_sg556";
	else if(StrContains(arg, "m249", false) != -1 || StrContains(arg, "batteuse", false) != -1)
		strEnt = "weapon_m249";
	else if(StrContains(arg, "negev", false) != -1)
		strEnt = "weapon_negev";
	else if(StrContains(arg, "ssg08", false) != -1)
		strEnt = "weapon_ssg08";
	else if(StrContains(arg, "awp", false) != -1)
		strEnt = "weapon_awp";
	else if(StrContains(arg, "scar", false) != -1)
		strEnt = "weapon_scar20";
	else if(StrContains(arg, "g3sg1", false) != -1 || StrContains(arg, "g3sg/1", false) != -1)
		strEnt = "weapon_g3sg1";
	else if(StrContains(arg, "m4a1", false) != -1)
		strEnt = "weapon_m4a1";
	else if(StrContains(arg, "grenade", false) != -1 || StrContains(arg, "he", false) != -1)
		strEnt = "weapon_hegrenade";
	else if(StrContains(arg, "gss", false) != -1 || StrContains(arg, "flash", false) != -1)
		strEnt = "weapon_flashbang";
	else if(StrContains(arg, "smoke", false) != -1 || StrContains(arg, "fumi", false) != -1)
		strEnt = "weapon_smokegrenade";
	else if(StrContains(arg, "incendi", false) != -1)
		strEnt = "weapon_incgrenade";
	else if(StrContains(arg, "molotov", false) != -1 || StrContains(arg, "cocktail", false) != -1)
		strEnt = "weapon_molotov";
	else if(StrContains(arg, "decoy", false) != -1 || StrContains(arg, "leurre", false) != -1)
		strEnt = "weapon_decoy";
	else if(StrContains(arg, "breach", false) != -1 || StrContains(arg, "charge", false) != -1 || StrContains(arg, "c4", false) != -1)
		strEnt = "weapon_breachcharge";	
	else if(StrContains(arg, "mine", false) != -1 || StrContains(arg, "mines", false) != -1 || StrContains(arg, "bump", false) != -1)
		strEnt = "weapon_bumpmine";	
	else if(StrContains(arg, "shield", false) != -1 || StrContains(arg, "bouclier", false) != -1)
		strEnt = "weapon_shield";		
	else if(StrContains(arg, "parachute", false) != -1)
		strEnt = "prop_weapon_upgrade_chute";	
	else if(StrContains(arg, "propulseur", false) != -1 || StrContains(arg, "jumper", false) != -1)
		strEnt = "prop_weapon_upgrade_exojump";	
	else if(StrContains(arg, "munitions", false) != -1 || StrContains(arg, "ammo", false) != -1)
		strEnt = "prop_ammo_box_generic";
	else if(StrContains(arg, "coffre", false) != -1 || StrContains(arg, "fort", false) != -1)
		strEnt = "func_survival_c4_target";		
	else if(StrContains(arg, "mitrailleuse", false) != -1 || StrContains(arg, "dronegun", false) != -1)
		strEnt = "dronegun";
	else if(StrContains(arg, "healthshot", false) != -1 || StrContains(arg, "seringue", false) != -1)
		strEnt = "weapon_healthshot";	
	else if(StrContains(arg, "casque", false) != -1)
		strEnt = "prop_weapon_upgrade_helmet";
	else if(StrContains(arg, "veste", false) != -1 || StrContains(arg, "kevlar", false) != -1)
		strEnt = "prop_weapon_upgrade_armor";
	else if(StrContains(arg, "armure", false) != -1 || StrContains(arg, "lourde", false) != -1)
		strEnt = "prop_weapon_refill_heavyarmor";	
	else
		strEnt = "erreur";
}

stock int GetWeaponEntName(char[] arg, char strName[32])
{
	if(StrEqual(arg, "weapon_hkp2000"))
		strName = "P2000";
	else if(StrEqual(arg, "weapon_usp_silencer"))
		strName = "USP-S";
	else if(StrEqual(arg, "weapon_tec9"))
		strName = "Tec-9";
	else if(StrEqual(arg, "weapon_glock"))
		strName = "Glock-18";
	else if(StrEqual(arg, "weapon_p250"))
		strName = "P250";
	else if(StrEqual(arg, "weapon_deagle"))
		strName = "Desert Eagle";
	else if(StrEqual(arg, "weapon_fiveseven"))
		strName = "Five-Seven";
	else if(StrEqual(arg, "weapon_elite"))
		strName = "Dual Berettas";
	else if(StrEqual(arg, "weapon_cz75a"))
		strName = "CZ75-Auto";
	else if(StrEqual(arg, "weapon_mac10"))
		strName = "MAC-10";
	else if(StrEqual(arg, "weapon_mp9"))
		strName = "MP9";
	else if(StrEqual(arg, "weapon_bizon"))
		strName = "PP-Bizon";
	else if(StrEqual(arg, "weapon_ump45"))
		strName = "UMP-45";
	else if(StrEqual(arg, "weapon_mp7"))
		strName = "MP7";
	else if(StrEqual(arg, "weapon_p90"))
		strName = "P90";
	else if(StrEqual(arg, "weapon_sawedoff"))
		strName = "Sawed-Off";
	else if(StrEqual(arg, "weapon_nova"))
		strName = "Nova";
	else if(StrEqual(arg, "weapon_mag7"))
		strName = "Mag-7";
	else if(StrEqual(arg, "weapon_xm1014"))
		strName = "XM1014";
	else if(StrEqual(arg, "weapon_galilar"))
		strName = "Galil AR";
	else if(StrEqual(arg, "weapon_famas"))
		strName = "FAMAS";
	else if(StrEqual(arg, "weapon_ak47"))
		strName = "AK-47";
	else if(StrEqual(arg, "weapon_m4a1"))
		strName = "M4A4";
	else if(StrEqual(arg, "weapon_aug"))
		strName = "Steayr AUG";
	else if(StrEqual(arg, "weapon_sg556"))
		strName = "SG 553";
	else if(StrEqual(arg, "weapon_m249"))
		strName = "M249";
	else if(StrEqual(arg, "weapon_negev"))
		strName = "Negev";
	else if(StrEqual(arg, "weapon_ssg08"))
		strName = "SSG 08";
	else if(StrEqual(arg, "weapon_awp"))
		strName = "AWP";
	else if(StrEqual(arg, "weapon_scar20"))
		strName = "SCAR-20";
	else if(StrEqual(arg, "weapon_g3sg1"))
		strName = "G3SG/1";
	else if(StrEqual(arg, "weapon_m4a1_silencer"))
		strName = "Maverick M4A1 Carbine";
	else if(StrEqual(arg, "weapon_hegrenade"))
		strName = "Grenade à fragmentation";
	else if(StrEqual(arg, "weapon_flashbang"))
		strName = "Grenade flash (GSS)";
	else if(StrEqual(arg, "weapon_smokegrenade"))
		strName = "Grenade fumigène";
	else if(StrEqual(arg, "weapon_incgrenade"))
		strName = "Grenade incendiaire";
	else if(StrEqual(arg, "weapon_molotov"))
		strName = "Cocktail Molotov";
	else if(StrEqual(arg, "weapon_decoy"))
		strName = "Grenade leurre";
	else if(StrEqual(arg, "weapon_bumpmine"))
		strName = "Mines propulsives";
	else if(StrEqual(arg, "weapon_breachcharge"))
		strName = "C4 Détonateur";	
	else if(StrEqual(arg, "weapon_shield"))
		strName = "Bouclier";	
	else if(StrEqual(arg, "prop_weapon_upgrade_chute"))
		strName = "Parachute";	
	else if(StrEqual(arg, "prop_weapon_upgrade_exojump"))
		strName = "Propulseur";	
	else if(StrEqual(arg, "prop_ammo_box_generic"))
		strName = "Recharge de munitions";
	else if(StrEqual(arg, "func_survival_c4_target"))
		strName = "Coffre Fort munit d'explosive";		
	else if(StrEqual(arg, "dronegun"))
		strName = "Tourrele";
	else if(StrEqual(arg, "weapon_healthshot"))
		strName = "Seringue";	
	else if(StrEqual(arg, "prop_weapon_upgrade_helmet"))
		strName = "Casque";
	else if(StrEqual(arg, "prop_weapon_upgrade_armor"))
		strName = "Kevlar";
	else if(StrEqual(arg, "prop_weapon_refill_heavyarmor"))
		strName = "Armure Lourde";	
	else
		strName = "erreur";
}

stock int rp_ClientTeleport(int client, float pos[3])
{
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}	

stock int rp_CreateFire(float position[3], float time)
{
	int ent = CreateEntityByName("env_fire");
	DispatchSpawn(ent);
	DispatchKeyValue(ent, "fireattack", "10");
	DispatchKeyValueFloat(ent, "damagescale", 2.0);
	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "StartFire");
	CreateTimer(time, DeleteEnt, ent);
}

stock Action DeleteEnt(Handle timer, any ent)
{
	if(IsValidEdict(ent))
		RemoveEdict(ent);
}

stock int DisolveEntity(int ent)
{
	if(IsValidEntity(ent))
	{
		char entName[64], strType[32], entClass[32], entModel[64];
		Format(STRING(entName),"dis_%d", ent);
		Format(STRING(strType), "%d", 100);
		
		Entity_GetClassName(ent, STRING(entClass));
		Entity_GetModel(ent, STRING(entModel));
		
		if(StrEqual(entClass, "weapon_knife")
		|| StrEqual(entModel, "models/props_interiors/printer.mdl"))
		{
			int dissolver = CreateEntityByName("env_entity_dissolver");
			DispatchKeyValue(ent, "targetname", entName);
			
			DispatchKeyValue(dissolver, "dissolvetype", strType);
			DispatchKeyValue(dissolver, "target", entName);
			AcceptEntityInput(dissolver, "Dissolve");
			AcceptEntityInput(dissolver, "kill");
		}
	}
}

stock void LoadingBar(char[] str, int length, float percent) {
    int full = RoundToFloor(percent * 100);
    int left = full % 10;
    full = (full - left) / 10;
    for(int i=0; i<full; i++)
        Format(str, length, "%s█", str);

    if(left > 0){
        if(left > 7)
            Format(str, length, "%s▓", str);
        else if(left > 4)
            Format(str, length, "%s░", str);
        else if(left > 1)
            Format(str, length, "%s▒", str);
    }
}

stock int rp_DeleteWeapon(int client, int weapon)
{
	if(IsClientValid(client))
	{
		if(IsValidEntity(weapon) && weapon > 0)
		{
			RemovePlayerItem(client, weapon);
			if(IsValidEntity(weapon))
				AcceptEntityInput(weapon, "Kill");
			
			int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", knife);
			ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
		}
	}
}

stock int rp_DeleteAllWeapon(int client)
{
	if(IsClientValid(client))
	{
		int knife;
		while((knife = GetPlayerWeaponSlot(rp_GetEventParticipants(), CS_SLOT_KNIFE)) != -1)
		{
			RemovePlayerItem(rp_GetEventParticipants(), knife);
			AcceptEntityInput(knife, "Kill");
		}
		
		int primary;
		while((primary = GetPlayerWeaponSlot(rp_GetEventParticipants(), CS_SLOT_PRIMARY)) != -1)
		{
			RemovePlayerItem(rp_GetEventParticipants(), primary);
			AcceptEntityInput(primary, "Kill");
		}
		
		int secondary;
		while((secondary = GetPlayerWeaponSlot(rp_GetEventParticipants(), CS_SLOT_SECONDARY)) != -1)
		{
			RemovePlayerItem(rp_GetEventParticipants(), secondary);
			AcceptEntityInput(secondary, "Kill");
		}
	}
}

stock int rp_GetPrice(char[] itemID)
{
	KeyValues kv = new KeyValues("Prix");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/prix.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/prix.cfg : NOT FOUND");
	}	
	
	if(kv.JumpToKey(itemID))
		return kv.GetNum("prix");
	else
		delete kv;	
	
	return -1;
}

stock int rp_GetAppartementPrice(Database db, char[] appartName)
{
	char buffer[1024];	
	Format(STRING(buffer), "SELECT prix FROM rp_appartements WHERE appartement = '%s';", appartName);
	DBResultSet query = SQL_Query(db, buffer);
	
	int prix = 999999999;
	if(query != null)
	{
		if(query.FetchRow())
			prix = query.FetchInt(0);
	}
	delete query;
	
	return prix;
}

stock int rp_GetAppartementOwner(Database db, char[] appartName)
{
	char buffer[1024];	
	Format(STRING(buffer), "SELECT proprietaire FROM rp_appartements WHERE appartement = '%s';", appartName);
	DBResultSet query = SQL_Query(db, buffer);
	
	char owner[64];
	int client;
	
	if(query != null)
	{
		if(query.FetchRow())
		{
			query.FetchString(0, STRING(owner));
			if(!StrEqual(owner, "none"))
				client = Client_FindBySteamId(owner);
			else
				client = -1;
		}	
	}
		
	delete query;
	
	return client;
}

stock int rp_SetEntityNameByHammerID(int hammerID, char[] entName)
{
	int ent = Entity_FindByHammerId(hammerID);
	Entity_SetName(ent, entName);
}	

stock int rp_SetupRingPoint(int client, int target)
{
	int modelLaser = PrecacheModel("sprites/laserbeam.vmt", true);
	int modelHalo = PrecacheModel("sprites/halo.vmt", true);
	
	float origin[3];
	GetClientAbsOrigin(target, origin);
	origin[2] += 5.0;
			
	TE_SetupBeamRingPoint(origin, 20.0, 200.0, modelLaser, modelHalo, 0, 1, 0.5, 8.0, 1.0, {20, 128, 20, 255}, 1, 0);
	TE_SendToAll();
}	

stock bool rp_canSetAmmo(int client, int weapon)
{
	char weaponName[64];
	Entity_GetClassName(weapon, STRING(weaponName));
	
	if(StrContains(weaponName, "knife") == -1
	&& StrContains(weaponName, "grenade") == -1
	&& StrContains(weaponName, "he") == -1
	&& StrContains(weaponName, "flashbang") == -1
	&& StrContains(weaponName, "gss") == -1
	&& StrContains(weaponName, "smoke") == -1
	&& StrContains(weaponName, "decoy") == -1
	&& StrContains(weaponName, "molotov") == -1
	&& StrContains(weaponName, "shield") == -1
	&& StrContains(weaponName, "fists") == -1
	&& StrContains(weaponName, "axe") == -1
	&& StrContains(weaponName, "hammer") == -1
	&& StrContains(weaponName, "spanner") == -1)
		return true;
	else
		return false;
}	

stock int rp_CreateParticle(float position[3], char[] particleName, float time)
{
	int ent = CreateEntityByName("info_particle_system");
	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(ent, "effect_name", particleName);
	DispatchKeyValue(ent, "targetname", "particle");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "start");
	CreateTimer(time, DeleteEnt, ent);
}

stock int IsVIP(int client)
{
	if(rp_GetClientInt(client, i_VipTime) != 0)
		return true;
	else
		return false;
}

stock int ADMIN_LEVEL_1(int client)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
		return true;
	else
		return false;
}

stock int ADMIN_LEVEL_2(int client)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 2)
		return true;
	else
		return false;
}

stock int ADMIN_LEVEL_3(int client)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 3)
		return true;
	else
		return false;
}

stock bool isApartmentOwner(int client)
{
	char entName[128];	
	int aim = GetAimEnt(client, false);
	Entity_GetName(aim, STRING(entName));
	
	// buffer[0] = nom de l'appartement
	// buffer[1] = steamID propriétaire
	// buffer[2] = Nom de l'appartement
	char buffer[3][128];
	ExplodeString(entName, "|", buffer, 3, 128);		

	if(rp_GetClientInt(client, i_appartement) == 18 && StrEqual(buffer[0], "appart_18"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 17 && StrEqual(buffer[0], "appart_17"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 15 && StrEqual(buffer[0], "appart_15"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 16 && StrEqual(buffer[0], "appart_16"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 31 && StrEqual(buffer[0], "appart_31"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 32 && StrEqual(buffer[0], "appart_32"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 33 && StrEqual(buffer[0], "appart_33"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 34 && StrEqual(buffer[0], "appart_34"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 35 && StrEqual(buffer[0], "appart_35"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 41 && StrEqual(buffer[0], "appart_41"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 42 && StrEqual(buffer[0], "appart_42"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 43 && StrEqual(buffer[0], "appart_43"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 44 && StrEqual(buffer[0], "appart_44"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 13 && StrEqual(buffer[0], "appart_13"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 14 && StrEqual(buffer[0], "appart_14"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 11 && StrEqual(buffer[0], "appart_11"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 12 && StrEqual(buffer[0], "appart_12"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 38 && StrEqual(buffer[0], "appart_38"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 37 && StrEqual(buffer[0], "appart_37"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 36 && StrEqual(buffer[0], "appart_36"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 46 && StrEqual(buffer[0], "appart_46"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 45 && StrEqual(buffer[0], "appart_45"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 48 && StrEqual(buffer[0], "appart_48"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 47 && StrEqual(buffer[0], "appart_47"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 21 && StrEqual(buffer[0], "appart_21"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 22 && StrEqual(buffer[0], "appart_22"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 24 && StrEqual(buffer[0], "appart_24"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 23 && StrEqual(buffer[0], "appart_23"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 27 && StrEqual(buffer[0], "appart_27"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 28 && StrEqual(buffer[0], "appart_28"))
		return true;
	else if(rp_GetClientInt(client, i_appartement) == 25 && StrEqual(buffer[0], "appart_25"))
		return true;	
	else if(rp_GetClientInt(client, i_appartement) == 26 && StrEqual(buffer[0], "appart_26"))
		return true;	
	else
		return false;
}	

stock int rp_GetEventNombreParticipant()
{
	int participants;
	LoopClients(i)
	{
		if(rp_GetClientBool(i, b_isEventParticipant))
			participants++;
	}
	
	return participants;
}

stock int rp_GetEventParticipants()
{
	LoopClients(i)
	{
		if(rp_GetClientBool(i, b_isEventParticipant))
			return i;	
	}	
	
	return -1;
}

stock int GetRandomParticipant()
{
	int[] clients = new int[rp_GetEventParticipants()];
	int clientCount;
	LoopClients(i)
	{
		if(rp_GetClientBool(i, b_isEventParticipant))
		{
			clients[clientCount++] = i;
		}	
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
	
}

stock void CreateZonePoints(float point[9][3], float offset = 0.0)
{
	// calculate all zone edges
	for(int i = 1; i < 7; i++)
	{
		for(int j = 0; j < 3; j++)
		{
			point[i][j] = point[((i >> (2 - j)) & 1) * 7][j];
		}
	}

	// apply beam offset
	if(offset != 0.0)
	{
		float center[2];
		center[0] = ((point[0][0] + point[7][0]) / 2);
		center[1] = ((point[0][1] + point[7][1]) / 2);

		for(int i = 0; i < 8; i++)
		{
			for(int j = 0; j < 2; j++)
			{
				if(point[i][j] < center[j])
				{
					point[i][j] += offset;
				}

				else if(point[i][j] > center[j])
				{
					point[i][j] -= offset;
				}
			}
		}
	}
}

stock bool ZonePeaceFull(int client)
{
	if (rp_GetClientInt(client, i_ByteZone) == 7
	|| rp_GetClientInt(client, i_ByteZone) == 5
	|| rp_GetClientInt(client, i_ByteZone) == 4)
		return true;
	else 
		return false;
}	 
    
stock bool IsInsideBox(float position[3], float Zone_Cords_0[3], float Zone_Cords_1[3])
{
	if(position[0] >= Zone_Cords_0[0] && position[0] <= Zone_Cords_0[1] && position[1] >= Zone_Cords_0[2] && position[1] <= Zone_Cords_1[0] && position[2] >= Zone_Cords_1[1] && position[2] <= Zone_Cords_1[2])
		return true;
	
	return false;
}

stock void rp_SetClientSize(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", value);
}

stock int rp_GetRandomPlayer()
{
	int PlayerList[MAXPLAYERS + 1];
	int PlayerCount;
	
	LoopClients(i)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i))
			continue;
		
		PlayerList[PlayerCount++] = i;
	}
	
	if (PlayerCount == 0)
		return -1;
	
	return PlayerList[GetRandomInt(0, PlayerCount-1)];
}

stock void rp_RemoveWeapon(int client, int slot)
{ 
	int weapon = GetPlayerWeaponSlot(client, slot);
	
	if (weapon != -1)
		AcceptEntityInput(weapon, "Kill");
}

stock int GetParamPolice(bool amende, char[] motif)
{	
	KeyValues kv = new KeyValues("Amendes");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/amendes.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/amendes.cfg : NOT FOUND");
	}	
	
	kv.JumpToKey(motif);
	
	int valeur;
	
	if(amende)
		valeur = kv.GetNum("amende");
	else
		valeur = kv.GetNum("temps");	
	kv.Rewind();	
	delete kv;
	
	return valeur;
}

stock void SetParamPolice(bool amende, char[] motif, int montant)
{
	KeyValues kv = new KeyValues("Amendes");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/amendes.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/amendes.cfg : NOT FOUND");
	}
	
	kv.JumpToKey(motif);
	
	if(amende)
		kv.SetNum("amende", montant);
	else
		kv.SetNum("temps", montant);
	kv.Rewind();	
	delete kv;
}

stock int rp_GetCurrentMap(char map[128])
{
	GetCurrentMap(STRING(map));
	if (StrContains(map, "workshop") != -1) {
		char mapPart[3][64];
		ExplodeString(map, "/", mapPart, 3, 64);
		strcopy(STRING(map), mapPart[2]);
	}
}

stock int TeleportToBytzone(int client, int bytZoneID)
{
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("bytpoint");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/bytpoint.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/bytpoint.cfg NOT FOUND", map);
	}	
	
	char bytstring[32];
	IntToString(bytZoneID, STRING(bytstring));
	if(kv.JumpToKey(bytstring))
	{	
		float position[3];	
		position[0] = kv.GetFloat("pos_x");
		position[1] = kv.GetFloat("pos_y");
		position[2] = kv.GetFloat("pos_z");
		
		TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	}
	else
		CPrintToChat(client, "%s Veuillez contacter le support avec le message suivant: {lightred}BytZone %i introuvable.", TEAM, bytZoneID);
		
	
	kv.Rewind();	
	delete kv;
}

stock void SpawnPropByName(int client = -1, char[] kvName = "", char[] entName = "")
{
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Props");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/props.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/props.cfg NOT FOUND", map);
	}	

	if(kv.JumpToKey(kvName))
	{	
		float position[3];	
		position[0] = kv.GetFloat("pos_x");
		position[1] = kv.GetFloat("pos_y");
		position[2] = kv.GetFloat("pos_z");
		
		char type[32];
		kv.GetString("type", STRING(type));
		
		char model[32];
		kv.GetString("model", STRING(model));
		
		char solid[2];
		kv.GetString("solid", STRING(solid));
		
		PrecacheModel(model);
		int ent = CreateEntityByName(type);
		DispatchKeyValue(ent, "solid", solid);
		DispatchKeyValue(ent, "model", model);
		DispatchSpawn(ent);
		
		if(!StrEqual(entName, ""))
			Entity_SetName(ent, entName);
		
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	}
	else
		CPrintToChat(client, "%s Veuillez contacter le support avec le message suivant: [PROPS]{lightred}%s introuvable.", TEAM, kvName);
		
	
	kv.Rewind();	
	delete kv;
}	