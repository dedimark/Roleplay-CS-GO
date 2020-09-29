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

/***************************************************************************************

							C O M P I L E  -  O P T I O N S

***************************************************************************************/
#pragma semicolon 1
#pragma newdecls required

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define MAXPOS 10
#define MAXZONE 256

/***************************************************************************************

							P L U G I N  -  I N F O

****************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Zones & Byt",
	author = "Benito",
	description = "Système zoning pour le roleplay",
	version = VERSION,
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	GameCheck();
	rp_LoadTranslation();
	
	RegConsoleCmd("printbytzone", Cmd_ByteZoneDisplay);
}

public Action Cmd_ByteZoneDisplay(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))	
		CPrintToChat(client, "%s Bytezone %i", TEAM, rp_GetClientInt(client, i_ByteZone));
	
	return Plugin_Handled;
}	

public void OnClientPostAdminCheck(int client) 
{
	rp_SetClientInt(client, i_ByteZone, 0);
}

public void OnGameFrame()
{
	LoopClients(i)
		GetZones(i);
}		

public int GetZones(int client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(Armurerie(client))
			{
				rp_SetClientInt(client, i_ByteZone, 6);
				rp_SetClientString(client, sz_Zone, "Armurerie", 32);
			}
			else if(Banque(client))
			{
				if(Coffre_Banque(client))
					rp_SetClientInt(client, i_ByteZone, 111);
				else
					rp_SetClientInt(client, i_ByteZone, 11);				
				rp_SetClientString(client, sz_Zone, "Banque", 32);
			}
			else if(McDonalds(client))
			{
				if(McDonalds_Holdup(client))
					rp_SetClientInt(client, i_ByteZone, 155);
				else
					rp_SetClientInt(client, i_ByteZone, 15);			
				rp_SetClientString(client, sz_Zone, "McDonald's", 32);
			}
			else if(DolceGabanna(client))
			{
				if(DolceGabanna_Holdup(client))
					rp_SetClientInt(client, i_ByteZone, 144);
				else	
					rp_SetClientInt(client, i_ByteZone, 14);			
				rp_SetClientString(client, sz_Zone, "Dolce & Gabbana", 32);
			}
			else if(Discotheque(client))
			{
				//rp_SetClientInt(client, i_ByteZone, 8);			
				rp_SetClientString(client, sz_Zone, "Discothèque", 32);
			}
			else if(Casino(client))
			{
				rp_SetClientInt(client, i_ByteZone, 16);			
				rp_SetClientString(client, sz_Zone, "Casino", 32);
			}
			else if(AgenceImmobilier(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);				
				rp_SetClientString(client, sz_Zone, "Agence immobilière", 32);
			}
			else if(PlanqueTueur(client))
			{
				rp_SetClientInt(client, i_ByteZone, 12);				
				rp_SetClientString(client, sz_Zone, "Planque Tueur", 32);
			}
			else if(VillaNumero1(client))
			{
				rp_SetClientInt(client, i_ByteZone, 19);				
				rp_SetClientString(client, sz_Zone, "Villa № 1", 32);
			}
			else if(Coach(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 17);				
				rp_SetClientString(client, sz_Zone, "Planque Coach", 32);
			}
			else if(Hopital(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 4);				
				rp_SetClientString(client, sz_Zone, "Hôpital", 32);
			}	
			else if(Technicien(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 10);				
				rp_SetClientString(client, sz_Zone, "Planque Technicien", 32);
			}
			else if(SexShop(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 18);			
				rp_SetClientString(client, sz_Zone, "Chez Roger", 32);
			}
			else if(Artificier(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 13);				
				rp_SetClientString(client, sz_Zone, "Planque Artificier", 32);
			}
			else if(Dealer(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 9);				
				rp_SetClientString(client, sz_Zone, "Planque Dealer", 32);
			}	
			else if(CarShop(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 20);				
				rp_SetClientString(client, sz_Zone, "CarShop", 32);
			}
			else if(MafiaJaponaise(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 2);				
				rp_SetClientString(client, sz_Zone, "Planque Mafia 中国的", 32);
			}	
			else if(Mafia18th(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 3);				
				rp_SetClientString(client, sz_Zone, "Planque 18th", 32);
			}	
			else if(Appartement(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement - Hall", 32);
			}
			else if(Appartement18(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 18", 32);
			}	
			else if(Appartement17(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 17", 32);
			}	
			else if(Appartement15(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 15", 32);
			}
			else if(Appartement16(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 16", 32);
			}
			else if(Appartement31(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 31", 32);
			}
			else if(Appartement32(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 32", 32);
			}
			else if(Appartement33(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 33", 32);
			}
			else if(Appartement34(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 34", 32);
			}
			else if(Appartement35(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 35", 32);
			}
			else if(Appartement41(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 41", 32);
			}
			else if(Appartement42(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 42", 32);
			}
			else if(Appartement43(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 43", 32);
			}
			else if(Appartement44(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 44", 32);
			}
			else if(Appartement13(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 13", 32);
			}
			else if(Appartement14(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 14", 32);
			}
			else if(Appartement11(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 11", 32);
			}
			else if(Appartement12(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 12", 32);
			}
			else if(Appartement38(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 38", 32);
			}
			else if(Appartement37(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 37", 32);
			}
			else if(Appartement36(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 36", 32);
			}
			else if(Appartement46(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 46", 32);
			}
			else if(Appartement45(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 45", 32);
			}
			else if(Appartement48(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 48", 32);
			}
			else if(Appartement47(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 47", 32);
			}
			else if(PierreTombale(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Pierre Tombal", 32);
			}
			else if(VillaPvP(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 777);				
				rp_SetClientString(client, sz_Zone, "Villa P.V.P", 32);
			}
			else if(Tribunal(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 7);				
				rp_SetClientString(client, sz_Zone, "Tribunal", 32);
			}
			else if(TourMairie(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 5);				
				rp_SetClientString(client, sz_Zone, "Mairie", 32);
			}
			else if(Appartement21(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 21", 32);
			}
			else if(Appartement22(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 22", 32);
			}
			else if(Appartement24(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 24", 32);
			}
			else if(Appartement23(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 23", 32);
			}
			else if(Appartement27(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 27", 32);
			}
			else if(Appartement28(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 28", 32);
			}
			else if(Appartement25(client))
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 25", 32);
			}
			else if(Appartement26(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 8);		
				rp_SetClientString(client, sz_Zone, "Appartement № 26", 32);
			}
			else if(GarageComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);				
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Garage", 32);
			}
			else if(ArmurerieComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);				
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Armurerie", 32);
			}
			else if(HallComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Hall", 32);
			}
			else if(EscalierComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Escalier", 32);
			}
			else if(ParloirComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Parloir", 32);
			}
			else if(JailComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Jail", 32);
			}
			else if(CouloirDeLaCourComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Couloir de la Cour", 32);
			}
			else if(CourComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Cour", 32);
			}
			else if(QHSComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Q.H.S", 32);
			}
			else if(CouloirComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Couloir", 32);
			}
			else if(ArchiveComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Archive", 32);
			}
			else if(ToitComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Toit", 32);
			}
			else if(ConduitComico(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 1);
				rp_SetClientString(client, sz_Zone, "P.C.P.D - Conduit", 32);
			}
			else if(ZonePvP(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 777);				
				rp_SetClientString(client, sz_Zone, "Zone P.V.P", 32);
			}
			else if(ZonePvpBuster(client))
			{
				rp_SetClientInt(client, i_ByteZone, 777);				
				rp_SetClientString(client, sz_Zone, "Tombeau de BusteR", 32);
			}
			else if(ZoneEvent(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 777);				
				rp_SetClientString(client, sz_Zone, "Zone Event", 32);
			}
			else if(Metro(client))	
			{
				rp_SetClientInt(client, i_ByteZone, 0);								
				rp_SetClientString(client, sz_Zone, "Métro", 32);
			}
			else
			{
				rp_SetClientInt(client, i_ByteZone, 0);
				rp_SetClientString(client, sz_Zone, "En Ville", 32);
			}	
		}
		else 
			rp_SetClientInt(client, i_ByteZone, -1);	
	}
}

/*bool CheckIfIsInZone(int client, char[] kvZone)
{	
	char map[128];
	GetCurrentMap(STRING(map));
	if (StrContains(map, "workshop") != -1) {
		char mapPart[3][64];
		ExplodeString(map, "/", mapPart, 3, 64);
		strcopy(STRING(map), mapPart[2]);
	}
	
	KeyValues kv = new KeyValues("Zones", 32);

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/zones/%s.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/zones/%s.cfg : NOT FOUND", map);
	}	
	
	kv.JumpToKey(kvZone);
		
	int points = kv.GetNum("maxpoints", 32);
	
	char point[64];
	
	for(int i = 1; i <= points; i++)
	{
		Format(STRING(point), "%i", i);
		kv.JumpToKey(point);
		float kvPos0[MAXPOS][3];
		float kvPos1[MAXPOS][3];
		kvPos0[i][0] = kv.GetFloat("x", 32);
		kvPos0[i][1] = kv.GetFloat("y", 32);
		kvPos0[i][2] = kv.GetFloat("z", 32);
		kvPos1[i][0] = kv.GetFloat("x²", 32);
		kvPos1[i][1] = kv.GetFloat("y²", 32);
		kvPos1[i][2] = kv.GetFloat("z²", 32);
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
}*/

