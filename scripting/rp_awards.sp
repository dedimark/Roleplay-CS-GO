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
#define MAX_QUESTIONS 22
#define PREFIX "{yellow}[{orange}QUESTION{yellow}]{default}"

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
Handle g_hQuestions;
char reponse[128];
char question[128];
bool canRespond;
int reward;
//int lastQuestion;
ConVar cv_QuestionRefreshTimer;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Questions",
	author = "Benito",
	description = "Système Appartement",
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
	
	cv_QuestionRefreshTimer = CreateConVar("rp_question_refresh", "900.0", "The timer to send new question.");
	AutoExecConfig(true, "rp_awards");
}	

public void OnMapStart()
{
	g_hQuestions = CreateTimer(GetConVarFloat(cv_QuestionRefreshTimer), SendQuestions, _, TIMER_REPEAT);
}	

public void OnMapEnd()
{
	if(g_hQuestions != null)
	{
		TrashTimer(g_hQuestions, true);
	}
}	

public Action QuestionStatus(Handle Timer)
{
	if(canRespond)
	{
		canRespond = false;
		CPrintToChatAll("%s Fin de la question, personne n'as répondu.", PREFIX);
	}	
}		

public Action SendQuestions(Handle Timer)
{
	CreateTimer(30.0, QuestionStatus);
	int nb = GetRandomInt(1, MAX_QUESTIONS);
	
	/*int nb = 1;
	if(nb != lastQuestion)
	{
		nb = GetRandomInt(1, MAX_QUESTIONS);
		lastQuestion = nb;
	}	*/
	
	KeyValues kv = new KeyValues("Questions");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/questions.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/questions.cfg : NOT FOUND");
	}	
	
	char idString[32];
	IntToString(nb, STRING(idString));
	kv.JumpToKey(idString);
	
	kv.GetString("question", STRING(question));
	
	CPrintToChatAll("%s %s", PREFIX, question);
	
	kv.GetString("reponse", STRING(reponse));		
	
	reward = kv.GetNum("reward");
	
	kv.Rewind();	
	delete kv;
	
	canRespond = true;
}	

public Action RP_OnPlayerSay(int client, const char[] arg)
{
	if(canRespond)
	{
		if(strcmp(arg, reponse))
		{
			canRespond = false;
			CPrintToChatAll("%s %N a répondu correctement à la question\nLa réponse était: %s.", PREFIX, client, reponse);
			CPrintToChat(client, "%s Vous avez reçu %i$ pour votre bonne réponse.", PREFIX, reward);
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + reward);
		}	
	}	
}