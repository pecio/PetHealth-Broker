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
  local total, owned = C_PetJournal.GetNumPets()
  local current = {}
  local max = {}
  local icons = {}
  local slot = 1
  for i = 1, total do
    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    if owned then
      local slotted = C_PetJournal.PetIsSlotted(petID)
      if slotted then
        local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
        current[slot] = health
        max[slot] = maxHealth
        icons[slot] = icon

        slot = slot + 1
        if slot > 3 then
          break
        end
      end
    end
  end
  dataobj.text = string.format("|T%s:16|t %d/%d |T%s:16|t %d/%d |T%s:16|t %d/%d", icons[1], current[1], max[1], icons[2], current[2], max[2], icons[3], current[3], max[3])
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