bool Armurerie(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -2287.867675 && position[0] <= -1292.867675 && position[1] >= 768.174194 && position[1] <= 1393.174194 && position[2] >= -2140.968750 && position[2] <= -2005.968750
	|| position[0] >= -2287.968750 && position[0] <= -1297.968750 && position[1] >= 526.985229 && position[1] <= 1396.985229 && position[2] >= -1996.955688 && position[2] <= -1861.955688
	|| position[0] >= -2286.053710 && position[0] <= -1291.053588 && position[1] >= 544.077880 && position[1] <= 1029.077880 && position[2] >= -2276.968750 && position[2] <= -2141.968750
	|| position[0] >= -2291.459960 && position[0] <= -1296.460083 && position[1] >= 1030.636108 && position[1] <= 1390.636108 && position[2] >= -2271.968750 && position[2] <= -2136.968750)
		return true;
	else 
		return false;
}

bool Banque(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2560.031250 && position[0] <= 3260.031250 && position[1] >= -387.037750 && position[1] <= 452.962249 && position[2] >= -2108.575439 && position[2] <= -1378.575439
	|| position[0] >= 2364.648925 && position[0] <= 2559.648925 && position[1] >= -191.054260 && position[1] <= 193.945739 && position[2] >= -2108.968750 && position[2] <= -1848.968750
	|| position[0] >= 3133.873291 && position[0] <= 3268.873291 && position[1] >= -448.031250 && position[1] <= -313.031250 && position[2] >= -2109.798339 && position[2] <= -1729.798339
	|| position[0] >= 3133.900146 && position[0] <= 3268.900146 && position[1] >= -322.123321 && position[1] <= -182.123321 && position[2] >= -2264.968750 && position[2] <= -1989.968750
	|| position[0] >= 3137.132568 && position[0] <= 3267.132568 && position[1] >= -187.090988 && position[1] <= 87.909011 && position[2] >= -2268.968750 && position[2] <= -2108.968750
	|| position[0] >= 2560.639404 && position[0] <= 3275.639404 && position[1] >= 88.609703 && position[1] <= 353.609710 && position[2] >= -2263.968750 && position[2] <= -2113.968750
	|| position[0] >= 2559.968750 && position[0] <= 3139.968750 && position[1] >= -448.151000 && position[1] <= 76.849014 && position[2] >= -2268.711669 && position[2] <= -2113.711669)
		return true;
	else 
		return false;
}

