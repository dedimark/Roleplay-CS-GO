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
//*                       CORE MAIN JOBS                        	  *
//*********************************************************************

stock void GetJobNote(int jobID, char[] noteVarChar, int maxlength)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		kv.GetString("note", noteVarChar, sizeof(maxlength));		
	}	
	
	kv.Rewind();	
	delete kv;
}

stock void SetNote(int client, int job, const char[] texte)
{
	char note[2048];
	rp_GetJobNote(job, STRING(note));	
	
	if(StrEqual(note, "none"))
	{		
		char strFormat[2048];
		strcopy(STRING(strFormat), texte);
		
		rp_SetJobNote(job, STRING(strFormat));
		
		KeyValues kv = new KeyValues("Jobs");
	
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
		
		if(!kv.ImportFromFile(sPath))
		{
			delete kv;
			PrintToServer("configs/roleplay/jobs.cfg NOT FOUND");
		}	
	
		char jobString[2];
		IntToString(job, STRING(jobString));
		if(kv.JumpToKey(jobString))
		{		
			kv.SetString("note", texte);
		}	
		
		kv.Rewind();	
		delete kv;
		
		char jobName[32];
		GetJobName(job, STRING(jobName));
		
		PrintHintText(client, "Note ajoutée.");
		CPrintToChat(client, "%s Note ajoutée avec succès : %s", TEAM, texte);
		
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == rp_GetClientInt(client, i_Job) && i != client)
				PrintHintText(i, "Nouvelle note de métier ajoutée.");
		}
		
		rp_SetClientBool(client, b_addNote, false);
	}	
	else
		CPrintToChat(client, "%s Attention, une note existe déjà, veuillez la modifier.", TEAM);
}

stock int GetMaxGrades(int jobID)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	int nbGrade;
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		nbGrade = kv.GetNum("grades");
	}	
	kv.Rewind();
	delete kv;
	
	return nbGrade;
}

stock void SetJobSkin(int client, bool spawn = true)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(rp_GetClientInt(client, i_Job), STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(rp_GetClientInt(client, i_Grade), STRING(gradeString));
		if(kv.JumpToKey(gradeString))
		{	
			char model[256];			
			kv.GetString("model", STRING(model));
			
			if(!StrEqual(model, "none"))
			{
				if(rp_GetClientInt(client, i_Job) == 1 && !spawn)
					rp_SetSkin(client, model);
				else if(rp_GetClientInt(client, i_Job) != 1)
					rp_SetSkin(client, model);
			}
			
			if(spawn)
				rp_SetSkin(client, "models/player/custom_player/voikanaa/gtaiv/niko.mdl");			
		}
	}	
	
	kv.Rewind();
	delete kv;
}

stock int GetMaxJobs()
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	int total = kv.GetNum("maxjobs");
	kv.Rewind();
	delete kv;
	
	return total;
}

stock int GetSalaire(int jobID, int gradeID)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	int salaire;
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(gradeID, STRING(gradeString));
		if(kv.JumpToKey(gradeString))
			salaire = kv.GetNum("salary");
	}	
	kv.Rewind();
	delete kv;
	
	return salaire;	
}

stock void SetSalaire(int jobID, int gradeID, int value)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(gradeID, STRING(gradeString));
		if(kv.JumpToKey(gradeString))	
		{
			kv.SetNum("salary", value);
			kv.Rewind();
			kv.ExportToFile(sPath);
		}	
	}	
	delete kv;
}

stock void LoadSalaire(int client)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(rp_GetClientInt(client, i_Job), STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(rp_GetClientInt(client, i_Grade), STRING(gradeString));
		
		if(kv.JumpToKey(gradeString))	
		{
			int salaire = kv.GetNum("salary");
			rp_SetClientInt(client, i_Salaire, salaire);	
		}	
	}	
	
	kv.Rewind();
	delete kv;
}

stock void GetJobName(int jobID, char[] jobName, int maxlen)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{
		kv.GetString("jobname", jobName, maxlen);
	}	
	
	kv.Rewind();	
	delete kv;
}

stock void GetGradeName(int gradeID, int jobID, char[] gradeName, int maxlen)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(gradeID, STRING(gradeString));
		if(kv.JumpToKey(gradeString))		
			kv.GetString("grade", gradeName, maxlen);	
	}	
	
	kv.Rewind();	
	delete kv;
}

stock void GetClanTag(int gradeID, int jobID, char[] clantag, int maxlen)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/callofduty/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		char gradeString[32];
		IntToString(gradeID, STRING(gradeString));
		if(kv.JumpToKey(gradeString))
			kv.GetString("clantag", clantag, maxlen);		
	}	
	
	kv.Rewind();
	delete kv;
}

stock bool isZoneProprietaire(int client)
{
	int jobid = rp_GetClientInt(client, i_Job);
	int zoneid = rp_GetClientInt(client, i_ByteZone);
	
	if(jobid == 1 && zoneid == 1)
		return true;
	else if(jobid == 2 && zoneid == 2)
		return true;
	else if(jobid == 3 && zoneid == 3)
		return true;	
	else if(jobid == 4 && zoneid == 4)
		return true;	
	else if(jobid == 5 && zoneid == 5)
		return true;	
	else if(jobid == 6 && zoneid == 6)
		return true;
	else if(jobid == 7 && zoneid == 7)
		return true;
	else if(jobid == 8 && zoneid == 8)
		return true;
	else if(jobid == 9 && zoneid == 9)
		return true;
	else if(jobid == 10 && zoneid == 10)
		return true;	
	else if(jobid == 11 && zoneid == 11)
		return true;
	else if(jobid == 12 && zoneid == 12)
		return true;
	else if(jobid == 13 && zoneid == 13)
		return true;	
	else if(jobid == 14 && zoneid == 14)
		return true;	
	else if(jobid == 15 && zoneid == 15)
		return true;	
	else
		return false;
}

stock int GetDoorsAcces(int client, int jobID, int gradeID, int hID)
{
	KeyValues kv = new KeyValues("Jobs");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/callofduty/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	if(kv.JumpToKey(jobString))
	{	
		kv.JumpToKey("doorsAcces");
		
		char HammerID_String[32];
		IntToString(hID, STRING(HammerID_String));
		if(kv.JumpToKey(HammerID_String))
		{
			char gradesAcces[64];
			kv.GetString("gradeAcess", STRING(gradesAcces));
			
			char actualGrade[64];
			IntToString(gradeID, STRING(actualGrade));
			
			if(StrContains(gradesAcces, actualGrade))
				return true;
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);	
				return false;
			}	
		}
		else
			CPrintToChat(client, "%s Porte non configurée.", TEAM);
	}		
	
	kv.Rewind();
	delete kv;
	
	return false;
}