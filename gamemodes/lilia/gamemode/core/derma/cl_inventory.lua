LIA_ICON_SIZE = 64
-- The queue for the rendered icons.
renderedIcons = renderedIcons or {}

-- To make making inventory variant, This must be followed up.
function renderNewIcon(panel, itemTable)
    -- re-render icons
    if (itemTable.iconCam and not renderedIcons[string.lower(itemTable.model)]) or itemTable.forceRender then
        local iconCam = itemTable.iconCam

        iconCam = {
            cam_pos = iconCam.pos,
            cam_ang = iconCam.ang,
            cam_fov = iconCam.fov,
        }

        renderedIcons[string.lower(itemTable.model)] = true
        panel.Icon:RebuildSpawnIconEx(iconCam)
    end
end

local function drawIcon(mat, self, x, y)
    surface.SetDrawColor(color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, x, y)
end

local PANEL = {}

function PANEL:setItemType(itemTypeOrID)
    local item = lia.item.list[itemTypeOrID]

    if isnumber(itemTypeOrID) then
        item = lia.item.instances[itemTypeOrID]
        self.itemID = itemTypeOrID
    else
        self.itemType = itemTypeOrID
    end

    assert(item, "invalid item type or ID " .. tostring(item))
    self.liaToolTip = true
    self.itemTable = item
    self:SetModel(item:getModel(), item:getSkin())
    self:updateTooltip()

    if item.exRender then
        self.Icon:SetVisible(false)

        self.ExtraPaint = function(self, x, y)
            local paintFunc = item.paintIcon

            if paintFunc and type(paintFunc) == "function" then
                paintFunc(item, self)
            else
                local exIcon = ikon:getIcon(item.uniqueID)

                if exIcon then
                    surface.SetMaterial(exIcon)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(0, 0, x, y)
                else
                    ikon:renderIcon(item.uniqueID, item.width, item.height, item.model, item.iconCam)
                end
            end
        end
    elseif item.icon then
        self.Icon:SetVisible(false)

        self.ExtraPaint = function(self, w, h)
            drawIcon(item.icon, self, w, h)
        end
    else
        renderNewIcon(self, item)
    end
end

function PANEL:updateTooltip()
    self:SetTooltip("<font=liaItemBoldFont>" .. self.itemTable:getName() .. "</font>\n" .. "<font=liaItemDescFont>" .. self.itemTable:getDesc())
end

function PANEL:getItem()
    return self.itemTable
end

-- Updates the parts of the UI that could be changed by data changes.
function PANEL:ItemDataChanged(key, oldValue, newValue)
    self:updateTooltip()
end

function PANEL:Init()
    self:Droppable("inv")
    self:SetSize(LIA_ICON_SIZE, LIA_ICON_SIZE)
end

--[[ function PANEL:Think()
	self.itemTable = lia.item.instances[self.itemID]
	self:updateTooltip()
end ]]
function PANEL:PaintOver(w, h)
    local itemTable = lia.item.instances[self.itemID]

    if itemTable and itemTable.paintOver then
        local w, h = self:GetSize()
        itemTable.paintOver(self, itemTable, w, h)
    end

    hook.Run("ItemPaintOver", self, itemTable, w, h)
end

function PANEL:PaintBehind(w, h)
    surface.SetDrawColor(0, 0, 0, 85)
    surface.DrawRect(2, 2, w - 4, h - 4)
end

function PANEL:ExtraPaint(w, h)
end

function PANEL:Paint(w, h)
    self:PaintBehind(w, h)
    self:ExtraPaint(w, h)
end

local buildActionFunc = function(action, actionIndex, itemTable, invID, sub)
    return function()
        itemTable.player = LocalPlayer()
        local send = true

        if action.onClick then
            send = action.onClick(itemTable, sub and sub.data)
        end

        local snd = action.sound or SOUND_INVENTORY_INTERACT

        if snd then
            if istable(snd) then
                LocalPlayer():EmitSound(unpack(snd))
            elseif isstring(snd) then
                surface.PlaySound(snd)
            end
        end

        if send ~= false then
            netstream.Start("invAct", actionIndex, itemTable.id, invID, sub and sub.data)
        end

        itemTable.player = nil
    end
end

