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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAXPOS 10

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
 
							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
Player joueur;
bool canSetZoneName[MAXPLAYERS + 1] = false;
char newZoneName[64];
float zoning[MAXPLAYERS + 1][9][3];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Zones & Byt",
	author = "Benito",
	description = "Système zoning pour le roleplay",
	version = VERSION,
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		RegConsoleCmd("gotopos", Cmd_Dev);
		RegConsoleCmd("printbytzone", Cmd_ByteZoneDisplay);
		RegConsoleCmd("savebytpoint", Cmd_SaveBytPoint);
		RegConsoleCmd("rp_zones", Cmd_Zoning);
	}	
	else
		UnloadPlugin();
}

public void OnClientPostAdminCheck(int client)
{
    joueur = Player(client);
} 

public Action Cmd_ByteZoneDisplay(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	if(joueur.IsValid)	
		CPrintToChat(joueur.index, "%s Bytezone %i", TEAM, joueur.zoneID);
	
	return Plugin_Handled;
}	

public Action Cmd_SaveBytPoint(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if(rp_GetClientInt(client, i_ByteZone) != 0)
		{
			float position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			
			char arg[2];
			IntToString(rp_GetClientInt(client, i_ByteZone), STRING(arg));
			
			char map[128];
			GetCurrentMap(STRING(map));
			if (StrContains(map, "workshop") != -1) 
			{
				char mapPart[3][64];
				ExplodeString(map, "/", mapPart, 3, 64);
				strcopy(STRING(map), mapPart[2]);
			}
				
			KeyValues kv = new KeyValues("bytpoint");
			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/bytpoint.cfg", map);
				
			if(!kv.ImportFromFile(sPath))
			{
				delete kv;
				PrintToServer("configs/roleplay/%s/bytpoint.cfg : NOT FOUND", map);
			}	
				
			kv.JumpToKey(arg);
				
			kv.SetFloat("pos_x", position[0]);
			kv.SetFloat("pos_y", position[1]);
			kv.SetFloat("pos_z", position[2]);
					
			CPrintToChat(client, "%s Le bytPoint %s a été enregistrée sous x:{green}%f{default},y:{green}%f{default},z:{green}%f", TEAM, arg, position[0], position[1], position[2]);	
					
			kv.GoBack();
			kv.ExportToFile(sPath);	
			delete kv;	
		}		
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
	
	return Plugin_Handled;
}	

