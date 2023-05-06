lia.config = lia.config or {}
lia.config.stored = lia.config.stored or {}

function lia.config.add(key, value, desc, callback, data, noNetworking, schemaOnly)
    assert(isstring(key), "expected config key to be string, got " .. type(key))
    local oldConfig = lia.config.stored[key]

    lia.config.stored[key] = {
        data = data,
        value = oldConfig and oldConfig.value or value,
        default = value,
        desc = desc,
        noNetworking = noNetworking,
        global = not schemaOnly,
        callback = callback
    }
end

function lia.config.setDefault(key, value)
    local config = lia.config.stored[key]

    if config then
        config.default = value
    end
end

function lia.config.forceSet(key, value, noSave)
    local config = lia.config.stored[key]

    if config then
        config.value = value
    end

    if noSave then
        lia.config.save()
    end
end

function lia.config.set(key, value)
    local config = lia.config.stored[key]

    if config then
        local oldValue = value
        config.value = value

        if SERVER then
            if not config.noNetworking then
                netstream.Start(nil, "cfgSet", key, value)
            end

            if config.callback then
                config.callback(oldValue, value)
            end

            lia.config.save()
        end
    end
end

function lia.config.get(key, default)
    local config = lia.config.stored[key]

    if config then
        if config.value ~= nil then
            -- if the value is a table with rgb values
            if istable(config.value) and config.value.r and config.value.g and config.value.b then
                config.value = Color(config.value.r, config.value.g, config.value.b) -- convert it to a Color table
            end

            return config.value
        elseif config.default ~= nil then
            return config.default
        end
    end

    return default
end

function lia.config.load()
    if SERVER then
        local globals = lia.data.get("config", nil, true, true)
        local data = lia.data.get("config", nil, false, true)

        if globals then
            for k, v in pairs(globals) do
                lia.config.stored[k] = lia.config.stored[k] or {}
                lia.config.stored[k].value = v
            end
        end

        if data then
            for k, v in pairs(data) do
                lia.config.stored[k] = lia.config.stored[k] or {}
                lia.config.stored[k].value = v
            end
        end
    end

    lia.util.include("lilia/gamemode/config/sh_config.lua")
    hook.Run("InitializedConfig")
end

if SERVER then
    function lia.config.getChangedValues()
        local data = {}

        for k, v in pairs(lia.config.stored) do
            if v.default ~= v.value then
                data[k] = v.value
            end
        end

        return data
    end

    function lia.config.send(client)
        netstream.Start(client, "cfgList", lia.config.getChangedValues())
    end

    function lia.config.save()
        local globals = {}
        local data = {}

        for k, v in pairs(lia.config.getChangedValues()) do
            if lia.config.stored[k].global then
                globals[k] = v
            else
                data[k] = v
            end
        end

        -- Global and schema data set respectively.
        lia.data.set("config", globals, true, true)
        lia.data.set("config", data, false, true)
    end

    netstream.Hook("cfgSet", function(client, key, value)
        if client:IsSuperAdmin() and type(lia.config.stored[key].default) == type(value) and hook.Run("CanPlayerModifyConfig", client, key) ~= false then
            lia.config.set(key, value)

            if type(value) == "table" then
                local value2 = "["
                local count = table.Count(value)
                local i = 1

                for _, v in SortedPairs(value) do
                    value2 = value2 .. v .. (i == count and "]" or ", ")
                    i = i + 1
                end

                value = value2
            end

            lia.util.notifyLocalized("cfgSet", nil, client:Name(), key, tostring(value))
        end
    end)
