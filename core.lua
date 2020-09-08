local RaidInvites = LibStub("AceAddon-3.0"):NewAddon("RaidInvites", "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")

local DEFAULTDB = {
    profile = {
        optionA = true,
        optionB = false,
        optionC = "hello2"
    }
}

function RaidInvites:OnInitialize()
    
    self.db = LibStub("AceDB-3.0"):New("RaidInvitesDB", DEFAULTDB, true)

    db = self.db.profile

	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileDeleted", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:Print(db.optionC)
    self.guildMembers = {} --stores all guild members
    self.guildRanks = {} --maps guild rank index to guild rank
    self.enabled = true
    self.minRank = "" --will be filled in GUILD_ROSTER_UPDATE
    
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("GUILD_ROSTER_UPDATE")

    GuildRoster()


    self.minRankEnabled = true-- invites only for members above this rank index
    self.minLevelEnabled = true -- invite only above a minimum level
    self.rankFilterResetTime_enabled = true -- disable rank requirements at a set time

    self.minLevel = 55
    self.rankFilterResetTime = {hour=17, min=40} -- stores the time rank filter is stripped
    
    local hourValues = {}
    local minuteValues = {}
    for i=0,23 do
        hourValues[i] = i
    end
    for i=1,59 do
        minuteValues[i] = i
    end

    self.keyWordList = {"inv", "invite", "hello", "hi"}
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
            test = {
                name = "func for testing",
                desc = "func for testing",
                type = "input",
                set = "testFunc",
                width = "full",
                get = function(info) return db.optionC end

            },
            enable = {
                name = "Enable",
                desc = "Enables/Disables the addon | Currently Enabled",
                type = "toggle",
                set = "toggleEnable",
                width = "full",
                get = function(info) return self.enabled end
            },
            keywords = {
                type = "input",
                name = "Invite Keywords (Comma Seperated)",
                desc = "The Message for raid invites",
                set = "setKeywords",
                width = 1.5,
                get = function(info) return strjoin(", ", unpack(self.keyWordList)) end
    
            },
            filterOptions = {
                name = "Filters",
                type = "group",
                cmdHidden = true,
                args = {
                    min_rank_enable = { 
                        type = "toggle",
                        name = "Minimum Rank Enabled",
                        desc = "Enables/Disables the minimum rank filter | Currently Enabled",
                        type = "toggle",
                        set = "toggleMinRank",
                        get = function(info) return self.minRankEnabled end,
                        order = 10,
                        width = "full"
                    },
                    set_min_rank = {
                        type = "select",
                        name = "Minimum Rank",
                        values = self:getRanks(),
                        desc = "set the minimum guild rank",
                        set  = "setMinRank",
                        get = function(info) return self.minRank end,
                        order = 11
    
                    },
                    min_level_enable = { 
                        type = "toggle",
                        name = "Minimum Level Filter Enabled",
                        desc = "Enables/Disables the minimum level filter | Currently Disabled",
                        set = "toggleMinLevel",
                        get = function(info) return self.minLevelEnabled end,
                        order = 20,
                        width = "full"
                    },
                    set_min_level = { --may need to be gui (check https://www.wowace.com/projects/ace3/pages/api/ace-config-dialog-3-0), this won't work in ace because it takes the 3rd arg no matter what, so /ri setguildrank core raider takes core - will work better in a frame
                        type = "range",
                        name = "Minimum Level",
                        min = 1,
                        max = 60,
                        step = 1,
                        desc = "set the minimum guild rank",
                        set  = "setMinLevel",
                        get = function(info) return self.minLevel end,
                        order = 21
                    },
                    rank_filter_reset_time_enable = {
                        type = "toggle",
                        name = "Rank Filter Reset Time Enabled",
                        desc = "Time for the rank filter to reset",
                        set = function(info) self.rankFilterResetTime_enabled = not self.rankFilterResetTime_enabled end,
                        get = function(info) return self.rankFilterResetTime_enabled end,
                        width = "full",
                        order = 30
                    },
                    set_rank_filter_reset_hour = {
                        type = "select",
                        name = "Hour",
                        values = hourValues,
                        desc = "Set the hour for rank filter reset",
                        set  = function(info, input) self.rankFilterResetTime.hour = input end,
                        get = function(info) return self.rankFilterResetTime.hour end,
                        width = 0.3,
                        order = 31
                    },
                    set_rank_filter_reset_minute = { 
                        type = "select",
                        name = "Min",
                        values = minuteValues,
                        desc = "Set the minute for rank filter reset",
                        set  = function(info, input) self.rankFilterResetTime.min = input end,
                        get = function(info) return self.rankFilterResetTime.min end,
                        width = 0.3,
                        order = 32
                    }
                   
                }
            },
        },
        

    }

    AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
    self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RaidInvites", "RaidInvites", "RaidInvites")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("RaidInvites", 450, 400)

