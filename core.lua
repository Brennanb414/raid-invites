local RaidInvites = LibStub("AceAddon-3.0"):NewAddon("RaidInvites", "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local DEFAULTDB = {
    profile = {
        enabled = true,
        minRank = 1,
        minRankEnabled = true,-- invites only for members above the min rank index
        minLevelEnabled = true, -- invite only above a minimum level
        rankFilterResetTime_enabled = true, -- disable rank requirements at a set time
        minLevel = 55,
        rankFilterResetTime = {hour=17, min=40},
        keywordList = {"inv", "invite", "hello", "hi"}

    }
}

function RaidInvites:OnInitialize()
    
    self.db = LibStub("AceDB-3.0"):New("RaidInvitesDB", DEFAULTDB, true)
    self.guildMembers = {} --stores all guild members
    self.guildRanks = {} --maps guild rank index to guild rank
    if(self.db.profile.enabled) then
        self:RegisterEvent("CHAT_MSG_WHISPER")
    end
    self:RegisterEvent("GUILD_ROSTER_UPDATE")

    --GuildRoster() -- refresh guild roster once loaded
    
    self.hourValues = {}
    self.minuteValues = {}
    for i=0,23 do
        self.hourValues[i] = i
    end
    for i=1,59 do
        self.minuteValues[i] = i
    end

    
    self:setOptionsTable() -- set and register main options table
    self.profilesFrame = AceConfigDialog:AddToBlizOptions("RaidInvites", "RaidInvites", "RaidInvites")
    AceConfigDialog:SetDefaultSize("RaidInvites", 450, 400)

end

function RaidInvites:RefreshConfig(event, db, prof)
    self:setOptionsTable()
    AceConfigRegistry:NotifyChange("RaidInvites")
end

function RaidInvites:setOptionsTable()
    self.optionsTable = {
        name = "RaidInvites",
        handler = RaidInvites,
        type = "group",
        args = {
            open = {
                name = "Open",
                desc = "Opens addon panel",
                type = "execute",
                func = "openAddonPanel",
                guiHidden = true
            },
            enable = {
                name = "Enable",
                desc = "Enables/Disables the addon",
                type = "toggle",
                set = "toggleEnable",
                width = "full",
                get = function(info) return self.db.profile.enabled end
            },
            keywords = {
                type = "input",
                name = "Invite Keywords (Comma Seperated)",
                desc = "The Message for raid invites",
                set = "setKeywords",
                width = 1.5,
                get = function(info) return strjoin(", ", unpack(self.db.profile.keywordList)) end
    
            },
            filterOptions = {
                name = "Filters",
                type = "group",
                cmdHidden = true,
                args = {
                    min_rank_enable = { 
                        type = "toggle",
                        name = "Minimum Rank Enabled",
                        desc = "Enables/Disables the minimum rank filter",
                        type = "toggle",
                        set = "toggleMinRank",
                        get = function(info) return self.db.profile.minRankEnabled end,
                        order = 10,
                        width = "full"
                    },
                    set_min_rank = {
                        type = "select",
                        name = "Minimum Rank",
                        values = self:getRanks(),
                        desc = "set the minimum guild rank",
                        set  = "setMinRank",
                        get = function(info) return self.db.profile.minRank end,
                        order = 11
    
                    },
                    min_level_enable = { 
                        type = "toggle",
                        name = "Minimum Level Filter Enabled",
                        desc = "Enables/Disables the minimum level filter",
                        set = "toggleMinLevel",
                        get = function(info) return self.db.profile.minLevelEnabled end,
                        order = 20,
                        width = "full"
                    },
                    set_min_level = { 
                        type = "range",
                        name = "Minimum Level",
                        min = 1,
                        max = 60,
                        step = 1,
                        desc = "set the minimum guild rank",
                        set  = "setMinLevel",
                        get = function(info) return self.db.profile.minLevel end,
                        order = 21
                    },
                    rank_filter_reset_time_enable = {
                        type = "toggle",
                        name = "Rank Filter Reset Time Enabled",
                        desc = "Time for the rank filter to reset",
                        set = function(info) self.db.profile.rankFilterResetTime_enabled = not self.db.profile.rankFilterResetTime_enabled end,
                        get = function(info) return self.db.profile.rankFilterResetTime_enabled end,
                        width = "full",
                        order = 30
                    },
                    set_rank_filter_reset_hour = {
                        type = "select",
                        name = "Hour",
                        values = self.hourValues,
                        desc = "Set the hour for rank filter reset",
                        set  = function(info, input) self.db.profile.rankFilterResetTime.hour = input end,
                        get = function(info) return self.db.profile.rankFilterResetTime.hour end,
                        width = 0.4,
                        order = 31
                    },
                    set_rank_filter_reset_minute = { 
                        type = "select",
                        name = "Min",
                        values = self.minuteValues,
                        desc = "Set the minute for rank filter reset",
                        set  = function(info, input) self.db.profile.rankFilterResetTime.min = input end,
                        get = function(info) return self.db.profile.rankFilterResetTime.min end,
                        width = 0.4,
                        order = 32
                    }
                   
                }
            },
        },
        

    }
    AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
