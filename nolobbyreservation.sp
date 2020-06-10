#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "No Lobby Reservation",
	author = "vanz",
	version = "0.0.2"
};

enum struct mem_patch
{
	Address addr;
	int len;
	char patch[256];
	char orig[256];

	bool Init(GameData conf, const char[] key, Address addr)
	{
		int offset, pos, curPos;
		char byte[16], bytes[512];
		
		if (this.len)
			return false;
		
		if (!conf.GetKeyValue(key, bytes, sizeof(bytes)))
			return false;
		
		offset = conf.GetOffset(key);
		
		if (offset == -1)
			offset = 0;
		
		this.addr = addr + view_as<Address>(offset);
		
		StrCat(bytes, sizeof(bytes), " ");
		
		while ((pos = SplitString(bytes[curPos], " ", byte, sizeof(byte))) != -1)
		{
			curPos += pos;
			
			TrimString(byte);
			
			if (byte[0])
			{
				this.patch[this.len] = StringToInt(byte, 16);
				this.orig[this.len] = LoadFromAddress(this.addr + view_as<Address>(this.len), NumberType_Int8);
				this.len++;
			}
		}
		
		return true;
	}
	
	void Apply()
	{
		for (int i = 0; i < this.len; i++)
			StoreToAddress(this.addr + view_as<Address>(i), this.patch[i], NumberType_Int8);
	}
	
	void Restore()
	{
		for (int i = 0; i < this.len; i++)
			StoreToAddress(this.addr + view_as<Address>(i), this.orig[i], NumberType_Int8);
	}
}

mem_patch g_isExclusiveToLobbyConnectionsPatch;
mem_patch g_replyChallengePatch1;
mem_patch g_replyChallengePatch2;
mem_patch g_replyChallengePatch3;
mem_patch g_replyChallengePatch4;

public void OnPluginStart()
{
	GameData conf = new GameData("nolobbyreservation.games");
	
	if (conf == null) 
		SetFailState("Failed to load nolobbyreservation gamedata");

	Address isExclusiveToLobbyConnectionsAddr = conf.GetAddress("CBaseServer::IsExclusiveToLobbyConnections");

	if (!isExclusiveToLobbyConnectionsAddr) 
		SetFailState("Failed to load CBaseServer::IsExclusiveToLobbyConnections signature from gamedata");

	Address replyChallengeAddr = conf.GetAddress("CBaseServer::ReplyChallenge");

	if (!replyChallengeAddr) 
		SetFailState("Failed to load CBaseServer::ReplyChallenge signature from gamedata");

	g_isExclusiveToLobbyConnectionsPatch.Init(conf, "CBaseServer::IsExclusiveToLobbyConnections_Patch", isExclusiveToLobbyConnectionsAddr);
	g_replyChallengePatch1.Init(conf, "CBaseServer::ReplyChallenge_Patch1", replyChallengeAddr);
	g_replyChallengePatch2.Init(conf, "CBaseServer::ReplyChallenge_Patch2", replyChallengeAddr);
	g_replyChallengePatch3.Init(conf, "CBaseServer::ReplyChallenge_Patch3", replyChallengeAddr);
	g_replyChallengePatch4.Init(conf, "CBaseServer::ReplyChallenge_Patch4", replyChallengeAddr);

	g_isExclusiveToLobbyConnectionsPatch.Apply();
	g_replyChallengePatch1.Apply();
	g_replyChallengePatch2.Apply();
	g_replyChallengePatch3.Apply();
	g_replyChallengePatch4.Apply();

	delete conf;
}

public void OnPluginEnd()
{
	g_isExclusiveToLobbyConnectionsPatch.Restore();
	g_replyChallengePatch1.Restore();
	g_replyChallengePatch2.Restore();
	g_replyChallengePatch3.Restore();
	g_replyChallengePatch4.Restore();
}
