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

#if defined _roleplay_included
 #endinput
#endif
#define _roleplay_included

//*********************************************************************
//*                       CORE MAIN INCLUDES                          *
//*********************************************************************

#include <discord_notification>
#include <cstrike>
#include <clients>

//*********************************************************************
//*                       CORE MAIN DEFINES                           *
//*********************************************************************

#define STRING(%1) %1, sizeof(%1)
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define TEAM 			"{yellow}[{lightblue}Roleplay{yellow}]{default}"
#define AUTHOR			"MBK"
#define VERSION 		"1.0"
#define URL 			"www.vr-hosting.fr"
#define DISCORD_URL 	"https://discord.gg/jZ9zmcw"
#define FORUM_URL 		"https://forum.vr-hosting.fr/"
#define DISCORD_WEBHOOK "https://discordapp.com/api/webhooks/760488311289675847/l76u4zN2zA2THS9ynsUVbo7tr0ZLTPG1lYqPAnJABcqor0grZAsnKo6p2sGkGo3jpWgT"
#define MAXJOBS 	20
#define MAXENTITIES 2048
#define MAXAPPART 	512
#define MAXITEMS	256
#define MAXGROUPES 	256

#define WEED_PLANT_1 "models/vr-hosting/drug/weedplant_pot_v1.mdl"
#define WEED_PLANT_2 "models/vr-hosting/drug/weedplant_pot_v2.mdl"
#define WEED_PLANT_3 "models/vr-hosting/drug/weedplant_pot_v3.mdl"
#define WEED_PLANT_4 "models/vr-hosting/drug/weedplant_pot_v4.mdl"
#define WEED_PLANT_5 "models/vr-hosting/drug/weedplant_pot_v5.mdl"
#define WEED_PLANT_6 "models/vr-hosting/drug/weedplant_pot_v6.mdl"
#define WEED_PLANT_7 "models/vr-hosting/drug/weedplant_pot_v7.mdl"

#define IMPRIMANTE 	 "models/freeman/compact_printer.mdl"
#define MONEY_MDL 	 "models/props/cs_assault/money.mdl"

#define MONTANT_MAX_MORT  200 // $
#define MONTANT_MIN_MORT  50 // $

#define JOIN_SOUND  "roleplay/join.wav"
#define PHONE_RECEIVER  "roleplay/phone_sound_receiver.wav"
#define PHONE_SENDER  "phone_sound_sender.wav"

#define EVENT_SPAWN {4759.233398, 11494.939453, -2047.968750}

#define JAIL_POLICE_1 {2288.847167, 1317.795898, -2151.968750}
#define JAIL_POLICE_2 {2803.303955, 1496.563110, -2151.968750}
#define JAIL_POLICE_3 {2286.474121, 1661.184082, -2151.968750}
#define JAIL_POLICE_4 {2800.080566, 1836.005004, -2151.968750}
#define JAIL_POLICE_5 {2284.735107, 1967.276855, -2151.968750}
#define JAIL_POLICE_6 {2801.993164, 2159.768310, -2151.968750}
#define JAIL_TRIBUNAL_1 {495.802673, -1976.294799, -2007.968750}
#define JAIL_TRIBUNAL_2 {-966.239318, -563.905700, -2007.968750}

//*********************************************************************
//*                       Load other libraries **/                    *
//*********************************************************************

#include "roleplay/enum.inc"
#include "roleplay/natives.inc"
#include "roleplay/forwards.inc"
#include "roleplay/jobs.inc"
//#include "roleplay/methodmap.inc"
#include "roleplay/sql.inc"
#include "roleplay/stocks.inc"
#include "roleplay/vehicle.inc"