public Action Cmd_Dev(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	else if(args < 1)
	{
		CPrintToChat(client, "%s Vous devez préciser les points x y z (exemple : /dev 1.0 1.0 1.0).", TEAM);
		return Plugin_Handled;
	}
	
	char arg1[80];
	GetCmdArg(1, STRING(arg1));

	char arg2[80];
	GetCmdArg(2, STRING(arg2));
	
	char arg3[80];
	GetCmdArg(3, STRING(arg3));
	
	float pos[3];
	
	pos[0] = StringToFloat(arg1);
	pos[1] = StringToFloat(arg2);
	pos[2] = StringToFloat(arg3);
	
	TeleportEntity(joueur.index, view_as<float>(pos), NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_GetZoneName", GetZoneName);
}

public int GetZoneName(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(!IsClientValid(client))
		return -1;
		
	GetZones(client);
	
	return -1;
}

public int GetZones(int client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			char map[128];
			rp_GetCurrentMap(map);
			
			if(CheckIfIsInZone(client, "Armurerie"))
			{
				joueur.zoneID = 6;
				joueur.SetZoneName("Armurerie");
			}
			else if(CheckIfIsInZone(client, "Banque"))
			{
				if(CheckIfIsInZone(client, "Coffre_Banque"))
					joueur.zoneID = 111;
				else
					joueur.zoneID = 11;				
				joueur.SetZoneName("Banque");
			}
			else if(CheckIfIsInZone(client, "McDonald's"))
			{
				if(CheckIfIsInZone(client, "McDonalds_Holdup"))
					joueur.zoneID = 155;
				else
					joueur.zoneID = 15;				
				joueur.SetZoneName("McDonald's");
			}
			else if(CheckIfIsInZone(client, "DolceGabanna"))
			{
				if(CheckIfIsInZone(client, "DolceGabanna_Holdup"))
					joueur.zoneID = 144;
				else	
					joueur.zoneID = 14;				
				joueur.SetZoneName("Dolce & Gabbana");
			}
			else if(CheckIfIsInZone(client, "Discothèque"))
			{
				//joueur.zoneID = 8;			
				joueur.SetZoneName("Discothèque");
			}
			else if(CheckIfIsInZone(client, "Casino"))
			{
				joueur.zoneID = 16;				
				joueur.SetZoneName("Casino");
			}
			else if(CheckIfIsInZone(client, "Immo"))
			{
				joueur.zoneID = 8;				
				joueur.SetZoneName("Agence immobilière");
			}
			else if(CheckIfIsInZone(client, "Assassin"))
			{
				joueur.zoneID = 12;				
				joueur.SetZoneName("Planque Tueur");
			}
			else if(CheckIfIsInZone(client, "villaN1"))
			{
				joueur.zoneID = 19;				
				joueur.SetZoneName("Villa № 1");
			}
			else if(CheckIfIsInZone(client, "coach"))
			{
				joueur.zoneID = 17;				
				joueur.SetZoneName("Planque Coach");
			}
			else if(CheckIfIsInZone(client, "hopital"))
			{
				joueur.zoneID = 4;				
				joueur.SetZoneName("Hôpital");
			}	
			else if(CheckIfIsInZone(client, "technicien"))
			{
				joueur.zoneID = 10;				
				joueur.SetZoneName("Planque Technicien");
			}
			else if(CheckIfIsInZone(client, "sexshop"))
			{
				joueur.zoneID = 18;				
				joueur.SetZoneName("Chez Roger");
			}
			else if(CheckIfIsInZone(client, "artificier"))
			{
				joueur.zoneID = 13;				
				joueur.SetZoneName("Planque Artificier");
			}
			else if(CheckIfIsInZone(client, "dealer"))
			{
				joueur.zoneID = 9;				
				joueur.SetZoneName("Planque Dealer");
			}	
			else if(CheckIfIsInZone(client, "carshop"))
			{
				//rp_SetClientInt(client, i_ByteZone, 9);				
				joueur.SetZoneName("CarShop");
			}
			else if(CheckIfIsInZone(client, "mafia"))
			{
				joueur.zoneID = 2;				
				joueur.SetZoneName("Planque Mafia 中国的");
			}	
			else if(CheckIfIsInZone(client, "18th"))	
			{
				joueur.zoneID = 3;				
				joueur.SetZoneName("Planque 18th");
			}	
			else if(CheckIfIsInZone(client, "appartement_hall"))	
			{
				joueur.zoneID = 8;			
				joueur.SetZoneName("Appartement - Hall");
			}
			if(StrEqual(map, "rp_princeton_v2"))
			{
				if(CheckIfIsInZone(client, "appartement_n18"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 18");
				}	
				else if(CheckIfIsInZone(client, "appartement_n17"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 17");
				}	
				else if(CheckIfIsInZone(client, "appartement_n15"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 15");
				}
				else if(CheckIfIsInZone(client, "appartement_n16"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 16");
				}
				else if(CheckIfIsInZone(client, "appartement_n31"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 31");
				}
				else if(CheckIfIsInZone(client, "appartement_n32"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 32");
				}
				else if(CheckIfIsInZone(client, "appartement_n33"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 33");
				}
				else if(CheckIfIsInZone(client, "appartement_n34"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 34");
				}
				else if(CheckIfIsInZone(client, "appartement_n35"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 35");
				}
				else if(CheckIfIsInZone(client, "appartement_n41"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 41");
				}
				else if(CheckIfIsInZone(client, "appartement_n42"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 42");
				}
				else if(CheckIfIsInZone(client, "appartement_n43"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 43");
				}
				else if(CheckIfIsInZone(client, "appartement_n44"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 44");
				}
				else if(CheckIfIsInZone(client, "appartement_n13"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 13");
				}
				else if(CheckIfIsInZone(client, "appartement_n14"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 14");
				}
				else if(CheckIfIsInZone(client, "appartement_n11"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 11");
				}
				else if(CheckIfIsInZone(client, "appartement_n12"))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 12");
				}
				else if(Appartement38(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 38");
				}
				else if(Appartement37(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 37");
				}
				else if(Appartement36(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 36");
				}
				else if(Appartement46(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 46");
				}
				else if(Appartement45(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 45");
				}
				else if(Appartement48(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 48");
				}
				else if(Appartement47(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 47");
				}
				else if(Appartement21(client))
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 21");
				}
				else if(Appartement22(client))
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 22");
				}
				else if(Appartement24(client))
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 24");
				}
				else if(Appartement23(client))
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 23");
				}
				else if(Appartement27(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 27");
				}
				else if(Appartement28(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 28");
				}
				else if(Appartement25(client))
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 25");
				}
				else if(Appartement26(client))	
				{
					joueur.zoneID = 8;			
					joueur.SetZoneName("Appartement № 26");
				}
			}	
			else if(VillaPvP(client))	
			{
				joueur.zoneID = 777;				
				joueur.SetZoneName("Villa P.V.P");
			}
			else if(Tribunal(client))	
			{
				joueur.zoneID = 7;				
				joueur.SetZoneName("Tribunal");
			}
			else if(TourMairie(client))	
			{
				joueur.zoneID = 5;				
				joueur.SetZoneName("Mairie");
			}
			else if(GarageComico(client))	
			{
				joueur.zoneID = 1;				
				joueur.SetZoneName("P.C.P.D - Garage");
			}
			else if(ArmurerieComico(client))	
			{
				joueur.zoneID = 1;				
				joueur.SetZoneName("P.C.P.D - Armurerie");
			}
			else if(HallComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Hall");
			}
			else if(EscalierComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Escalier");
			}
			else if(ParloirComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Parloir");
			}
			else if(JailComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Jail");
			}
			else if(CouloirDeLaCourComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Couloir de la Cour");
			}
			else if(CourComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Cour");
			}
			else if(QHSComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Q.H.S");
			}
			else if(CouloirComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Couloir");
			}
			else if(ArchiveComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Archive");
			}
			else if(ToitComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Toit");
			}
			else if(ConduitComico(client))	
			{
				joueur.zoneID = 1;
				joueur.SetZoneName("P.C.P.D - Conduit");
			}
			else if(ZonePvP(client))	
			{
				joueur.zoneID = 777;				
				joueur.SetZoneName("Zone P.V.P");
			}
			else if(ZonePvpBuster(client))
			{
				joueur.zoneID = 777;				
				joueur.SetZoneName("Tombeau de BusteR");
			}
			else if(ZoneEvent(client))	
			{
				joueur.zoneID = 777;				
				joueur.SetZoneName("Zone Event");
			}
			else if(Metro(client))	
			{
				joueur.zoneID = 0;									
				joueur.SetZoneName("Métro");
			}
			else
			{
				joueur.zoneID = 0;
				joueur.SetZoneName("En Ville");
			}	
		}
		else 
			rp_SetClientInt(client, i_ByteZone, -1);	
	}
}

bool CheckIfIsInZone(int client, char[] kvZone)
{	
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Zones");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/zones.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/zones.cfg : NOT FOUND", map);
	}	
	
	kv.JumpToKey(kvZone);
		
	int points = kv.GetNum("maxpoints");
	
	char point[64];
	
	for(int i = 1; i <= points; i++)
	{
		Format(STRING(point), "%i", i);
		kv.JumpToKey(point);
		float kvPos0[MAXPOS][3];
		float kvPos1[MAXPOS][3];
		kvPos0[i][0] = kv.GetFloat("x");
		kvPos0[i][1] = kv.GetFloat("y");
		kvPos0[i][2] = kv.GetFloat("z");
		kvPos1[i][0] = kv.GetFloat("x²");
		kvPos1[i][1] = kv.GetFloat("y²");
		kvPos1[i][2] = kv.GetFloat("z²");
		kv.GoBack();
	
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		
		if(IsInsideBox(position, kvPos0[i], kvPos1[i]))
		{
			return true;
		}	
	}	
	
	kv.Rewind();	
	delete kv;

	return false;
}

bool Armurerie(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	char map[128];
	rp_GetCurrentMap(map);
	
	if(StrEqual(map, "rp_princeton_v2"))
	{	
		if (position[0] >= -2287.867675 && position[0] <= -1292.867675 && position[1] >= 768.174194 && position[1] <= 1393.174194 && position[2] >= -2140.968750 && position[2] <= -2005.968750
		|| position[0] >= -2287.968750 && position[0] <= -1297.968750 && position[1] >= 526.985229 && position[1] <= 1396.985229 && position[2] >= -1996.955688 && position[2] <= -1861.955688
		|| position[0] >= -2286.053710 && position[0] <= -1291.053588 && position[1] >= 544.077880 && position[1] <= 1029.077880 && position[2] >= -2276.968750 && position[2] <= -2141.968750
		|| position[0] >= -2291.459960 && position[0] <= -1296.460083 && position[1] >= 1030.636108 && position[1] <= 1390.636108 && position[2] >= -2271.968750 && position[2] <= -2136.968750)
			return true;
		else 
			return false;
	}
	else if(StrEqual(map, "rp_vr-city_v1"))
	{
		if (position[0] >= -7028.770507 && position[0] <= -6538.770507 && position[1] >= -6160.052734 && position[1] <= -5475.052734 && position[2] >= 11.031250 && position[2] <= 591.031250
		|| position[0] >= -7029.099121 && position[0] <= -6539.099121 && position[1] >= -5476.968750 && position[1] <= -4791.968750 && position[2] >= 11.381404 && position[2] <= 211.381408)
			return true;
		else 
			return false;
	}
	else
		return false;
}

bool Discotheque(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 3199.968750 && position[0] <= 3884.968750 && position[1] >= -3807.706054 && position[1] <= -3072.706054 && position[2] >= -2007.634887 && position[2] <= -1677.634887
	|| position[0] >= 3407.757812 && position[0] <= 3887.757812 && position[1] >= -3798.968750 && position[1] <= -3078.968750 && position[2] >= -2012.076782 && position[2] <= -1982.076782)
		return true;
	else 
		return false;
}

bool Casino(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2441.452148 && position[0] <= 3191.452148 && position[1] >= -4927.968750 && position[1] <= -4577.968750 && position[2] >= -1960.290771 && position[2] <= -1510.290771
	|| position[0] >= 1791.238525 && position[0] <= 3196.238525 && position[1] >= -5626.649414 && position[1] <= -4931.649414 && position[2] >= -1951.968750 && position[2] <= -1501.968750)
		return true;
	else 
		return false;
}

bool AgenceImmobilier(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1004.685546 && position[0] <= -374.685546 && position[1] >= -3585.427001 && position[1] <= -2755.427001 && position[2] >= -2012.968750 && position[2] <= -1877.968750
	|| position[0] >= -1031.557861 && position[0] <= -376.557861 && position[1] >= -3586.968750 && position[1] <= -2691.968750 && position[2] >= -1863.558105 && position[2] <= -1543.558105)
		return true;
	else 
		return false;
}

bool VillaNumero1(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2304.579101 && position[0] <= -889.579101 && position[1] >= -9303.836914 && position[1] <= -6263.836914 && position[2] >= -2327.968750 && position[2] <= -1482.968750)
		return true;
	else 
		return false;
}

bool Coach(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -5058.003906 && position[0] <= -3588.003906 && position[1] >= 2.546630 && position[1] <= 3067.546630 && position[2] >= -2263.968750 && position[2] <= -1588.968750
	|| position[0] >= -5109.671875 && position[0] <= -5054.671875 && position[1] >= 9.274452 && position[1] <= 504.274444 && position[2] >= -2140.968750 && position[2] <= -2005.968750
	|| position[0] >= -4856.652343 && position[0] <= -3841.652343 && position[1] >= 1279.237304 && position[1] <= 2814.237304 && position[2] >= -2524.968750 && position[2] <= -2269.968750)
		return true;
	else 
		return false;
}

bool Technicien(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -4090.895507 && position[0] <= -3585.895751 && position[1] >= -512.031250 && position[1] <= -7.031250 && position[2] >= -2134.544433 && position[2] <= -1594.544433
	|| position[0] >= -4550.960937 && position[0] <= -3580.960693 && position[1] >= -2045.139404 && position[1] <= -1150.139404 && position[2] >= -2135.968750 && position[2] <= -1590.968750
	|| position[0] >= -4098.968750 && position[0] <= -3583.968750 && position[1] >= -1151.805419 && position[1] <= -511.805419 && position[2] >= -1871.227539 && position[2] <= -1731.227539)
		return true;
	else 
		return false;
}

bool SexShop(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -5233.287109 && position[0] <= -3778.286865 && position[1] >= -5344.969726 && position[1] <= -4449.969726 && position[2] >= -2012.968750 && position[2] <= -1757.968750
	|| position[0] >= -4663.968750 && position[0] <= -3773.968750 && position[1] >= -5599.959472 && position[1] <= -5359.959472 && position[2] >= -1964.923828 && position[2] <= -1759.923828)
		return true;
	else 
		return false;
}

bool Artificier(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -5743.968750 && position[0] <= -3903.968750 && position[1] >= -4091.813476 && position[1] <= -3086.813476 && position[2] >= -2008.234375 && position[2] <= -1873.234375)
		return true;
	else 
		return false;
}		

bool Dealer(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -3590.590087 && position[0] <= -2555.590087 && position[1] >= -5640.166015 && position[1] <= -4090.166015 && position[2] >= -2272.968750 && position[2] <= -1457.968750
	|| position[0] >= -2580.056884 && position[0] <= -2390.056884 && position[1] >= -5607.981445 && position[1] <= -5472.981445 && position[2] >= -1876.968750 && position[2] <= -1696.968750)
		return true;
	else 
		return false;
}	

bool CarShop(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -372.795349 && position[0] <= 392.204650 && position[1] >= -3577.968750 && position[1] <= -2687.968750 && position[2] >= -2201.668701 && position[2] <= -1606.668701)
		return true;
	else 
		return false;
}

bool MafiaJaponaise(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1022.968750 && position[0] <= -127.968750 && position[1] >= 518.305541 && position[1] <= 1023.305541 && position[2] >= -2132.331054 && position[2] <= -1977.331054
	|| position[0] >= -3035.968750 && position[0] <= -920.968750 && position[1] >= 525.419128 && position[1] <= 2350.419189 && position[2] >= -2309.947509 && position[2] <= -2154.947509
	|| position[0] >= -3053.814697 && position[0] <= -2318.814697 && position[1] >= 1683.154785 && position[1] <= 3698.154785 && position[2] >= -2124.968750 && position[2] <= -1974.968750
	|| position[0] >= -2315.344482 && position[0] <= -15.344482 && position[1] >= 2945.439453 && position[1] <= 3695.439453 && position[2] >= -2379.968750 && position[2] <= -1974.968750)
		return true;
	else 
		return false;
}

bool Mafia18th(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1534.644409 && position[0] <= -1294.644409 && position[1] >= -3597.546875 && position[1] <= -2682.546630 && position[2] >= -2012.968750 && position[2] <= -1452.968750
	|| position[0] >= -2555.968750 && position[0] <= -1525.968750 && position[1] >= -3852.505371 && position[1] <= -2682.505371 && position[2] >= -2012.972656 && position[2] <= -1442.972656)
		return true;
	else 
		return false;
}

bool Appartement(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1775.688110 && position[0] <= -1295.688110 && position[1] >= -671.852966 && position[1] <= -161.852966 && position[2] >= -2140.031250 && position[2] <= -1600.031250
	|| position[0] >= -1261.981811 && position[0] <= -771.981811 && position[1] >= -2019.020141 && position[1] <= -1499.020141 && position[2] >= -2004.968750 && position[2] <= -1459.968750
	|| position[0] >= -2911.306396 && position[0] <= -2401.306396 && position[1] >= -1456.031250 && position[1] <= -371.031250 && position[2] >= -2132.357421 && position[2] <= -1597.357421
	|| position[0] >= -2398.925292 && position[0] <= -2303.925292 && position[1] >= -972.482238 && position[1] <= -857.482238 && position[2] >= -2132.968750 && position[2] <= -2022.968750)
		return true;
	else 
		return false;
}

bool Appartement18(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2107.968750 && position[0] <= -1792.968750 && position[1] >= -383.189086 && position[1] <= -143.189102 && position[2] >= -1732.827758 && position[2] <= -1597.827758)
		return true;
	else 
		return false;
}

bool Appartement17(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2332.144287 && position[0] <= -1787.144287 && position[1] >= -683.031250 && position[1] <= -383.031250 && position[2] >= -1731.653564 && position[2] <= -1596.653564)
		return true;
	else 
		return false;
}

bool Appartement15(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2332.614746 && position[0] <= -1787.614746 && position[1] >= -683.686157 && position[1] <= -383.686157 && position[2] >= -1868.968750 && position[2] <= -1733.968750)
		return true;
	else 
		return false;
}

