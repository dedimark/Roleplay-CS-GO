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
//*                       CORE MAIN METHODMAP                         *
//*********************************************************************

methodmap Roleplay
{
	public Roleplay(int client) {
		return view_as<Roleplay>(client);
	}

	//=====================//
	// P R O P E R T I E S //
	//=====================//

	/**
	 * Returns the client's index.
	 *
	 * @return				Client's index.
	 */
	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	/**
	 * Returns if a player is valid or not.
	 *
	 * @return				True if player is valid, false otherwise.
	 */
	property bool IsValid {
		public get() {
			return IsClientValid(this.index);
		}
	}

	/**
	 * Retrieves a client's team index (and can also change the client's team).
	 *
	 * @return				Team index the client is on (mod specific).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Team {
		public get() {
			return GetClientTeam(this.index);
		}
		public set(int team) {
			ChangeClientTeam(this.index, team);
		}
	}

	/**
	 * Returns the client's health.
	 *
	 * @return				Health value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Health {
		public get() {
			return GetClientHealth(this.index);
		}
	}

	/**
	 * Returns the client's armor.
	 *
	 * @return				Armor value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Armor {
		public get() {
			return GetClientArmor(this.index);
		}
	}
	
	/**
	 * Returns the client's User ID.
	 *
	 * @return				Armor value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int UserID {
		public get() {
			return GetClientUserId(this.index);
		}
	}
	
	/**
	 * Returns or change the client's Admin Level.
	 *
	 * @return				adminLevel value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int AdminID {
		public get() {
			return rp_GetClientInt(this.index, i_AdminLevel);
		}
		public set(int level) {
            rp_SetClientInt(this.index, i_AdminLevel, level);
        }
	}
	
	/**
	 * Returns or change the client's Hud Statement.
	 *
	 * @return				menuOpen value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property bool menuOpen {
		public get() {
			return rp_GetClientBool(this.index, b_menuOpen);
		}
		public set(bool stat) {
            rp_SetClientBool(this.index, b_menuOpen, stat);
        }
	}
	
	/**
	 * Returns or change the client's Admin Level.
	 *
	 * @return				Armor value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int zoneID {
		public get() {
			return rp_GetClientInt(this.index, i_ByteZone);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_ByteZone, value);
        }
	}
	
	/**
	 * Returns or change the client's money.
	 *
	 * @return				money value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int money {
		public get() {
			return rp_GetClientInt(this.index, i_Money);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Money, value);
        }
	}
	
	/**
	 * Returns or change the client's bank.
	 *
	 * @return				bank value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int bank {
		public get() {
			return rp_GetClientInt(this.index, i_Bank);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Bank, value);
        }
	}
	
	/**
	 * Returns or change the client's job.
	 *
	 * @return				job value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int jobID {
		public get() {
			return rp_GetClientInt(this.index, i_Job);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Job, value);
        }
	}
	
	/**
	 * Returns or change the client's job gradeID.
	 *
	 * @return				grade value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int gradeID {
		public get() {
			return rp_GetClientInt(this.index, i_Grade);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Grade, value);
        }
	}
	
	/**
	 * Returns or change the client's gang groupe ID.
	 *
	 * @return				groupe value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int gangID {
		public get() {
			return rp_GetClientInt(this.index, i_Group);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Group, value);
        }
	}

	/**
	 * Returns the client's send data rate in bytes/sec.
	 *
	 * @return				Data rate.
	 * @error				Invalid client index, client not connected, or fake client.
	 */
	property int DataRate {
		public get() {
			return GetClientDataRate(this.index);
		}
	}

	/**
	 * Returns the client's connection time in seconds.
	 *
	 * @return				Connection time.
	 * @error				Invalid client index, client not connected, or fake client.
	 */
	property float ConnectionTime {
		public get() {
			return GetClientTime(this.index);
		}
	}
	

	//=====================//
	//  F U N C T I O N S  //
	//=====================//
	
	/**
	 * Returns the client's zone name.
	 *
	 * @param name			Buffer to store the client's name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @return				Store the zonename on the first param.
	 * @error				If the client is not connected an error will be thrown.
	 */
	public void GetZone(char[] name, int maxlen) 
	{
		if(this.IsValid)
			rp_GetClientString(this.index, sz_Zone, name, maxlen);
	}
	
	/**
	 * Returns the client's jobname
	 *
	 * @param name			Buffer to store the client's name.
	 * @return				Store the jobname on the first param.
	 * @error				If the client is not connected an error will be thrown.
	 */
	public void JobName(char name[64]) 
	{
		GetJobName(rp_GetClientInt(this.index, i_Job), name);
	}

	/**
	 * Returns the client's name.
	 *
	 * @param name			Buffer to store the client's name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @return				True on success, false otherwise.
	 * @error				If the client is not connected an error will be thrown.
	 */
	public bool GetName(char[] name, int maxlen) {
		return GetClientName(this.index, name, maxlen);
	}

	/** 
	 * Sets access flags on a client using bits instead of flags.  If the
	 * client is not an admin, and flags not 0, a temporary, anonymous AdminId is given.
	 *
	 * @param flags			Bitstring of flags to set on client.
	 */
	public void SetFlagBits(int flags) {
	   SetUserFlagBits(this.index, flags);
	}

	/**
	 * Returns the client's model name.
	 *
	 * @param model			Buffer to store the client's model name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetModel(char[] model, int maxlen) {
		GetClientModel(this.index, model, maxlen);
	}

	/**
	 * Returns the client's weapon name.
	 *
	 * @param weapon		Buffer to store the client's weapon name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetWeapon(char[] weapon, int maxlen) {
		GetClientWeapon(this.index, weapon, maxlen);
	}

	/**
	 * Returns the client's position angle.
	 *
	 * @param ang			Destination vector to store the client's position angle.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetAngles(float ang[3]) {
	   GetClientAbsAngles(this.index, ang);
	}

	/**
	 * Returns the client's origin vector.
	 *
	 * @param vec			Destination vector to store the client's origin vector.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetOrigin(float vec[3]) {
		GetClientAbsOrigin(this.index, vec);
	}

	/**
	 * Changes a client's team through the mod's generic team changing function.
	 * On CS:S, this will kill the player.
	 *
	 * @param team			Mod-specific team index.
	 * @error				Invalid client index, client not connected, or lack of 
	 *						mod support.
	 */
	public void ChangeTeam(int team) {
		ChangeClientTeam(this.index, team);
	}

	public int SetItem(item_list prop, int value) 
	{
		rp_SetClientItem(this.index, prop, value);
	}
	
	public int GetItem(item_list prop) 
	{
		int value = rp_GetClientItem(this.index, prop);		
		return value;
	}
}