-- @module lia.char
-- @moduleCommentStart
-- Library functions for character
-- @moduleCommentEnd
-- Create the character metatable.
local CHAR = lia.meta.character or {}
CHAR.__index = CHAR
CHAR.id = CHAR.id or 0
CHAR.vars = CHAR.vars or {}
debug.getregistry().Character = lia.meta.character -- hi mark

-- Called when the character is being printed as a string.
function CHAR:__tostring()
    return "character[" .. (self.id or 0) .. "]"
end

-- Checks if two character objects represent the same character.
function CHAR:__eq(other)
    return self:getID() == other:getID()
end

-- Returns the character index from the database.
function CHAR:getID()
    return self.id
end

function CHAR:GetID()
    return self.id
end

if SERVER then
    -- @type method Character:save(callback)
    -- @typeCommentStart
    -- Saves the character to the database and calls the callback if provided.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    -- @function callback Callback when character saved on database
    function CHAR:save(callback)
        -- Do not save if the character is for a bot.
        if self.isBot then return end
        -- Prepare a list of information to be saved.
        local data = {}

        -- Save all the character variables.
        for k, v in pairs(lia.char.vars) do
            if v.field and self.vars[k] ~= nil then
                data[v.field] = self.vars[k]
            end
        end

        -- Let plugins/schema determine if the character should be saved.
        local shouldSave = hook.Run("CharacterPreSave", self)

        if shouldSave ~= false then
            -- Run a query to save the character to the database.
            lia.db.updateTable(data, function()
                if callback then
                    callback()
                end

                hook.Run("CharacterPostSave", self)
            end, nil, "_id = " .. self:getID())
        end
    end

    function CHAR:Save(callback)
        -- Do not save if the character is for a bot.
        if self.isBot then return end
        -- Prepare a list of information to be saved.
        local data = {}

        -- Save all the character variables.
        for k, v in pairs(lia.char.vars) do
            if v.field and self.vars[k] ~= nil then
                data[v.field] = self.vars[k]
            end
        end

        -- Let plugins/schema determine if the character should be saved.
        local shouldSave = hook.Run("CharacterPreSave", self)

        if shouldSave ~= false then
            -- Run a query to save the character to the database.
            lia.db.updateTable(data, function()
                if callback then
                    callback()
                end

                hook.Run("CharacterPostSave", self)
            end, nil, "_id = " .. self:getID())
        end
    end

    -- @type method Character:sync(receiver)
    -- @typeCommentStart
    -- Sends character information to the receiver.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    -- @player receiver who will receive synchronization, nil - so that all players receive.
    function CHAR:sync(receiver)
        -- Broadcast the character information if receiver is not set.
        if receiver == nil then
            for k, v in ipairs(player.GetAll()) do
                self:sync(v)
            end
            -- Send all character information if the receiver is the character's owner.
        elseif receiver == self.player then
            local data = {}

            for k, v in pairs(self.vars) do
                if lia.char.vars[k] ~= nil and not lia.char.vars[k].noNetworking then
                    data[k] = v
                end
            end

            netstream.Start(self.player, "charInfo", data, self:getID())

            for k, v in pairs(lia.char.vars) do
                if isfunction(v.onSync) then
                    v.onSync(self, self.player)
                end
            end
        else -- Send public character information to the receiver.
            local data = {}

            for k, v in pairs(lia.char.vars) do
                if not v.noNetworking and not v.isLocal then
                    data[k] = self.vars[k]
                end
            end

            netstream.Start(receiver, "charInfo", data, self:getID(), self.player)

            for k, v in pairs(lia.char.vars) do
                if type(v.onSync) == "function" then
                    v.onSync(self, receiver)
                end
            end
        end
    end

    function CHAR:Sync(receiver)
        -- Broadcast the character information if receiver is not set.
        if receiver == nil then
            for k, v in ipairs(player.GetAll()) do
                self:sync(v)
            end
            -- Send all character information if the receiver is the character's owner.
        elseif receiver == self.player then
            local data = {}

            for k, v in pairs(self.vars) do
                if lia.char.vars[k] ~= nil and not lia.char.vars[k].noNetworking then
                    data[k] = v
                end
            end

            netstream.Start(self.player, "charInfo", data, self:getID())

            for k, v in pairs(lia.char.vars) do
                if isfunction(v.onSync) then
                    v.onSync(self, self.player)
                end
            end
        else -- Send public character information to the receiver.
            local data = {}

            for k, v in pairs(lia.char.vars) do
                if not v.noNetworking and not v.isLocal then
                    data[k] = self.vars[k]
                end
            end

            netstream.Start(receiver, "charInfo", data, self:getID(), self.player)

            for k, v in pairs(lia.char.vars) do
                if type(v.onSync) == "function" then
                    v.onSync(self, receiver)
                end
            end
        end
    end

    -- @type method Character:setup(noNetworking)
    -- @typeCommentStart
    -- Sets up the "appearance" related information for the character.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    -- @bool noNetworking responsible for character synchronization
    function CHAR:setup(noNetworking)
        local client = self:getPlayer()

        if IsValid(client) then
            -- Set the faction, model, and character index for the player.
            client:SetModel(isstring(self:getModel()) and self:getModel() or self:getModel()[1])
            client:SetTeam(self:getFaction())
            client:setNetVar("char", self:getID())

            -- Apply saved body groups.
            for k, v in pairs(self:getData("groups", {})) do
                client:SetBodygroup(k, v)
            end

            -- Apply a saved skin.
            client:SetSkin(self:getData("skin", 0))

            -- Synchronize the character if we should.
            if not noNetworking then
                for k, v in ipairs(self:getInv(true)) do
                    if istable(v) then
                        v:sync(client)
                    end
                end

                self:sync()
            end

            hook.Run("CharacterLoaded", self:getID())
            self.firstTimeLoaded = true
        end
    end

    function CHAR:Setup(noNetworking)
        local client = self:getPlayer()

        if IsValid(client) then
            -- Set the faction, model, and character index for the player.
            client:SetModel(isstring(self:getModel()) and self:getModel() or self:getModel()[1])
            client:SetTeam(self:getFaction())
            client:setNetVar("char", self:getID())

            -- Apply saved body groups.
            for k, v in pairs(self:getData("groups", {})) do
                client:SetBodygroup(k, v)
            end

            -- Apply a saved skin.
            client:SetSkin(self:getData("skin", 0))

            -- Synchronize the character if we should.
            if not noNetworking then
                for k, v in ipairs(self:getInv(true)) do
                    if istable(v) then
                        v:sync(client)
                    end
                end

                self:sync()
            end

            hook.Run("CharacterLoaded", self:getID())
            self.firstTimeLoaded = true
        end
    end

    -- @type method Character:kick()
    -- @typeCommentStart
    -- Forces the player to choose a character.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    function CHAR:kick()
        -- Kill the player so they are not standing anywhere.
        local client = self:getPlayer()
        client:KillSilent()
        local steamID = client:SteamID64()
        local id = self:getID()
        local isCurrentChar = self and self:getID() == id

        -- Return the player to the character menu.
        if self and self.steamID == steamID then
            netstream.Start(client, "charKick", id, isCurrentChar)

            if isCurrentChar then
                client:setNetVar("char", nil)
                client:Spawn()
            end
        end
    end

    function CHAR:Kick()
        -- Kill the player so they are not standing anywhere.
        local client = self:getPlayer()
        client:KillSilent()
        local steamID = client:SteamID64()
        local id = self:getID()
        local isCurrentChar = self and self:getID() == id

        -- Return the player to the character menu.
        if self and self.steamID == steamID then
            netstream.Start(client, "charKick", id, isCurrentChar)

            if isCurrentChar then
                client:setNetVar("char", nil)
                client:Spawn()
            end
        end
    end

    -- @type method Character:ban(time)
    -- @typeCommentStart
    -- Prevents the use of this character permanently or for a certain amount of time.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    -- @int time Сharacter ban time
    -- @usageStart
    -- Entity(1):getChar():ban(3600) -- will send a character owned by a player with index 1 to a ban
    -- @usageEnd
    function CHAR:ban(time)
        time = tonumber(time)

        if time then
            -- If time is provided, adjust it so it becomes the un-ban time.
            time = os.time() + math.max(math.ceil(time), 60)
        end

        -- Mark the character as banned and kick the character back to menu.
        self:setData("banned", time or true)
        self:save()
        self:kick()
        hook.Run("OnCharPermakilled", self, time or nil)
    end

    function CHAR:Ban(time)
        time = tonumber(time)

        if time then
            -- If time is provided, adjust it so it becomes the un-ban time.
            time = os.time() + math.max(math.ceil(time), 60)
        end

        -- Mark the character as banned and kick the character back to menu.
        self:setData("banned", time or true)
        self:save()
        self:kick()
        hook.Run("OnCharPermakilled", self, time or nil)
    end

    -- @type method Character:delete()
    -- @typeCommentStart
    -- Deletes this character from existence along with its associated data.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    function CHAR:delete()
        lia.char.delete(self:getID(), self:getPlayer())
    end

    function CHAR:Delete()
        lia.char.delete(self:getID(), self:getPlayer())
    end

    -- @type method Character:destroy()
    -- @typeCommentStart
    -- Deletes this character from memory.
    -- @typeCommentEnd
    -- @classmod Character
    -- @realm server
    -- @internal
    function CHAR:destroy()
        local id = self:getID()
        lia.char.loaded[id] = nil
        netstream.Start(nil, "charDel", id)
    end