bool Appartement31(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2617.642333 && position[0] <= -1987.642333 && position[1] >= -2026.872436 && position[1] <= -1476.872436 && position[2] >= -2132.968750 && position[2] <= -2002.968750)
		return true;
	else 
		return false;
}

bool Appartement32(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2921.582519 && position[0] <= -2631.582519 && position[1] >= -2012.853637 && position[1] <= -1467.853637 && position[2] >= -2127.968750 && position[2] <= -1997.968750)
		return true;
	else 
		return false;
}

bool Appartement33(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2615.788818 && position[0] <= -1990.788818 && position[1] >= -2021.844482 && position[1] <= -1471.844482 && position[2] >= -1996.968750 && position[2] <= -1866.968750)
		return true;
	else 
		return false;
}

bool Appartement34(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2921.208984 && position[0] <= -2631.208984 && position[1] >= -2010.363403 && position[1] <= -1470.363403 && position[2] >= -1996.968750 && position[2] <= -1866.968750)
		return true;
	else 
		return false;
}

bool Appartement35(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2615.810546 && position[0] <= -1985.810424 && position[1] >= -2018.943969 && position[1] <= -1473.943969 && position[2] >= -1860.968750 && position[2] <= -1730.968750)
		return true;
	else 
		return false;
}

bool Appartement41(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1596.705444 && position[0] <= -1276.705444 && position[1] >= -2027.968750 && position[1] <= -1792.968750 && position[2] >= -2003.400634 && position[2] <= -1868.400634)
		return true;
	else 
		return false;
}

