-- 관리 대상이 아닌 캐릭터
local exclude_member = {"예외", "캐릭터", "이름"}
-- 관리 대상이 아닌 등급 (길드 마스터가 0, 그 아래로 9 등급까지)
local exclude_rank = { 
	0, -- 길드 마스터
}

-- 등급 규칙
local rank_rule = {
	[5] = 20000000, 
	[6] = 10000000, 
	[7] =  5000000, 
	[8] =  2500000, 
}

SLASH_GUILDROSTERMANAGER1, SLASH_GUILDROSTERMANAGER2= "/grm", "/guildrostermanager";

local function GuildRosterManager_HandleSlashCmd(msg, editbox)
    print("Start to check guild members...");
	GuildRosterManagerMain(true);
    print("Checking done.");
end

SlashCmdList["GUILDROSTERMANAGER"] = GuildRosterManager_HandleSlashCmd;


local rank_queue = {};
local timer = 0;
local running = false;
local frame = CreateFrame("FRAME", "GuildRosterManagerFrame");
frame:RegisterEvent("GUILD_ROSTER_UPDATE");

local function GuildRosterManager_OnEvent(self, event, ...)
	if event == "GUILD_ROSTER_UPDATE" then
		if running == false and #rank_queue <= 0 then
			GuildRosterManagerMain(false);
		end
	end
end

frame:SetScript("OnEvent", GuildRosterManager_OnEvent);

function GuildRosterManager() 
    print("Good luck to all guild masters.");
    print("Please, type /grm or /guildrostermanager to manage rank of guild members.");
end

function GuildRosterManager_OnUpdate(self, elapsed)
    timer = timer + elapsed;
    if timer >= 0.5 then
		if #rank_queue > 0 then
			local member = table.remove(rank_queue);
			PromoteOrDemote(member[1], member[2]);
		else
			frame:SetScript("OnUpdate", nil)
			running = false;
		end
        timer = 0;
    end
end

function GuildRosterManagerMain(slashcmd) 
	if running then
		if slashcmd then
            print("Sorry. It's already running.");
        end
		return;
	end
	running = true;
    if ( not CanManageGuildRoster() ) then
        running = false;
    else
        showoffline = GetGuildRosterShowOffline();
		SetGuildRosterShowOffline(true);
		ManageGuildRoster();
		SetGuildRosterShowOffline(showoffline);
        frame:SetScript("OnUpdate", GuildRosterManager_OnUpdate);
    end
end 

function CanManageGuildRoster() 
	if not IsInGuild() then
		return false;
	end
   
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
    if guildName == nil or guildRankIndex ~= 0 then
        return false;
    end

    return true;
end

function ManageGuildRoster()
    local numTotalMembers, numOnlineMembers = GetNumGuildMembers();
    for index = 1, numTotalMembers do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(index);
		local weeklyXP, totalXP, weeklyRank, totalRank = GetGuildRosterContribution(index);
        SetGuildRank(index, name, rankIndex, totalXP);
    end
end

function SetGuildRank(index, name, rankIndex, totalXP)
	if IsExcludeMember(name, rankIndex) then
		return;
	end
	local newRankIndex = GetNewRankIndex(totalXP);
	if rankIndex ~= newRankIndex then
		SetMemberRank(index, name, rankIndex, newRankIndex);
	end
end

function IsExcludeMember(name, rankIndex)
	for k, v in pairs(exclude_member) do
		if v == name then
			return true;
		end
	end

	for k, v in pairs(exclude_rank) do
		if v == rankIndex then
			return true;
		end
	end

	return false;
end

function GetNewRankIndex(totalXP)
	local newRankIndex = 9;

	for k, v in pairs(rank_rule) do
		if totalXP >= v and newRankIndex > k then
			newRankIndex = k;
		end		
	end

	return newRankIndex;
end

function SetMemberRank(index, name, rankIndex, newRankIndex)
	print(name.." - "..GuildControlGetRankName(rankIndex + 1).." => "..GuildControlGetRankName(newRankIndex + 1));
	for i = 1, abs(rankIndex - newRankIndex) do
		if rankIndex < newRankIndex then
			table.insert(rank_queue, {name, 1});
		elseif rankIndex > newRankIndex then
			table.insert(rank_queue, {name, -1});
		else
			print("DAMN!!");
		end
	end	
end

function PromoteOrDemote(name, rankDirection)
	if rankDirection > 0 then
		GuildDemote(name)
	elseif rankDirection < 0 then
		GuildPromote(name);
	else
		print("DAMN!!");
	end
end