else
    netstream.Hook("cfgList", function(data)
        for k, v in pairs(data) do
            if lia.config.stored[k] then
                lia.config.stored[k].value = v
            end
        end

        hook.Run("InitializedConfig", data)
    end)

    netstream.Hook("cfgSet", function(key, value)
        local config = lia.config.stored[key]

        if config then
            if config.callback then
                config.callback(config.value, value)
            end

            config.value = value
            local properties = lia.gui.properties

            if IsValid(properties) then
                local row = properties:GetCategory(L(config.data and config.data.category or "misc")):GetRow(key)

                if IsValid(row) then
                    if istable(value) and value.r and value.g and value.b then
                        value = Vector(value.r / 255, value.g / 255, value.b / 255)
                    end

                    row:SetValue(value)
                end
            end
        end
    end)
end

if CLIENT then
    hook.Add("CreateMenuButtons", "liaConfig", function(tabs)
        if not LocalPlayer():IsSuperAdmin() or hook.Run("CanPlayerUseConfig", LocalPlayer()) == false then return end

        tabs["config"] = function(panel)
            local scroll = panel:Add("DScrollPanel")
            scroll:Dock(FILL)
            hook.Run("CreateConfigPanel", panel)
            local properties = scroll:Add("DProperties")
            properties:SetSize(panel:GetSize())
            lia.gui.properties = properties
            -- We're about to store the categories in this buffer.
            local buffer = {}

            for k, v in pairs(lia.config.stored) do
                -- Get the category name.
                local index = v.data and v.data.category or "misc"
                -- Insert the config into the category list.
                buffer[index] = buffer[index] or {}
                buffer[index][k] = v
            end

            -- Loop through the categories in alphabetical order.
            for category, configs in SortedPairs(buffer) do
                category = L(category)

                -- Ditto, except we're looping through configs.
                for k, v in SortedPairs(configs) do
                    -- Determine which type of panel to create.
                    local form = v.data and v.data.form
                    local value = lia.config.stored[k].default

                    -- Let's see if the parameter has a form to perform some additional operations.
                    if form then
                        if form == "Int" then
                            -- math.Round can create an error without failing silently as expected if the parameter is invalid.
                            -- So an alternate value is entered directly into the function and not outside of it.
                            value = math.Round(lia.config.get(k) or value)
                        elseif form == "Float" then
                            value = tonumber(lia.config.get(k)) or value
                        elseif form == "Boolean" then
                            value = tobool(lia.config.get(k)) or value
                        else
                            value = lia.config.get(k) or value
                        end
                    else
                        local formType = type(value)

                        if formType == "number" then
                            form = "Int"
                            value = tonumber(lia.config.get(k)) or value
                        elseif formType == "boolean" then
                            form = "Boolean"
                            value = tobool(lia.config.get(k))
                        else
                            form = "Generic"
                            value = lia.config.get(k) or value
                        end
                    end

                    -- VectorColor currently only exists for DProperties.
                    if form == "Generic" and type(value) == "table" and value.r and value.g and value.b then
                        -- Convert the color to a vector.
                        value = Vector(value.r / 255, value.g / 255, value.b / 255)
                        form = "VectorColor"
                    end

                    local delay = 1

                    if form == "Boolean" then
                        delay = 0
                    end

                    -- Add a new row for the config to the properties.
                    local row = properties:CreateRow(category, tostring(k))
                    row:Setup(form, v.data and v.data.data or {})
                    row:SetValue(value)
                    row:SetTooltip(v.desc)

                    row.DataChanged = function(this, newValue)
                        timer.Create("liaCfgSend" .. k, delay, 1, function()
                            if not IsValid(row) then return end

                            if form == "VectorColor" then
                                local vector = Vector(newValue)
                                newValue = Color(math.floor(vector.x * 255), math.floor(vector.y * 255), math.floor(vector.z * 255))
                            elseif form == "Int" or form == "Float" then
                                newValue = tonumber(newValue)

                                if form == "Int" then
                                    newValue = math.Round(newValue)
                                end
                            elseif form == "Boolean" then
                                newValue = tobool(newValue)
                            end

                            netstream.Start("cfgSet", k, newValue)
                        end)
                    end
                end
            end
        end
    end)
end