bool Appartement42(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1980.770874 && position[0] <= -1275.770874 && position[1] >= -1787.777465 && position[1] <= -1487.777465 && position[2] >= -2004.968750 && position[2] <= -1864.968750
	|| position[0] >= -1983.145141 && position[0] <= -1603.145141 && position[1] >= -2029.341308 && position[1] <= -1789.341308 && position[2] >= -2004.968750 && position[2] <= -1869.968750)
		return true;
	else 
		return false;
}

bool Appartement43(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1598.004394 && position[0] <= -1263.004394 && position[1] >= -2009.298828 && position[1] <= -1794.298828 && position[2] >= -1868.968750 && position[2] <= -1733.968750)
		return true;
	else 
		return false;
}

bool Appartement44(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1981.737060 && position[0] <= -1276.737060 && position[1] >= -1785.170654 && position[1] <= -1495.170654 && position[2] >= -1868.968750 && position[2] <= -1733.968750
	|| position[0] >= -1980.018676 && position[0] <= -1600.018676 && position[1] >= -2028.040405 && position[1] <= -1788.040405 && position[2] >= -1868.968750 && position[2] <= -1733.968750)
		return true;
	else 
		return false;
}

bool Appartement16(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2107.796875 && position[0] <= -1787.796875 && position[1] >= -378.031250 && position[1] <= -143.031250 && position[2] >= -1867.599731 && position[2] <= -1737.599731)
		return true;
	else 
		return false;
}

bool Appartement13(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2332.224121 && position[0] <= -1787.223999 && position[1] >= -683.163452 && position[1] <= -383.163421 && position[2] >= -2004.968750 && position[2] <= -1869.968750)
		return true;
	else 
		return false;
}

bool Appartement14(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2107.751220 && position[0] <= -1792.751220 && position[1] >= -378.252349 && position[1] <= -143.252349 && position[2] >= -2004.968750 && position[2] <= -1869.968750)
		return true;
	else 
		return false;
}

bool Appartement11(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2332.463867 && position[0] <= -1787.463867 && position[1] >= -688.542297 && position[1] <= -383.542297 && position[2] >= -2140.968750 && position[2] <= -2005.968750)
		return true;
	else 
		return false;
}

bool Appartement12(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2107.968750 && position[0] <= -1777.968750 && position[1] >= -383.263854 && position[1] <= -143.263839 && position[2] >= -2140.112792 && position[2] <= -2005.112792)
		return true;
	else 
		return false;
}

bool Appartement36(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2921.354248 && position[0] <= -2631.354248 && position[1] >= -2008.989379 && position[1] <= -1468.989379 && position[2] >= -1860.968750 && position[2] <= -1725.968750)
		return true;
	else 
		return false;
}

bool Appartement37(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2614.659667 && position[0] <= -1999.659667 && position[1] >= -2027.291259 && position[1] <= -1472.291259 && position[2] >= -1724.968750 && position[2] <= -1599.968750)
		return true;
	else 
		return false;
}

bool Appartement38(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2921.215820 && position[0] <= -2631.215820 && position[1] >= -2013.743408 && position[1] <= -1473.743408 && position[2] >= -1729.968750 && position[2] <= -1604.968750
	|| position[0] >= -2378.517578 && position[0] <= -2118.517578 && position[1] >= -378.425659 && position[1] <= -358.425659 && position[2] >= -1719.968750 && position[2] <= -1604.968750)
		return true;
	else 
		return false;
}

bool Appartement45(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1600.031250 && position[0] <= -1275.031250 && position[1] >= -2025.622680 && position[1] <= -1795.622558 && position[2] >= -1732.855712 && position[2] <= -1597.855712)
		return true;
	else 
		return false;
}

bool Appartement46(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1980.031250 && position[0] <= -1275.031250 && position[1] >= -1784.853271 && position[1] <= -1489.853271 && position[2] >= -1732.908203 && position[2] <= -1592.908203
	|| position[0] >= -1980.652954 && position[0] <= -1600.652954 && position[1] >= -2032.621948 && position[1] <= -1787.621948 && position[2] >= -1732.968750 && position[2] <= -1597.968750)
		return true;
	else 
		return false;
}

bool Appartement47(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1600.251586 && position[0] <= -1275.251586 && position[1] >= -2026.972045 && position[1] <= -1791.972045 && position[2] >= -1596.968750 && position[2] <= -1461.968750)
		return true;
	else 
		return false;
}

bool Appartement48(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1980.363525 && position[0] <= -1275.363525 && position[1] >= -1787.039184 && position[1] <= -1487.039184 && position[2] >= -1596.968750 && position[2] <= -1461.968750
	||position[0] >= -1980.185302 && position[0] <= -1600.185302 && position[1] >= -2028.616699 && position[1] <= -1788.616821 && position[2] >= -1596.968750 && position[2] <= -1461.968750)
		return true;
	else 
		return false;
}

bool PierreTombale(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -6342.031250 && position[0] <= -6062.031250 && position[1] >= 4387.468750 && position[1] <= 4647.468750 && position[2] >= -2526.012207 && position[2] <= -2366.012207)
		return true;
	else 
		return false;
}

bool VillaPvP(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -6984.135253 && position[0] <= -6519.135253 && position[1] >= 3188.114257 && position[1] <= 4468.114257 && position[2] >= -2460.968750 && position[2] <= -2050.968750
	|| position[0] >= -6537.587402 && position[0] <= -6007.587402 && position[1] >= 3555.676025 && position[1] <= 4500.675781 && position[2] >= -2340.968750 && position[2] <= -1980.968750
	|| position[0] >= -6012.357421 && position[0] <= -5897.357421 && position[1] >= 3940.303710 && position[1] <= 4500.303710 && position[2] >= -2340.968750 && position[2] <= -2030.968750
	|| position[0] >= -7994.644531 && position[0] <= -5449.644531 && position[1] >= 2080.278076 && position[1] <= 4785.278320 && position[2] >= -2340.968750 && position[2] <= -1730.968750
	|| position[0] >= -6345.201171 && position[0] <= -5720.201171 && position[1] >= 2954.812744 && position[1] <= 3429.812744 && position[2] >= -2726.968750 && position[2] <= -2336.968750
	|| position[0] >= -6896.215820 && position[0] <= -5906.215820 && position[1] >= 2917.326416 && position[1] <= 4792.326171 && position[2] >= -3841.625488 && position[2] <= -2251.625488)
		return true;
	else 
		return false;
}

