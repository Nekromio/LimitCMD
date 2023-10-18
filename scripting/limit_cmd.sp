#pragma semicolon 1
#pragma newdecls required

ConVar
	cvEnable,
	cvFloodCheck,
	cvCountCmd;

Handle
	hTimerFlood[MAXPLAYERS+1];

bool
	bLogsSay[MAXPLAYERS+1];

int
	iCountUse[MAXPLAYERS+1];
	
float
	fFloodCount[MAXPLAYERS+1];

char
	sFile[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Limit CMD",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Anti-Flood/Анти спам командами",
	version = "1.0.1",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	cvEnable = CreateConVar("sm_cmd_flood_enable", "1", "Включить/Выключить плагин", _, true, 0.0, true, 1.0);
	
	cvFloodCheck = CreateConVar("sm_cmd_flood_time", "1.5", "В какой период времени делать проверку");
	
	cvCountCmd = CreateConVar("sm_cmd_flood_count", "35", "Какое количество команд можно отправить в разрешенный период премени");
	
	AutoExecConfig(true, "limit_cmd");
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/limit_cmd.log");
}

public void OnClientConnected(int client)
{
	iCountUse[client] = 0;
	bLogsSay[client] = false;
	
	delete hTimerFlood[client];
}

public Action OnClientCommand(int client, int args)
{
	if(!cvEnable.BoolValue)
		return Plugin_Continue;
		
	if(!IsValideClient(client))
		return Plugin_Continue;
	
	if(fFloodCount[client] > GetGameTime() - cvFloodCheck.FloatValue && iCountUse[client] >= cvCountCmd.IntValue)
	{
		if(!bLogsSay[client])
		{
			char sSteam[32], ip[16];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			GetClientIP(client, ip, sizeof(ip));

			bLogsSay[client] = true;
			LogToFile(sFile, "Игрок [%s] [%s] [%N] был кикнут за превышения лимита команда [%d] в [%.2f] секунд", ip, sSteam, client, iCountUse[client], cvFloodCheck.FloatValue);
		}
		KickClient(client, "[Anti-Flood] Вы привысили лимит спама команд !");
		return Plugin_Handled;
	}
	else
	{
		delete hTimerFlood[client];
		hTimerFlood[client] = CreateTimer(cvFloodCheck.FloatValue, Timer_UnTimeClient, GetClientUserId(client));
	}
	
	iCountUse[client]++;
	fFloodCount[client] = GetGameTime();
	
	return Plugin_Continue;
}

Action Timer_UnTimeClient(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)))
    {
		iCountUse[client] = 0;
		hTimerFlood[client] = null;
	}
	return Plugin_Stop;
}

bool IsValideClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}