bool Coffre_Banque(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 3137.132568 && position[0] <= 3267.132568 && position[1] >= -187.090988 && position[1] <= 87.909011 && position[2] >= -2268.968750 && position[2] <= -2108.968750
	|| position[0] >= 2560.639404 && position[0] <= 3275.639404 && position[1] >= 88.609703 && position[1] <= 353.609710 && position[2] >= -2263.968750 && position[2] <= -2113.968750)
		return true;
	else 
		return false;
}

bool McDonalds(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -904.548156 && position[0] <= 190.451843 && position[1] >= -4992.827148 && position[1] <= -4222.827148 && position[2] >= -2007.968750 && position[2] <= -1702.968750)
		return true;
	else 
		return false;
}

bool McDonalds_Holdup(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -219.031250 && position[0] <= 175.968750 && position[1] >= -4240.721679 && position[1] <= -4230.721679 && position[2] >= -2011.870117 && position[2] <= -1876.870117
	|| position[0] >= -339.030517 && position[0] <= -189.030502 && position[1] >= -4980.791503 && position[1] <= -4795.791503 && position[2] >= -2012.968750 && position[2] <= -1877.968750)
		return true;
	else 
		return false;
}

bool DolceGabanna(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 528.968750 && position[0] <= 1388.968750 && position[1] >= -6641.923828 && position[1] <= -5631.923828 && position[2] >= -2017.798339 && position[2] <= -1672.798339
	|| position[0] >= 492.508422 && position[0] <= 1387.508422 && position[1] >= -6633.323242 && position[1] <= -6218.323242 && position[2] >= -2188.968750 && position[2] <= -2013.968750)
		return true;
	else 
		return false;
}

bool DolceGabanna_Holdup(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1121.355224 && position[0] <= 1286.355224 && position[1] >= -6194.895996 && position[1] <= -5844.895996 && position[2] >= -2011.968750 && position[2] <= -1841.968750)
		return true;
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

bool PlanqueTueur(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -5743.770507 && position[0] <= -3923.770507 && position[1] >= -3054.746582 && position[1] <= -2059.746582 && position[2] >= -2007.968750 && position[2] <= -1807.968750)
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

bool Hopital(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1155.254150 && position[0] <= 1555.254150 && position[1] >= -2819.823242 && position[1] <= -2114.823242 && position[2] >= -2007.968750 && position[2] <= -1882.968750
	|| position[0] >= 1535.225585 && position[0] <= 2550.225585 && position[1] >= -2944.898437 && position[1] <= -1534.898437 && position[2] >= -2138.968750 && position[2] <= -1353.968750
	|| position[0] >= 1540.047119 && position[0] <= 2565.047119 && position[1] >= -2767.900878 && position[1] <= -1527.900756 && position[2] >= -2148.968750 && position[2] <= -2023.968750)
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