bool ZonePvP(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -8000.031250 && position[0] <= -6470.031250 && position[1] >= -1469.671875 && position[1] <= 2080.328125 && position[2] >= -2340.721923 && position[2] <= -1740.721923
	|| position[0] >= -11986.824218 && position[0] <= -2991.823730 && position[1] >= -8824.087890 && position[1] <= -5809.087890 && position[2] >= -2012.968750 && position[2] <= -577.968750
	|| position[0] >= -8063.830566 && position[0] <= -7038.830566 && position[1] >= -8062.743164 && position[1] <= -6527.743164 && position[2] >= -2191.719970 && position[2] <= -2006.719970
	|| position[0] >= -7804.910156 && position[0] <= -7554.910156 && position[1] >= -6525.854003 && position[1] <= -5695.854003 && position[2] >= -2140.968750 && position[2] <= -2010.968750
	|| position[0] >= -7804.910156 && position[0] <= -7554.910156 && position[1] >= -8895.853515 && position[1] <= -8065.854003 && position[2] >= -2140.968750 && position[2] <= -2010.968750
	|| position[0] >= -7804.976562 && position[0] <= -3969.976562 && position[1] >= -8823.808593 && position[1] <= -8578.808593 && position[2] >= -2140.968750 && position[2] <= -2005.968750
	|| position[0] >= -8064.766113 && position[0] <= -3969.766113 && position[1] >= -8830.657226 && position[1] <= -5720.657226 && position[2] >= -2135.968750 && position[2] <= -2010.968750
	|| position[0] >= -4736.534179 && position[0] <= -3586.533935 && position[1] >= -5820.203613 && position[1] <= -5760.203613 && position[2] >= -1756.968750 && position[2] <= -576.968750)
		return true;
	else 
		return false;
}

bool ZonePvpBuster(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -6587.415527 && position[0] <= -6402.415527 && position[1] >= -9087.283203 && position[1] <= -8867.283203 && position[2] >= -2140.968750 && position[2] <= -1845.968750)
		return true;
	else 
		return false;
}

bool ZoneEvent(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 144.259902 && position[0] <= 5263.765136 && position[1] >= 6463.694335 && position[1] <= 11583.370117 && position[2] >= -2047.968750 && position[2] <= -3.088190)
		return true;
	else 
		return false;
}

bool TourMairie(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 16.298013 && position[0] <= 1016.297973 && position[1] >= 1168.268554 && position[1] <= 2453.268554 && position[2] >= -2120.968750 && position[2] <= -90.968750
	|| position[0] >= 0.001668 && position[0] <= 1010.001708 && position[1] >= 1158.579467 && position[1] <= 2413.579589 && position[2] >= -2150.968750 && position[2] <= -2110.968750)
		return true;
	else 
		return false;
}

bool Tribunal(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -1014.435546 && position[0] <= -514.435546 && position[1] >= -1143.878540 && position[1] <= -133.878540 && position[2] >= -2012.968750 && position[2] <= -1747.968750
	|| position[0] >= -511.968750 && position[0] <= -141.968750 && position[1] >= -507.598327 && position[1] <= -132.598312 && position[2] >= -2012.259765 && position[2] <= -1747.259765
	|| position[0] >= -118.759628 && position[0] <= 1151.240356 && position[1] >= -2043.031250 && position[1] <= -1533.031250 && position[2] >= -2011.574951 && position[2] <= -1751.574951
	|| position[0] >= 516.968750 && position[0] <= 1156.968750 && position[1] >= -1536.361816 && position[1] <= -1196.361816 && position[2] >= -2016.631591 && position[2] <= -1741.631591
	|| position[0] >= -516.173339 && position[0] <= -126.173339 && position[1] >= -1896.902343 && position[1] <= -1026.902343 && position[2] >= -2017.968750 && position[2] <= -1747.968750
	|| position[0] >= -176.468963 && position[0] <= -6.468965 && position[1] >= -1538.686279 && position[1] <= -1118.686279 && position[2] >= -2012.968750 && position[2] <= -1807.968750
	|| position[0] >= 781.467102 && position[0] <= 1151.467041 && position[1] >= -1208.625488 && position[1] <= -1158.625488 && position[2] >= -2012.968750 && position[2] <= -1752.968750)
		return true;
	else 
		return false;
}

bool Appartement21(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2923.650878 && position[0] <= -2568.650878 && position[1] >= -359.968750 && position[1] <= -149.968750 && position[2] >= -2131.862060 && position[2] <= -1996.862060)
		return true;
	else 
		return false;
}

bool Appartement22(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2556.199707 && position[0] <= -2111.199707 && position[1] >= -379.878173 && position[1] <= -149.878173 && position[2] >= -2132.968750 && position[2] <= -1997.968750)
		return true;
	else 
		return false;
}

bool Appartement24(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2551.315917 && position[0] <= -2111.315917 && position[1] >= -378.031250 && position[1] <= -143.031250 && position[2] >= -1995.765625 && position[2] <= -1860.765625)
		return true;
	else 
		return false;
}

bool Appartement23(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2923.858398 && position[0] <= -2563.858398 && position[1] >= -359.968750 && position[1] <= -149.968750 && position[2] >= -1996.514770 && position[2] <= -1861.514770)
		return true;
	else 
		return false;
}

bool Appartement26(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2556.113769 && position[0] <= -2111.113769 && position[1] >= -378.298004 && position[1] <= -143.298004 && position[2] >= -1860.968750 && position[2] <= -1725.968750)
		return true;
	else 
		return false;
}

bool Appartement25(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2923.916748 && position[0] <= -2563.916748 && position[1] >= -359.968750 && position[1] <= -144.968750 && position[2] >= -1859.740722 && position[2] <= -1724.740722)
		return true;
	else 
		return false;
}

bool Appartement28(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2554.615478 && position[0] <= -2114.615478 && position[1] >= -359.968750 && position[1] <= -144.968750 && position[2] >= -1738.634155 && position[2] <= -1593.634155)
		return true;
	else 
		return false;
}

bool Appartement27(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2923.140136 && position[0] <= -2563.140136 && position[1] >= -359.315673 && position[1] <= -144.315673 && position[2] >= -1729.968750 && position[2] <= -1594.968750)
		return true;
	else 
		return false;
}

bool GarageComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1153.001464 && position[0] <= 1793.001464 && position[1] >= 1546.270507 && position[1] <= 2016.270507 && position[2] >= -2148.968750 && position[2] <= -1873.968750)
		return true;
	else 
		return false;
}

bool ArmurerieComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1797.524414 && position[0] <= 2177.524414 && position[1] >= 1581.970336 && position[1] <= 2016.970336 && position[2] >= -2082.968750 && position[2] <= -1877.968750)
		return true;
	else 
		return false;
}

bool HallComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2180.792968 && position[0] <= 2705.792968 && position[1] >= 1161.548339 && position[1] <= 1711.548339 && position[2] >= -2020.968750 && position[2] <= -1875.968750
	|| position[0] >= 2183.968750 && position[0] <= 2708.968750 && position[1] >= 1719.047119 && position[1] <= 2424.047119 && position[2] >= -2020.771118 && position[2] <= -1875.771118)
		return true;
	else 
		return false;
}

bool ParloirComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1935.268432 && position[0] <= 2580.268554 && position[1] >= 2298.427978 && position[1] <= 3003.427978 && position[2] >= -2156.968750 && position[2] <= -2021.968750)
		return true;
	else 
		return false;
}