end

function RaidInvites:openAddonPanel()
    AceConfigDialog:Open("RaidInvites")
end

function RaidInvites:setMinLevel(info, input)
    if(not self.db.profile.minLevelEnabled) then
        self:toggleMinLevel("", true)
    end
    self.db.profile.minLevel = input

end

function RaidInvites:setMinRank(info, input)
    if(not self.db.profile.minRankEnabled) then
        self:toggleMinRank("", true)
    end
    self.db.profile.minRank = input
end

function RaidInvites:getRanks(info, input)
    local output = {}
    for k,v in pairs(self.guildRanks) do
        output[v] = k
    end
    return output;

end

function RaidInvites:toggleMinLevel(info, input)
    self.db.profile.minLevelEnabled = input
end

function RaidInvites:toggleMinRank(info, input)
    self.db.profile.minRankEnabled = input
end

function RaidInvites:toggleEnable(info, input)
    self.db.profile.enabled = input
    if(input) then
        self:RegisterEvent("CHAT_MSG_WHISPER")
    else
        self:UnregisterEvent("CHAT_MSG_WHISPER")
    end
end

function RaidInvites:setKeywords(info, input) -- takes keywords as 1 string (delimited by ,)
    if(input) then
        self.db.profile.keywordList = {}
        for w in input:gmatch("([^,]+)") do 
            if(w) then
                table.insert(self.db.profile.keywordList, strtrim(w, " "))
            end
        end
    end
end

function RaidInvites:checkKeyword(input)
    for k, v in pairs(self.db.profile.keywordList) do
        if(string.lower(input) == string.lower(v)) then
            return true
        end
    end
    return false
end

function RaidInvites:checkInGuild(memberName)
    for k in pairs(self.guildMembers) do
        if(memberName == k) then
            return true
        end
    end
    return false
end

function RaidInvites:checkRankIndex(memberName)
    return (tonumber(self.guildMembers[memberName]["memberRankIndex"]) <= tonumber(self.db.profile.minRank))
end

function RaidInvites:checkLevel(memberName)
    return (self.guildMembers[memberName]["memberLvl"] >= self.db.profile.minLevel)
end

function RaidInvites:checkEligibility(sender)
    if(not self:checkInGuild(sender)) then
        self:Print(sender .. " not in guild")
        return false
    end
    if(self.db.profile.minRankEnabled) then
        if(not self:checkRankIndex(sender)) then
            self:Print(sender .. " not right rank")
            return false
        end
    end
    if(self.db.profile.minLevelEnabled) then
        if(not self:checkLevel(sender)) then
            self:Print(sender .. " not right level")
            return false
        end
    end
    return true
end

function RaidInvites:tryConvertStringToTime(timeString)
    local timeHr, timeMin = strsplit(":", timeString)
    if(1 <= tonumber(timeHr) and tonumber(timeHr) <= 23 and 1 <= tonumber(timeMin) and tonumber(timeMin) <= 60) then
        return tonumber(timeHr), tonumber(timeMin)
    else
        self:Print("ERROR:Incorrect time input for hours - must be in 24hr format HH:mm")
    end
end

function RaidInvites:checkTimeAndUpdate()
    local curTimeHr, curTimeMin = GetGameTime();
    if((curTimeHr * 60 + curTimeMin) > (tonumber(self.db.profile.rankFilterResetTime.hour) * 60 + tonumber(self.db.profile.rankFilterResetTime.min)) and self.db.profile.minRankEnabled and self.db.profile.rankFilterResetTime_enabled) then
        self:toggleMinRank("",false)
        self:Print("Rank filter reset time reached! Disabling minimum rank filter")
        AceConfigRegistry:NotifyChange("RaidInvites")
    end

end

function RaidInvites:CHAT_MSG_WHISPER(event, txt, sender)
    self:checkTimeAndUpdate()
    if(self:checkKeyword(txt)) then
        if(self:checkEligibility(strsplit("-",sender))) then
            InviteUnit(strsplit("-",sender))
        end
    end
end

function RaidInvites:GUILD_ROSTER_UPDATE()
    self:storeGuildMembers()
    if(GetNumGuildMembers() > 0) then -- store current members then refresh
        self:RefreshConfig();
    end
end

function RaidInvites:storeGuildMembers()
    local newGuildMembers = {}
    local numGuildMembers = GetNumGuildMembers()
    for i=1, numGuildMembers do
        
        memberName, memberRank, memberRankIndex, memberLvl = GetGuildRosterInfo(i)
        newGuildMembers[strsplit("-", memberName)] = {
            ["memberRank"] = memberRank,
            ["memberRankIndex"] = memberRankIndex,
            ["memberLvl"] = memberLvl
        }
        self.guildRanks[memberRank] = memberRankIndex
    end
    self.guildMembers = newGuildMembers
end