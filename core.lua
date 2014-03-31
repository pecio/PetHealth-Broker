-- PetHealth-Broker
-------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local UPDATEPERIOD, elapsed = 0.5, 0
local dataobj = ldb:NewDataObject("Pet Health", { type = "data source", text = "75.0 FPS"})
local f = CreateFrame("frame")

f:SetScript("OnUpdate", function(self, elap)
  elapsed = elapsed + elap
  if elapsed < UPDATEPERIOD then return end

  elapsed = 0
  local fps = GetFramerate()
  dataobj.text = string.format("%.1f FPS", fps)
end)

function dataobj:OnTooltipShow()
  self:AddLine("Pet Health")
end

function dataobj:OnEnter()
  GameTooltip:SetOwoner(self, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
  GameTooltip:ClearLines()
  dataobj.OnTooltipShow(GameTooltip)
  GameTooltip:Show()
end

function dataobj:OnLeave()
  GameTooltip:Hide()
end