bool JailComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2187.040039 && position[0] <= 2907.040039 && position[1] >= 1332.653564 && position[1] <= 2292.653564 && position[2] >= -2156.968750 && position[2] <= -2021.968750
	|| position[0] >= 2187.968750 && position[0] <= 2702.968750 && position[1] >= 1153.525512 && position[1] <= 1348.525512 && position[2] >= -2155.957275 && position[2] <= -2020.957275)
		return true;
	else 
		return false;
}

bool EscalierComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1820.806152 && position[0] <= 2180.806152 && position[1] >= 2024.796630 && position[1] <= 2289.796630 && position[2] >= -2156.026367 && position[2] <= -1876.026367
	|| position[0] >= 1683.284179 && position[0] <= 2183.284179 && position[1] >= 2296.031250 && position[1] <= 2426.031250 && position[2] >= -2022.066284 && position[2] <= -1737.066284
	|| position[0] >= 1335.968750 && position[0] <= 2660.968750 && position[1] >= 2296.174316 && position[1] <= 2426.174316 && position[2] >= -1879.729492 && position[2] <= -1454.729492)
		return true;
	else 
		return false;
}

bool CourComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 3346.606445 && position[0] <= 4691.606445 && position[1] >= 2042.360107 && position[1] <= 3197.360107 && position[2] >= -2147.020019 && position[2] <= -1627.020019)
		return true;
	else 
		return false;
}

bool CouloirDeLaCourComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2586.598388 && position[0] <= 3341.598388 && position[1] >= 2532.049316 && position[1] <= 2672.049316 && position[2] >= -2156.968750 && position[2] <= -2016.968750)
		return true;
	else 
		return false;
}

bool QHSComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2238.054687 && position[0] <= 2803.054687 && position[1] >= 3009.723388 && position[1] <= 3389.723388 && position[2] >= -2156.968750 && position[2] <= -2021.968750)
		return true;
	else 
		return false;
}

bool CouloirComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 3346.031250 && position[0] <= 4701.031250 && position[1] >= 2042.650878 && position[1] <= 3197.650878 && position[2] >= -2176.732421 && position[2] <= -1631.732421)
		return true;
	else 
		return false;
}

bool ArchiveComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1688.031250 && position[0] <= 2658.031250 && position[1] >= 1805.668701 && position[1] <= 2300.668701 && position[2] >= -1911.782470 && position[2] <= -1741.782470)
		return true;
	else 
		return false;
}

bool ToitComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1336.969116 && position[0] <= 1456.969116 && position[1] >= 1990.334472 && position[1] <= 2295.334472 && position[2] >= -1588.968750 && position[2] <= -1453.968750)
		return true;
	else 
		return false;
}

bool ConduitComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2075.320312 && position[0] <= 2975.320312 && position[1] >= 1667.254516 && position[1] <= 1797.254516 && position[2] >= -1875.968750 && position[2] <= -1515.968750
	|| position[0] >= 1796.848388 && position[0] <= 2141.848388 && position[1] >= 1799.140991 && position[1] <= 1924.140991 && position[2] >= -1582.968750 && position[2] <= -1517.968750
	|| position[0] >= 2699.719970 && position[0] <= 3059.719970 && position[1] >= 1212.234130 && position[1] <= 1277.234130 && position[2] >= -2118.968750 && position[2] <= -2048.968750
	|| position[0] >= 2910.260253 && position[0] <= 3045.260253 && position[1] >= 1278.091308 && position[1] <= 1803.091308 && position[2] >= -2118.968750 && position[2] <= -1803.968750
	|| position[0] >= 2916.090087 && position[0] <= 2981.090087 && position[1] >= 1731.105957 && position[1] <= 2541.105957 && position[2] >= -2118.968750 && position[2] <= -2048.968750)
		return true;
	else 
		return false;
}

bool Metro(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -3587.152099 && position[0] <= -2827.152099 && position[1] >= -879.968750 && position[1] <= 70.031250 && position[2] >= -2404.779296 && position[2] <= -2144.779296
	|| position[0] >= -3058.652099 && position[0] <= -2853.652099 && position[1] >= -1469.571411 && position[1] <= 475.428588 && position[2] >= -2449.968750 && position[2] <= -2259.968750
	|| position[0] >= 3902.238281 && position[0] <= 5862.238281 && position[1] >= 10861.901367 && position[1] <= 11576.901367 && position[2] >= -2369.968750 && position[2] <= -2144.968750
	|| position[0] >= 1528.526855 && position[0] <= 3028.526855 && position[1] >= 411.968750 && position[1] <= 1156.968750 && position[2] >= -2425.895507 && position[2] <= -2205.895507
	|| position[0] >= -2944.638916 && position[0] <= 14389.576171 && position[1] >= -8833.034179 && position[1] <= -62727.156250 && position[2] >= -1751.968750 && position[2] <= 8614.204101
	|| position[0] >= -960.843261 && position[0] <= 529.156738 && position[1] >= -4354.765625 && position[1] <= -3579.765380 && position[2] >= -2327.968750 && position[2] <= -2057.968750)
		return true;
	else 
		return false;
}

public Action rp_SayOnPublic(int client, const char[] arg, const char[] Cmd, int args)
{
	if(canSetZoneName[client])
	{
		if(StrEqual(arg, "annuler"))
		{
			CPrintToChat(client, "%s Action annulée !", TEAM);
			canSetZoneName[client] = false;
		}	
		else
		{
			CPrintToChat(client, "%s Nom de zone: %s", TEAM, arg);
			Format(STRING(newZoneName), "%s", arg);
			canSetZoneName[client] = false;
		}					
	}
}	

public Action Cmd_Zoning(int client, int args)
{
	if(IsClientValid(client))
		MenuZoning(client);
}