end

-- @type method Character:getPlayer()
-- @typeCommentStart
-- Returns which player owns this character.
-- @typeCommentEnd
-- @classmod Character
-- @realm shared
-- @treturn player The player who owns need character
-- @usageStart
-- local charOwner = Entity(1):getChar():getPlayer()
-- charOwner:notify('test')
-- @usageEnd
function CHAR:getPlayer()
    -- Return the player from cache.
    if IsValid(self.player) then
        return self.player
    elseif self.steamID then
        -- Search for which player owns this character.
        local steamID = self.steamID

        for k, v in ipairs(player.GetAll()) do
            if v:SteamID64() == steamID then
                self.player = v

                return v
            end
        end
    else
        for k, v in ipairs(player.GetAll()) do
            local char = v:getChar()

            if char and (char:getID() == self:getID()) then
                self.player = v

                return v
            end
        end
    end
end

function CHAR:GetPlayer()
    -- Return the player from cache.
    if IsValid(self.player) then
        return self.player
    elseif self.steamID then
        -- Search for which player owns this character.
        local steamID = self.steamID

        for k, v in ipairs(player.GetAll()) do
            if v:SteamID64() == steamID then
                self.player = v

                return v
            end
        end
    else
        for k, v in ipairs(player.GetAll()) do
            local char = v:getChar()

            if char and (char:getID() == self:getID()) then
                self.player = v

                return v
            end
        end
    end
