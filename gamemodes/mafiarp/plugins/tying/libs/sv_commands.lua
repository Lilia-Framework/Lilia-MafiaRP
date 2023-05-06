local PLUGIN = PLUGIN

------------------------------------------------------------------------------------------------------------------------
lia.command.add("allowcarentry", {
    onRun = function(client, arguments)
        local data = {}
        data.start = client:GetShootPos()
        data.endpos = data.start + client:GetAimVector() * 96
        data.filter = client
        local target = util.TraceLine(data).Entity

        if not target:IsPlayer() then
            client:notify("Invalid Target!")

            return
        end

        if not target:IsHandcuffed() then
            client:notify("The character needs to be handcuffed!")

            return
        end

        local MAXDISTANCE_TARGET = 100 * 100 -- SQUARED FOR PERFORMANCE The distance the dragged player will try to achieve
        local TargetPos = target:GetPos()
        local myPos = client:GetPos()
        local dist2Sqr = (TargetPos.x - myPos.x) ^ 2 + (TargetPos.y - myPos.y) ^ 2

        if dist2Sqr < MAXDISTANCE_TARGET then
            if target:IsVehicleAllowed() then
                target:SetVehicleAllowed()
                client:notify("Disallowed Player in Cars!")
            else
                target:SetVehicleAllowed()
                client:notify("Allowed Player in Cars!")
            end
        else
            client:notify("You can't use this from distance!")

            return
        end
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("gagplayer", {
    onRun = function(client, arguments)
        local data = {}
        data.start = client:GetShootPos()
        data.endpos = data.start + client:GetAimVector() * 96
        data.filter = client
        local target = util.TraceLine(data).Entity

        if not target:IsPlayer() then
            client:notify("Invalid Target!")

            return
        end

        if not target:IsHandcuffed() then
            client:notify("The character needs to be handcuffed!")

            return
        end

        local MAXDISTANCE_TARGET = 100 * 100 -- SQUARED FOR PERFORMANCE The distance the dragged player will try to achieve
        local TargetPos = target:GetPos()
        local myPos = client:GetPos()
        local dist2Sqr = (TargetPos.x - myPos.x) ^ 2 + (TargetPos.y - myPos.y) ^ 2

        if dist2Sqr < MAXDISTANCE_TARGET then
            if target:IsGagged() then
                target:SetGagged()
                client:notify("Ungagged Player!")
            else
                target:SetGagged()
                client:notify("Gagged Player!")
            end
        else
            client:notify("You can't use this from distance!")

            return
        end
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("blindplayer", {
    onRun = function(client, arguments)
        local data = {}
        data.start = client:GetShootPos()
        data.endpos = data.start + client:GetAimVector() * 96
        data.filter = client
        local target = util.TraceLine(data).Entity

        if not target:IsPlayer() then
            client:notify("Invalid Target!")

            return
        end

        if not target:IsHandcuffed() then
            client:notify("The character needs to be handcuffed!")

            return
        end

        local MAXDISTANCE_TARGET = 100 * 100 -- SQUARED FOR PERFORMANCE The distance the dragged player will try to achieve
        local TargetPos = target:GetPos()
        local myPos = client:GetPos()
        local dist2Sqr = (TargetPos.x - myPos.x) ^ 2 + (TargetPos.y - myPos.y) ^ 2

        if dist2Sqr < MAXDISTANCE_TARGET then
            if target:IsBlinded() then
                target:SetBlinded()
                client:notify("Unblinded Player!")
            else
                target:SetBlinded()
                client:notify("Blinded Player!")
            end
        else
            client:notify("You can't use this from distance!")

            return
        end
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("dragplayer", {
    onRun = function(client, arguments)
        local tr = util.TraceLine(util.GetPlayerTrace(client))
        local target = tr.Entity
        if client:InVehicle() or IsBeingDragged(client) then return end

        if IsValid(target) and target:IsPlayer() and target:GetPos():DistToSqr(client:GetPos()) <= DRAGGING_START_RANGE * DRAGGING_START_RANGE and target:getNetVar("restricted") and not target:InVehicle() then
            if target:IsDragged() then
                client:notify("Stopped Dragging Player!")
                SetDrag(nil, client)
                SetDrag(target, nil)
                target:setNetVar("dragged", false)
            elseif not target:IsDragged() then
                SetDrag(target, client)
                client:notify("Started Dragging Player!")
                target:setNetVar("dragged", true)
            end
        else
            client:notify("Not a Valid Target!")
        end
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("setrestricted", {
    onRun = function(client, arguments)
        local target = lia.command.findPlayer(client, arguments[1])
        local uniqueID = client:GetUserGroup()

        if not UserGroups.modRanks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        target:SetRestricted(target)
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("setblinded", {
    onRun = function(client, arguments)
        local target = lia.command.findPlayer(client, arguments[1])
        local uniqueID = client:GetUserGroup()

        if not UserGroups.modRanks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        if not target:IsHandcuffed() then
            client:notify("Character isn't Handcuffed!")

            return
        end

        target:SetBlinded(target)
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("setallowcar", {
    onRun = function(client, arguments)
        local target = lia.command.findPlayer(client, arguments[1])
        local uniqueID = client:GetUserGroup()

        if not UserGroups.modRanks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        if not target:IsHandcuffed() then
            client:notify("Character isn't Handcuffed!")

            return
        end

        target:SetVehicleAllowed()
    end
})

------------------------------------------------------------------------------------------------------------------------
lia.command.add("setgagged", {
    onRun = function(client, arguments)
        local target = lia.command.findPlayer(client, arguments[1])
        local uniqueID = client:GetUserGroup()

        if not UserGroups.modRanks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        if not target:IsHandcuffed() then
            client:notify("Character isn't Handcuffed!")

            return
        end

        target:SetGagged(target)
    end
})

----------------------------------------------------------------------------------------------
lia.command.add("charsearch", {
    onRun = function(client, arguments)
        local data = {}
        data.start = client:GetShootPos()
        data.endpos = data.start + client:GetAimVector() * 96
        data.filter = client
        local target = util.TraceLine(data).Entity

        if not target:IsPlayer() then
            client:notify("Invalid Target!")

            return
        end

        if not target:IsHandcuffed() then
            client:notify("The character needs to be handcuffed!")

            return
        end

        if not client:getChar() or not client:getChar():getInv() then return false end
        if not IsValid(target) or not target:IsPlayer() then return false, "@invalidPly" end
        local MAXDISTANCE_TARGET = 100 * 100 -- SQUARED FOR PERFORMANCE The distance the dragged player will try to achieve
        local TargetPos = target:GetPos()
        local myPos = client:GetPos()
        local dist2Sqr = (TargetPos.x - myPos.x) ^ 2 + (TargetPos.y - myPos.y) ^ 2

        if target:IsHandcuffed() then
            if dist2Sqr < MAXDISTANCE_TARGET then
                if target:getNetVar("restricted") then
                    client:EmitSound("npc/combine_soldier/gear5.wav", 100, 100)
                    client:setAction("Reaching into pockets...", 2)
                    target:setAction("You feel something in your pockets...", 2)
                    client:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_PLACE)

                    timer.Simple(2, function()
                        PLUGIN:searchPlayer(client, target)
                        client:ConCommand("say /me reaches into tied persons pockets.")
                        client:EmitSound("npc/combine_soldier/gear4.wav", 100, 100)
                    end)
                else
                    return false, "@This player must be tied"
                end
            else
                client:notify("You can't use this from distance!")

                return
            end
        else
            client:ChatPrint("This character isn't handcuffed!")
        end
    end
})

----------------------------------------------------------------------------------------------
lia.command.add("admincharsearch", {
    syntax = "<string target>",
    onRun = function(client, arguments)
        local uniqueID = client:GetUserGroup()

        if not UserGroups.modRanks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        local target = lia.command.findPlayer(client, arguments[1])

        if IsValid(target) and target:IsPlayer() then
            PLUGIN:searchPlayer(client, target)
        end
    end
})