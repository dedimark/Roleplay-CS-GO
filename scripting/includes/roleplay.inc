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
#include <unixtime_sourcemod>

//*********************************************************************
//*                       CORE MAIN DEFINES                           *
//*********************************************************************

#define STRING(%1) %1, sizeof(%1)
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define TEAM "{yellow}[{green}VR-Hosting{yellow}]{default}"
#define VERSION "1.0"
#define URL "www.vr-hosting.fr"
#define DISCORD_URL "https://discord.gg/jZ9zmcw"
#define FORUM_URL "https://forum.vr-hosting.fr/"
#define DISCORD_WEBHOOK "https://discordapp.com/api/webhooks/735907316079001702/d0UEu3-9X0dLohSB-9JKKp737z8PHsxeO2zrUBPNkciJrVnrb_rNsRbqKJ0zin8V8LSs"
#define MAXJOBS 20
#define MAXENTITIES 2048


//*********************************************************************
//*                       Load other libraries **/                    *
//*********************************************************************

#include "roleplay/enum.inc"
#include "roleplay/natives.inc"
#include "roleplay/forwards.inc"
#include "roleplay/jobs.inc"
#include "roleplay/methodmap.inc"
#include "roleplay/sql.inc"
#include "roleplay/stocks.inc"
#include "roleplay/vehicle.inc"
