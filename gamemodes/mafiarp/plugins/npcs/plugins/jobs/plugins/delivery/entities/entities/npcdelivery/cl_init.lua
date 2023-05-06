include("shared.lua")
local TEXT_OFFSET = Vector(0, 0, 20)
local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = lia.util.drawText
local configGet = lia.config.get
ENT.DrawEntityInfo = true

function ENT:onDrawEntityInfo(alpha)
    local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)) + TEXT_OFFSET)
    local x, y = position.x, position.y
    --local desc = self.getNetVar(self, "desc")
    drawText("Pierce Bowman", x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)
    --if (desc) then
    drawText("Need some work?", x, y + 16, colorAlpha(color_white, alpha), 1, 1, "liaSmallFont", alpha * 0.65)
    --end
end