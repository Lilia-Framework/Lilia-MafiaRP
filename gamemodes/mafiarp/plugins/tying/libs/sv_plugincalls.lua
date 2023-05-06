local PLUGIN = PLUGIN

function PLUGIN:PlayerLoadout(client)
    client:setNetVar("restricted")
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function PLUGIN:CanPlayerEnterVehicle(ply)
    if ply:IsHandcuffed() and not ply:IsVehicleAllowed() then
        return false
    elseif ply:IsHandcuffed() and ply:IsVehicleAllowed() then
        return true
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
hook.Add("PlayerCanHearPlayersVoiceHookTying", "PlayerCanHearPlayersVoiceHookTying", function(listener, speaker)
    if not speaker:getChar() then return false end
    if not listener:getChar() then return false end
    if speaker:IsHandcuffed() and speaker:IsGagged() then return false end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function PLUGIN:OnPlayerUnRestricted(client)
    local searcher = client:getNetVar("searcher")

    if IsValid(searcher) then
        self:stopSearching(searcher)
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function PLUGIN:PlayerUse(client, entity)
    if not client:getNetVar("restricted") and entity:IsPlayer() and entity:getNetVar("restricted") and not entity.liaBeingUnTied then
        entity.liaBeingUnTied = true
        entity:setAction("@beingUntied", 5)
        client:setAction("@unTying", 5)

        client:doStaredAction(entity, function()
            entity:setRestrictedTying(false)
            entity.liaBeingUnTied = false
            client:EmitSound("npc/roller/blade_in.wav")
            entity:FreeTies()
        end, 5, function()
            if IsValid(entity) then
                entity.liaBeingUnTied = false
                entity:setAction()
            end

            if IsValid(client) then
                client:setAction()
            end
        end)
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function PLUGIN:PlayerSpawn(ply)
    if not ply:getChar() then return end
    ply:FreeTies()
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local PLUGIN = PLUGIN

local function liaApproveSearch(len, ply)
    local requester = ply.SearchRequested
    if not requester then return end
    if not requester.SearchRequested then return end
    local approveSearch = net.ReadBool()

    if not approveSearch then
        requester:notify("Player denied your request to view their inventory.")
        requester.SearchRequested = nil
        ply.SearchRequested = nil

        return
    end

    if requester:GetPos():DistToSqr(ply:GetPos()) > 250 * 250 then return end
    PLUGIN:searchPlayer(requester, ply, true)
    requester.SearchRequested = nil
    ply.SearchRequested = nil
end

net.Receive("liaApproveSearch", liaApproveSearch)