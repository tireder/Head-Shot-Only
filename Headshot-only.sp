#pragma semicolon 1
#pragma tabsize 0
#define DEBUG
#define PREFIX " \x04[Only Head Shot Event]\x01"
#define cooldown g_cvCooldownTime.FloatValue

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

ConVar mp_damage_headshot_only;
ConVar g_cvAllowKnifeDamage;
bool IsActive = false;
bool AlreadyUsed[MAXPLAYERS + 1];
int CurrentPlayersAmount = 0;
int WantToActivate;
int WantToDisable;
Handle CommandHandle[MAXPLAYERS + 1];
ConVar g_cvCooldownTime;
ConVar g_cvSpecIsValid;
ConVar g_cvAutoDisable;
int RoundsCounter=0;
public Plugin myinfo = 
{
	name = "Only HeadShot Event / Vote",
	author = "Tired",
	description = " Only HeadShot Event for Csgo servers",
	version = "1.0",
	url = "http://tired-dev.xyz"
};

public void OnPluginStart()
{
	g_cvAllowKnifeDamage = CreateConVar("sm_allow_knife_damage", "0", "1-Enables 0-Disables knife damage if the Only Headshot is enabled.");
	g_cvCooldownTime = CreateConVar("sm_cooldown_time", "5.0", "Cooldown for the VoteHeadShot command. Usage: The amount of second between each try of the command . 0.0-Disable.");
	g_cvSpecIsValid = CreateConVar("sm_spec_is_valid", "0", "1-Enables 0-Disables spectators's option to use the vote command and to be counted as a player.");
	g_cvAutoDisable = CreateConVar("sm_auto_disable_after_x_rounds", "-1", "-1 = Doesnt Disable the Only Headshot after any amount of rounds. Any other amount Disables the Only Headshot after the amount of rounds set.");
	HookEvent("round_start", OnRoundStart);
	mp_damage_headshot_only = FindConVar("mp_damage_headshot_only");
   // RegConsoleCmd("sm_vh", VoteHs, "Enable/Disable your decision for the Vote HeadShot."); // uncomment for vote
    //RegConsoleCmd("sm_voteheadshot", VoteHs, "Enable/Disable your decision for the Vote HeadShot."); // uncomment for vote
  // RegConsoleCmd("sm_votehs", VoteHs, "Enable/Disable your decision for the Vote HeadShot."); // uncomment for vote
   //RegConsoleCmd("sm_cvh", CVoteHs, "Showing the currrent status of the Vote HeadShot."); // uncomment for vote
    RegAdminCmd("sm_eh", FVoteHs,ADMFLAG_GENERIC, "start or stop  Only HeadShot event.");
    Reg
    
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i)) 
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamageHook);
    }
    AutoExecConfig(true, "Retakes_VoteHeadShot");
}
public Action FVoteHs(int client,int args)
{
	if (args > 0)
		return Plugin_Handled;
	if(!IsActive)
	{
		IsActive = true;
		CPrintToChatAll("%s Event Started Only HeadShot will be \x04Activated!\x01 next round",PREFIX);
	}
	else
	{
		IsActive = false;
		CPrintToChatAll("%s Event stoped Only HeadShot will be \x07Disabled!\x01 next round",PREFIX);
	}
return Plugin_Handled;
}
// uncomment this section for voting
/*public Action CVoteHs(int client,int args)
{
	if (args > 0)
		return Plugin_Handled;
	for(int i = 1; i <= MaxClients;i++)
	{
		if(g_cvSpecIsValid.IntValue==1)
		{
			if(IsClientInGame(i)&&!IsFakeClient(i))
				CurrentPlayersAmount++;
		}
		else if(g_cvSpecIsValid.IntValue==0)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1)
				CurrentPlayersAmount++;
		}
	}
	if(!IsActive)
		CPrintToChat(client,"%s \x0C%i\x01 players want to \x04Enable\x01 Only HeadShot out of \x07%i\x01 needed.",PREFIX,WantToActivate,(1+(CurrentPlayersAmount / 2)));
	if(IsActive)
		CPrintToChat(client,"%s \x0C%i\x01 players want to \x07Disable\x01 Only HeadShot out of \x07%i\x01 needed.",PREFIX,WantToDisable,(1+(CurrentPlayersAmount / 2)));
CurrentPlayersAmount = 0;
return Plugin_Handled;
}
public void OnClientDisconnect(int client)
{
	if(IsActive&&AlreadyUsed[client])
	{
		AlreadyUsed[client]=false;
		WantToDisable--;
	}
	if(!IsActive&&AlreadyUsed[client])
	{
		AlreadyUsed[client]=false;
		WantToActivate--;
	}
} 
public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients;i++)
	{
		if(IsClientInGame(i)&&!IsFakeClient(i))
			AlreadyUsed[i] = false;
	}
	CurrentPlayersAmount = 0;
	WantToActivate = 0;
	WantToDisable = 0;
	IsActive = false;
} 
public Action VoteHs(int client,int args)
{
	if (CommandHandle[client] != null)
	{
	 int time = RoundFloat(cooldown);
	 CPrintToChat(client,"%s You have to wait \x07%d\x01 seconds before trying to use this command again",PREFIX,time);
     return Plugin_Handled;
    }
	CommandHandle[client] = CreateTimer(cooldown , TimerFunction,client);
	if (GetClientTeam(client)==1&&g_cvSpecIsValid.IntValue==0)
	{
		CPrintToChat(client,"%s You \x07cannot\x01 use this command since you are a spectator",PREFIX);
		return Plugin_Handled;
	}
	if (args > 0)
		return Plugin_Handled;
	for(int i = 1; i <= MaxClients;i++)
	{
		if(g_cvSpecIsValid.IntValue==1)
		{
			if(IsClientInGame(i)&&!IsFakeClient(i))
				CurrentPlayersAmount++;
		}
		else if(g_cvSpecIsValid.IntValue==0)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1)
				CurrentPlayersAmount++;
		}
	}
	if(!IsActive&&!AlreadyUsed[client])
	{
		WantToActivate++;
		CPrintToChatAll("%s \x0C%N\x01 wants to \x04Enable\x01 Only HeadShot. \x0C(\x04%i\x01/\x07%i\x0C)",PREFIX,client,WantToActivate,(1+(CurrentPlayersAmount / 2)));	
		AlreadyUsed[client] = true;
		if(WantToActivate>(CurrentPlayersAmount / 2))
		{
			IsActive = true;
			CPrintToChatAll("%s Only HeadShot will be \x04Activated!\x01 next round",PREFIX);
			WantToActivate = 0;
			for(int i = 1; i <= MaxClients;i++)
			AlreadyUsed[i] = false;
		}
	}
	else if(!IsActive&&AlreadyUsed[client])
	{
		AlreadyUsed[client] = false;
		WantToActivate--;
		CPrintToChatAll("%s \x0C%N\x01 \x07Devoted\x01 Only HeadShot. \x0C(\x04%i\x01/\x07%i\x0C)",PREFIX,client,WantToActivate,(1+(CurrentPlayersAmount / 2)));
	}
	else if(IsActive&&!AlreadyUsed[client])
	{
		WantToDisable++;
		CPrintToChatAll("%s \x0C%N\x01 wants to \x07Disable\x01 Only HeadShot. \x0C(\x04%i\x01/\x07%i\x0C)",PREFIX,client,WantToDisable,(1+(CurrentPlayersAmount / 2)));
		AlreadyUsed[client] = true;
		if(WantToDisable>(CurrentPlayersAmount / 2))
		{	
			IsActive = false;
			CPrintToChatAll("%s Only HeadShot will be \x07Disabled!\x01 next round",PREFIX);
			WantToDisable = 0;
			for(int i = 1; i <= MaxClients;i++)
			AlreadyUsed[i] = false;
		}			
	}
	else if(IsActive&&AlreadyUsed[client])
	{
		AlreadyUsed[client] = false;
		WantToDisable--;
		CPrintToChatAll("%s \x0C%N\x01 \x07Devoted\x01 Only HeadShot. \x0C(\x04%i\x01/\x07%i\x0C)",PREFIX,client,WantToDisable,(1+(CurrentPlayersAmount / 2)));
	}
CurrentPlayersAmount = 0;
return Plugin_Handled;
} */

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(IsActive&&g_cvAutoDisable.IntValue==-1)
	{
		SetConVarInt(mp_damage_headshot_only, 1);
		CPrintToChatAll("%s Only HeadShot event is \x04Activated!\x01",PREFIX);
		PrintCenterTextAll("Only HeadShot event is Activated!");
	}
	else if(!IsActive)
	SetConVarInt(mp_damage_headshot_only, 0);
	if(IsActive)
	{
		if(g_cvAutoDisable.IntValue==RoundsCounter)
		{
			SetConVarInt(mp_damage_headshot_only, 0);
			CPrintToChatAll("%s Only HeadShot event is \x07Disabled!\x01",PREFIX);
			PrintCenterTextAll("Only HeadShot event is Disabled!");
			IsActive = false;
			RoundsCounter = 0;
		}
		else if(g_cvAutoDisable.IntValue!=-1)
		{
			RoundsCounter++;
			SetConVarInt(mp_damage_headshot_only, 1);
			CPrintToChatAll("%s Only HeadShot event will be \x04Activated\x01 for \x07%i\x01 more rounds.",PREFIX,1+g_cvAutoDisable.IntValue-RoundsCounter);
			PrintCenterTextAll("Only HeadShot  event will be Activated for %i more rounds.",1+g_cvAutoDisable.IntValue-RoundsCounter);
		}		
	}
}
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
}
public Action OnTakeDamageHook(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ((client>=1) && (client<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor) && (g_cvAllowKnifeDamage.IntValue==0) && (IsActive))
    {
        char WeaponName[64];
        GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        if (StrContains(WeaponName, "knife", false) != -1||StrContains(WeaponName, "bayonet", false) != -1)
        {
            damage = 0.0;
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
public Action TimerFunction(Handle timer,int client)
{
	CommandHandle[client] = null;
    return Plugin_Handled;
}