function PANEL:openActionMenu()
    local itemTable = self.itemTable
    assert(itemTable, "attempt to open action menu for invalid item")
    itemTable.player = LocalPlayer()
    local menu = DermaMenu()
    local override = hook.Run("OnCreateItemInteractionMenu", self, menu, itemTable)

    if override then
        if IsValid(menu) then
            menu:Remove()
        end

        return
    end

    for k, v in SortedPairs(itemTable.functions) do
        if hook.Run("onCanRunItemAction", itemTable, k) == false or isfunction(v.onCanRun) and not v.onCanRun(itemTable) then continue end

        -- TODO: refactor custom menu options as a method for items
        if v.isMulti then
            local subMenu, subMenuOption = menu:AddSubMenu(L(v.name or k), buildActionFunc(v, k, itemTable, self.invID))
            subMenuOption:SetImage(v.icon or "icon16/brick.png")
            if not v.multiOptions then return end
            local options = isfunction(v.multiOptions) and v.multiOptions(itemTable, LocalPlayer()) or v.multiOptions

            for _, sub in pairs(options) do
                subMenu:AddOption(L(sub.name or "subOption"), buildActionFunc(v, k, itemTable, self.invID, sub)):SetImage(sub.icon or "icon16/brick.png")
            end
        else
            menu:AddOption(L(v.name or k), buildActionFunc(v, k, itemTable, self.invID)):SetImage(v.icon or "icon16/brick.png")
        end
    end

    menu:Open()
    itemTable.player = nil
end

vgui.Register("liaItemIcon", PANEL, "SpawnIcon")
PANEL = {}

function PANEL:Init()
    self:MakePopup()
    self:Center()
    self:ShowCloseButton(false)
    self:SetDraggable(true)
    self:SetTitle(L"inv")
end

-- Sets which inventory this panel is representing.
function PANEL:setInventory(inventory)
    self.inventory = inventory
    self:liaListenForInventoryChanges(inventory)
end

-- Called when the data for the local inventory has been initialized.
-- This shouldn't run unless the inventory got resync'd.
function PANEL:InventoryInitialized()
end

-- Called when a data value has been changed for the inventory.
function PANEL:InventoryDataChanged(key, oldValue, newValue)
end

-- Called when the inventory for this panel has been deleted. This may
-- be because the local player no longer has access to the inventory!
function PANEL:InventoryDeleted(inventory)
    if self.inventory == inventory then
        self:Remove()
    end
end

-- Called when the given item has been added to the inventory.
function PANEL:InventoryItemAdded(item)
end

-- Called when the given item has been removed from the inventory.
function PANEL:InventoryItemRemoved(item)
end

-- Called when an item within this inventory has its data changed.
function PANEL:InventoryItemDataChanged(item, key, oldValue, newValue)
end

-- Make sure to clean up hooks before removing the panel.
function PANEL:OnRemove()
    self:liaDeleteInventoryHooks()
end

vgui.Register("liaInventory", PANEL, "DFrame")
local margin = 10

hook.Add("CreateMenuButtons", "liaInventory", function(tabs)
    if hook.Run("CanPlayerViewInventory") == false then return end

    tabs["inv"] = function(panel)
        local inventory = LocalPlayer():getChar():getInv()
        if not inventory then return end
        local mainPanel = inventory:show(panel)
        local sortPanels = {}

        local totalSize = {
            x = 0,
            y = 0,
            p = 0
        }

        table.insert(sortPanels, mainPanel)
        totalSize.x = totalSize.x + mainPanel:GetWide() + margin
        totalSize.y = math.max(totalSize.y, mainPanel:GetTall())

        for id, item in pairs(inventory:getItems()) do
            if item.isBag and hook.Run("CanOpenBagPanel", item) ~= false then
                local inventory = item:getInv()
                local childPanels = inventory:show(mainPanel)
                lia.gui["inv" .. inventory:getID()] = childPanels
                table.insert(sortPanels, childPanels)
                totalSize.x = totalSize.x + childPanels:GetWide() + margin
                totalSize.y = math.max(totalSize.y, childPanels:GetTall())
            end
        end

        local px, py, pw, ph = mainPanel:GetBounds()
        local x, y = px + pw / 2 - totalSize.x / 2, py + ph / 2

        for _, panel in pairs(sortPanels) do
            panel:ShowCloseButton(true)
            panel:SetPos(x, y - panel:GetTall() / 2)
            x = x + panel:GetWide() + margin
        end

        hook.Add("PostRenderVGUI", mainPanel, function()
            hook.Run("PostDrawInventory", mainPanel)
        end)
    end
end)