Menu MenuZoning(int client)
{
	Menu menu = new Menu(DoMenuZoning);
	menu.SetTitle("Zoning :");
	if (zoning[client][0][0] == 0.0)
		menu.AddItem("spawn", "Créer un zoning");
	else
	{
		menu.AddItem("name", "Nom de zone");
		menu.AddItem("up", "Monter");
		menu.AddItem("down", "Descendre");
		menu.AddItem("leftX", "Deplacer X gauche");
		menu.AddItem("rightX", "Deplacer X droite");
		menu.AddItem("leftY", "Deplacer Y gauche");
		menu.AddItem("rightY", "Deplacer Y droite");
		menu.AddItem("taille", "Modifier la taille");
		menu.AddItem("inter+", "Ajouter une intervalle", ITEMDRAW_DISABLED);
		menu.AddItem("inter-", "Enlever une intervalle", ITEMDRAW_DISABLED);
		menu.AddItem("coord", "Enregistrer la zone");
		menu.AddItem("delete", "Supprimer");
	}
	
	menu.ExitBackButton = true; 
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

Menu MenuZoningTaille(int client)
{
	if (zoning[client][0][0] == 0.0)
		MenuZoning(client);
	else
	{
		Menu menu = new Menu(DoMenuZoningTaille);
		menu.SetTitle("Taille du zoning :");
		menu.AddItem("up", "Grandir");
		menu.AddItem("down", "Rétrécir");
		menu.AddItem("x+", "Grandir X");
		menu.AddItem("x-", "Rétrécir X");
		menu.AddItem("y+", "Grandir Y");
		menu.AddItem("y-", "Rétrécir Y");
		menu.AddItem("", "Retour pour déplacer.", ITEMDRAW_DISABLED);
		menu.ExitBackButton = true; 
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int DoMenuZoning(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "spawn"))
		{
			zoning[client][0][0] = 1.0; // Desactive le spawn
			PointVision(client, zoning[client][1]);
			
			zoning[client][1][2] += 5.0; // Init Z
			
			zoning[client][2] = zoning[client][1];
			zoning[client][2][1] = zoning[client][2][1] + 5.0;
			
			zoning[client][3] = zoning[client][1];
			zoning[client][3][0] = zoning[client][1][0] + 5.0;
			
			zoning[client][4] = zoning[client][2];
			zoning[client][4][0] = zoning[client][1][0] + 5.0;
			
			zoning[client][5] = zoning[client][1];
			zoning[client][5][2] += 5.0;
			
			zoning[client][6] = zoning[client][2];
			zoning[client][6][2] += 5.0;
			
			zoning[client][7] = zoning[client][3];
			zoning[client][7][2] += 5.0;
			
			zoning[client][8] = zoning[client][4];
			zoning[client][8][2] += 5.0;
			
			char strName[16], strTarget[16];
			Format(STRING(strName), "laser|1|%i", client);
			Format(STRING(strTarget), "laser|3|%i", client);
			int ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][1], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|2|%i", client);
			Format(STRING(strTarget), "laser|1|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][2], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|3|%i", client);
			Format(STRING(strTarget), "laser|4|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][3], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|4|%i", client);
			Format(STRING(strTarget), "laser|2|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][4], NULL_VECTOR, NULL_VECTOR);
			// 
			Format(STRING(strName), "laser|5|%i", client);
			Format(STRING(strTarget), "laser|7|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][5], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|6|%i", client);
			Format(STRING(strTarget), "laser|5|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][6], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|7|%i", client);
			Format(STRING(strTarget), "laser|8|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][7], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|8|%i", client);
			Format(STRING(strTarget), "laser|6|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][8], NULL_VECTOR, NULL_VECTOR);
			//
			Format(STRING(strName), "laser|9|%i", client);
			Format(STRING(strTarget), "laser|1|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][5], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|10|%i", client);
			Format(STRING(strTarget), "laser|2|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][6], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|11|%i", client);
			Format(STRING(strTarget), "laser|3|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][7], NULL_VECTOR, NULL_VECTOR);
			
			Format(STRING(strName), "laser|12|%i", client);
			Format(STRING(strTarget), "laser|4|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][8], NULL_VECTOR, NULL_VECTOR);
			
			MenuZoning(client);
		}
		else if (StrEqual(info, "up") || StrEqual(info, "down")
			 || StrEqual(info, "leftX") || StrEqual(info, "rightX")
			 || StrEqual(info, "leftY") || StrEqual(info, "rightY"))
		{
			if (StrEqual(info, "up"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][2] += 5.0;
			}
			else if (StrEqual(info, "down"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][2] -= 5.0;
			}
			else if (StrEqual(info, "leftX"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][0] += 5.0;
			}
			else if (StrEqual(info, "rightX"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][0] -= 5.0;
			}
			else if (StrEqual(info, "leftY"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][1] += 5.0;
			}
			else if (StrEqual(info, "rightY"))
			{
				for (int i = 1; i <= 8; i++)
				zoning[client][i][1] -= 5.0;
			}
			
			char entClass[64], entName[64], buffer[3][8];
			for (int i = MaxClients; i <= MAXENTITIES; i++)
			{
				if (IsValidEntity(i))
				{
					Entity_GetClassName(i, STRING(entClass));
					if (StrEqual(entClass, "env_laser"))
					{
						Entity_GetName(i, STRING(entName));
						if (StrContains(entName, "laser") != -1)
						{
							ExplodeString(entName, "|", buffer, 3, 8);
							if (String_IsNumeric(buffer[2]))
							{
								if (StringToInt(buffer[2]) == client)
								{
									int num = StringToInt(buffer[1]);
									switch (num)
									{
										case 9:num = 5;
										case 10:num = 6;
										case 11:num = 7;
										case 12:num = 8;
									}
									if (num <= 12)
										TeleportEntity(i, zoning[client][num], NULL_VECTOR, NULL_VECTOR);
									else
									{
										float position[3];
										GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
										
										if (StrEqual(info, "up"))
											position[2] += 5.0;
										else if (StrEqual(info, "down"))
											position[2] -= 5.0;
										else if (StrEqual(info, "leftX"))
											position[0] += 5.0;
										else if (StrEqual(info, "rightX"))
											position[0] -= 5.0;
										else if (StrEqual(info, "leftY"))
											position[1] += 5.0;
										else if (StrEqual(info, "rightY"))
											position[1] -= 5.0;
										TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
									}
								}
							}
						}
					}
				}
			}
			MenuZoning(client);
		}
		else if (StrEqual(info, "taille"))
			MenuZoningTaille(client);
		else if (StrEqual(info, "inter+"))
		{
			zoning[client][0][1] += 1.0;
			if (zoning[client][0][1] == 1.0)
			{
				float position[3];
				char strName[16], strTarget[16];
				position[0] = zoning[client][1][0];
				position[1] = zoning[client][1][1];
				position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
				
				Format(STRING(strName), "laser|13|%i", client);
				Format(STRING(strTarget), "laser|14|%i", client);
				int ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][2][0];
				position[1] = zoning[client][2][1];
				
				Format(STRING(strName), "laser|14|%i", client);
				Format(STRING(strTarget), "laser|15|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][4][0];
				position[1] = zoning[client][4][1];
				
				Format(STRING(strName), "laser|15|%i", client);
				Format(STRING(strTarget), "laser|16|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][3][0];
				position[1] = zoning[client][3][1];
				
				Format(STRING(strName), "laser|16|%i", client);
				Format(STRING(strTarget), "laser|13|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(ent, "TurnOn");
				// haut :
				position[0] = zoning[client][5][0];
				position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
				position[2] = zoning[client][5][2];
				
				Format(STRING(strName), "laser|17|%i", client);
				Format(STRING(strTarget), "laser|18|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][7][0];
				position[2] = zoning[client][7][2];
				
				Format(STRING(strName), "laser|18|%i", client);
				Format(STRING(strTarget), "laser|17|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0", false);
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				//AcceptEntityInput(ent, "TurnOn");
				// bas :
				position[0] = zoning[client][1][0];
				position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
				position[2] = zoning[client][1][2];
				
				Format(STRING(strName), "laser|19|%i", client);
				Format(STRING(strTarget), "laser|20|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][3][0];
				position[2] = zoning[client][3][2];
				
				Format(STRING(strName), "laser|20|%i", client);
				ent = SpawnLaser(strName, "", "102 204 0", false);
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			}
			MenuZoning(client);
		}
		else if (StrEqual(info, "coord"))
		{
			char arg1[64], arg2[64], arg3[64], arg4[64], arg5[64], arg6[64];
			if (zoning[client][1][0] < zoning[client][8][0])
			{
				Format(STRING(arg1), "%f", zoning[client][1][0]);
				Format(STRING(arg2), "%f", zoning[client][8][0]);
			}
			else
			{
				Format(STRING(arg1), "%f", zoning[client][8][0]);
				Format(STRING(arg2), "%f", zoning[client][1][0]);
			}
			if (zoning[client][1][1] < zoning[client][8][1])
			{
				Format(STRING(arg3), "%f", zoning[client][1][1]);
				Format(STRING(arg4), "%f", zoning[client][8][1]);
			}
			else
			{
				Format(STRING(arg3), "%f", zoning[client][8][1]);
				Format(STRING(arg4), "%f", zoning[client][1][1]);
			}
			if (zoning[client][1][2] < zoning[client][8][2])
			{
				Format(STRING(arg5), "%f", zoning[client][1][2]);
				Format(STRING(arg6), "%f", zoning[client][8][2]);
			}
			else
			{
				Format(STRING(arg5), "%f", zoning[client][8][2]);
				Format(STRING(arg6), "%f", zoning[client][1][2]);
			}
			
			PrintToChat(client, "position[0] >= %s && position[0] <= %s && position[1] >= %s && position[1] <= %s && position[2] >= %s && position[2] <= %s", arg1, arg2, arg3, arg4, arg5, arg6);
			PrintToConsole(client, "position[0] >= %s && position[0] <= %s && position[1] >= %s && position[1] <= %s && position[2] >= %s && position[2] <= %s", arg1, arg2, arg3, arg4, arg5, arg6);
			
			PrintHintText(client, "Coordonnées affichées !\n> Chat & console.");
			MenuZoning(client);
			
			char map[128];
			rp_GetCurrentMap(map);

			KeyValues kv = new KeyValues("Zones");
			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/zones.cfg", map);
				
			if(!kv.ImportFromFile(sPath))
			{
				delete kv;
				PrintToServer("configs/roleplay/%s/zones.cfg : NOT FOUND", map);
			}	
				
			if(!kv.JumpToKey(newZoneName))
			{		
				kv.SetSectionName(newZoneName);
				kv.JumpToKey(newZoneName);
				kv.SetString("maxpoints", "1");
			
				if(!kv.JumpToKey("1"))
				{		
					kv.SetSectionName("1");
					kv.SetFloat("x", StringToFloat(arg1));
					kv.SetFloat("y", StringToFloat(arg2));
					kv.SetFloat("z", StringToFloat(arg3));
					kv.SetFloat("x²", StringToFloat(arg4));
					kv.SetFloat("y²", StringToFloat(arg5));
					kv.SetFloat("z²", StringToFloat(arg6));
				}	
			}			
					
			kv.GoBack();
			kv.ExportToFile(sPath);	
			delete kv;	
		}
		else if (StrEqual(info, "delete"))
		{
			RemoveLaser(client);
			MenuZoning(client);
		}
		else if (StrEqual(info, "name"))
		{
			canSetZoneName[client] = true;
		}	
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		/*else if (param == MenuCancel_ExitBack)
			BuildAdminMenu(client);*/
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuZoningTaille(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "up"))
		{
			for (int i = 5; i <= 8; i++)
			zoning[client][i][2] += 5.0;
		}
		else if (StrEqual(info, "down"))
		{
			for (int i = 5; i <= 8; i++)
			zoning[client][i][2] -= 5.0;
		}
		else if (StrEqual(info, "x+"))
		{
			zoning[client][1][0] -= 5.0;
			zoning[client][2][0] -= 5.0;
			zoning[client][5][0] -= 5.0;
			zoning[client][6][0] -= 5.0;
		}
		else if (StrEqual(info, "x-"))
		{
			zoning[client][1][0] += 5.0;
			zoning[client][2][0] += 5.0;
			zoning[client][5][0] += 5.0;
			zoning[client][6][0] += 5.0;
		}
		else if (StrEqual(info, "y+"))
		{
			zoning[client][1][1] -= 5.0;
			zoning[client][3][1] -= 5.0;
			zoning[client][5][1] -= 5.0;
			zoning[client][7][1] -= 5.0;
		}
		else if (StrEqual(info, "y-"))
		{
			zoning[client][1][1] += 5.0;
			zoning[client][3][1] += 5.0;
			zoning[client][5][1] += 5.0;
			zoning[client][7][1] += 5.0;
		}
		
		char entClass[64], entName[64], buffer[3][8];
		for (int i = MaxClients; i <= MAXENTITIES; i++)
		{
			if (IsValidEntity(i))
			{
				Entity_GetClassName(i, STRING(entClass));
				if (StrEqual(entClass, "env_laser"))
				{
					Entity_GetName(i, STRING(entName));
					if (StrContains(entName, "laser") != -1)
					{
						ExplodeString(entName, "|", buffer, 3, 8);
						if (String_IsNumeric(buffer[2]))
						{
							if (StringToInt(buffer[2]) == client)
							{
								int num = StringToInt(buffer[1]);
								switch (num)
								{
									case 9:num = 5;
									case 10:num = 6;
									case 11:num = 7;
									case 12:num = 8;
								}
								if (num <= 12)TeleportEntity(i, zoning[client][num], NULL_VECTOR, NULL_VECTOR);
								else
								{
									float position[3];
									GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
									
									if (StrEqual(info, "up"))
									{
										if (num == 17 || num == 18)
											position[2] += 5.0;
										else if (num >= 13 && num <= 16)
											position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
									}
									else if (StrEqual(info, "down"))
									{
										if (num == 17 || num == 18)
											position[2] -= 5.0;
										else if (num >= 13 && num <= 16)
											position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
									}
									else if (StrEqual(info, "x+"))
									{
										if (num == 13 || num == 14 || num == 17 || num == 19)
											position[0] -= 5.0;
									}
									else if (StrEqual(info, "x-"))
									{
										if (num == 13 || num == 14 || num == 17 || num == 19)
											position[0] += 5.0;
									}
									else if (StrEqual(info, "y+"))
									{
										if (num == 13 || num == 16)
											position[1] -= 5.0;
										else if (num == 17 || num == 18)
											position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
										else if (num == 19 || num == 20)
											position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
									}
									else if (StrEqual(info, "y-"))
									{
										if (num == 13 || num == 16)
											position[1] += 5.0;
										else if (num == 17 || num == 18)
											position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
										else if (num == 19 || num == 20)
											position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
									}
									TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
					}
				}
			}
		}
		MenuZoningTaille(client);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuZoning(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

stock int SpawnLaser(char[] entName, char[] targetName, char[] color, bool turnOn = true)
{
	int ent = CreateEntityByName("env_laser");
	Entity_SetName(ent, entName);
	DispatchKeyValue(ent, "texture", "sprites/laserbeam.vmt");
	DispatchKeyValue(ent, "rendercolor", color);
	DispatchKeyValue(ent, "width", "1");
	DispatchKeyValue(ent, "LaserTarget", targetName);
	DispatchSpawn(ent);
	if (turnOn)AcceptEntityInput(ent, "TurnOn");
	
	return ent;
}

stock int RemoveLaser(int client)
{
	for (int i; i <= 8; i++)
	{
		zoning[client][i][0] = 0.0;
		zoning[client][i][1] = 0.0;
		zoning[client][i][2] = 0.0;
	}
	
	char entClass2[64], entName2[64], buffer2[3][8];
	for (int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if (IsValidEntity(i))
		{
			Entity_GetClassName(i, STRING(entClass2));
			if (StrEqual(entClass2, "env_laser"))
			{
				Entity_GetName(i, STRING(entName2));
				if (StrContains(entName2, "laser") != -1)
				{
					ExplodeString(entName2, "|", buffer2, 3, 8);
					if (String_IsNumeric(buffer2[2]))
					{
						if (StringToInt(buffer2[2]) == client)
							AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
}