end

-- @type function lia.char.registerVar()
-- @typeCommentStart
-- Sets up a new character variable.
-- @typeCommentEnd
-- @realm shared
function lia.char.registerVar(key, data)
    -- Store information for the variable.
    lia.char.vars[key] = data
    data.index = data.index or table.Count(lia.char.vars)
    -- Convert the name of the variable to be capitalized.
    local upperName = key:sub(1, 1):upper() .. key:sub(2)

    -- Provide functions to change the variable if allowed.
    if SERVER and not data.isNotModifiable then
        -- Overwrite the set function if desired.
        if data.onSet then
            CHAR["set" .. upperName] = data.onSet
            -- Have the set function only set on the server if no networking.
        elseif data.noNetworking then
            CHAR["set" .. upperName] = function(self, value)
                self.vars[key] = value
            end
        elseif data.isLocal then
            -- If the variable is a local one, only send the variable to the local player.
            CHAR["set" .. upperName] = function(self, value)
                local curChar = self:getPlayer() and self:getPlayer():getChar()
                local sendID = true

                if curChar and curChar == self then
                    sendID = false
                end

                local oldVar = self.vars[key]
                self.vars[key] = value
                netstream.Start(self.player, "charSet", key, value, sendID and self:getID() or nil)
                hook.Run("OnCharVarChanged", self, key, oldVar, value)
            end
        else -- Otherwise network the variable to everyone.
            CHAR["set" .. upperName] = function(self, value)
                local oldVar = self.vars[key]
                self.vars[key] = value
                netstream.Start(nil, "charSet", key, value, self:getID())
                hook.Run("OnCharVarChanged", self, key, oldVar, value)
            end
        end
    end

    -- The get functions are shared.
    -- Overwrite the get function if desired.
    if data.onGet then
        CHAR["get" .. upperName] = data.onGet
        -- Otherwise return the character variable or default if it does not exist.
    else
        CHAR["get" .. upperName] = function(self, default)
            local value = self.vars[key]
            if value ~= nil then return value end
            if default == nil then return lia.char.vars[key] and lia.char.vars[key].default or nil end

            return default
        end
    end

    -- Add the variable default to the character object.
    CHAR.vars[key] = data.default
end


-- Allows access to the character metatable using lia.meta.character
lia.meta.character = CHAR