end

function RaidInvites:testFunc(info, input)
    self:Print(input)
    self:Print(db.optionC)
    db.optionC = input
    self:Print(db.optionC)
    self:Print(self.db.profile.optionC)
end

function RaidInvites:RefreshConfig(event, db, prof)
    self:Print(self.db.profile.optionC)
    
	db = self.db.profile
	--ERA:KwordListToTable()
	--wipe(self.options)

	--self:IniOptions()
	--ERA:CreateMonitorUI()
	--ERA:CurrentMonitor()
end

function RaidInvites:openAddonPanel()
    LibStub("AceConfigDialog-3.0"):Open("RaidInvites")
end

function RaidInvites:setMinLevel(info, input)
    if(not self.minLevelEnabled) then
        self:toggleMinLevel("", true)
    end
    self.minLevel = input

end

function RaidInvites:setMinRank(info, input)
    if(not self.minRankEnabled) then
        self:toggleMinRank("", true)
    end
    self.minRank = input
end

function RaidInvites:getRanks(info, input)
    local output = {}
    for k,v in pairs(self.guildRanks) do
        output[v] = k
    end
    return output;

end

function RaidInvites:toggleMinLevel(info, input)
    self.minLevelEnabled = input
    self.optionsTable["args"]["filterOptions"]["args"]["min_level_enable"]["desc"] = self:printMinLevelEnableDesc(info)
    AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
end

-- following set of functions set the description in the options tables when options change
function RaidInvites:printEnableDesc(info)
    local enableDesc =  "Enables/Disables the addon | Currently "
    if (self.enabled) then 
       return enableDesc .. "Enabled" 
    else 
        return enableDesc .. "Disabled" 
    end
end

function RaidInvites:printMinRankEnableDesc(info)
    local enableDesc =  "Enables/Disables the minimum rank filter | Currently "
    if (self.minRankEnabled) then 
       return enableDesc .. "Enabled" 
    else 
        return enableDesc .. "Disabled" 
    end
end

function RaidInvites:printMinLevelEnableDesc(info)
    local enableDesc =  "Enables/Disables the minimum level filter | Currently "
    if (self.minLevelEnabled) then 
       return enableDesc .. "Enabled" 
    else 
        return enableDesc .. "Disabled" 
    end
end

-------

function RaidInvites:toggleMinRank(info, input)
    self.minRankEnabled = input
    self.optionsTable["args"]["filterOptions"]["args"]["min_rank_enable"]["desc"] = self:printMinRankEnableDesc(info)
    AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
end

function RaidInvites:toggleEnable(info, input)
    self.enabled = input
    if(input) then
        self:RegisterEvent("CHAT_MSG_WHISPER")
    else
        self:UnregisterEvent("CHAT_MSG_WHISPER")
    end
    self.optionsTable["args"]["enable"]["desc"] = self:printEnableDesc(info);
    AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
end

function RaidInvites:setKeywords(info, input) -- takes keywords as 1 string (delimited by ,)
    if(input) then
        self.keyWordList = {}
        for w in input:gmatch("([^,]+)") do 
            if(w) then
                table.insert(self.keyWordList, strtrim(w, " "))
            end
        end
    end
end

function RaidInvites:checkKeyword(input)
    for k, v in pairs(self.keyWordList) do
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
    return (tonumber(self.guildMembers[memberName]["memberRankIndex"]) <= tonumber(self.minRank))
end

function RaidInvites:checkLevel(memberName)
    return (self.guildMembers[memberName]["memberLvl"] >= self.minLevel)
end

function RaidInvites:checkEligibility(sender)
    if(not self:checkInGuild(sender)) then
        self:Print(sender .. "not in guild")
        return false
    end
    if(self.minRankEnabled) then
        if(not self:checkRankIndex(sender)) then
            self:Print(sender .. "not right rank index")
            return false
        end
    end
    if(self.minLevelEnabled) then
        if(not self:checkLevel(sender)) then
            self:Print(sender .. "not right level")
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
    if((curTimeHr * 60 + curTimeMin) > (tonumber(self.rankFilterResetTime.hour) * 60 + tonumber(self.rankFilterResetTime.min)) and self.minRankEnabled and self.rankFilterResetTime_enabled) then
        self:toggleMinRank("",false)
        self:Print("Rank filter reset time reached! Disabling minimum rank filter")
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
    if(GetNumGuildMembers() > 0) then
        self.minRank = self.guildRanks[self:getRanks()[5]]
        self:UnregisterEvent("GUILD_ROSTER_UPDATE")

        self.optionsTable["args"]["filterOptions"]["args"]["set_min_rank"]["values"] = self:getRanks();
        AceConfig:RegisterOptionsTable("RaidInvites", self.optionsTable, {"ri"})
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