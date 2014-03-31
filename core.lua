-- PetHealth-Broker
-------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local UPDATEPERIOD, elapsed = 2, 0
local dataobj = ldb:NewDataObject("Pet Health", { type = "data source", text = "Pet Health Info"})
local f = CreateFrame("frame")

f:SetScript("OnUpdate", function(self, elap)
  elapsed = elapsed + elap
  if elapsed < UPDATEPERIOD then return end

  elapsed = 0
  local total, owned = C_PetJournal.GetNumPets()
  local current = {}
  local max = {}
  local icons = {}
  local color = {}
  local slot = 1
  for i = 1, total do
    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    if canBattle and owned then
      local slotted = C_PetJournal.PetIsSlotted(petID)
      if slotted then
        local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
        current[slot] = health
        max[slot] = maxHealth
        icons[slot] = icon
        color[slot] = dataobj:GetHealthColor(health, maxHealth)

        slot = slot + 1
        if slot > 3 then
          break
        end
      end
    end
  end
  dataobj.text = string.format("|T%s:16|t |cFF%s%d|r/%d |T%s:16|t |cFF%s%d|r/%d |T%s:16|t |cFF%s%d|r/%d", icons[1], color[1], current[1], max[1], icons[2], color[2], current[2], max[2], icons[3], color[3], current[3], max[3])
end)

function dataobj:OnTooltipShow()
  self:AddLine("Pet Health")

  -- Iterate all pets
  local total, owned = C_PetJournal.GetNumPets()
  local slot = 1
  for i = 1, total do
    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    if canBattle and owned then
      local slotted = C_PetJournal.PetIsSlotted(petID)
      if slotted then
        local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

        local name
        if customName then
          name = customName
        else
          name = speciesName
        end

        -- rarity
        local r, g, b, hex = GetItemQualityColor(rarity - 1)

        -- status
        local healthColor = dataobj:GetHealthColor(health, maxHealth)

        self:AddDoubleLine(string.format("Level %d %s", level, name), string.format("|cFF%s%d|r/%d (%.1f%%)", healthColor, health, maxHealth, (100.0 * health / maxHealth)), r, g, b)
        slot = slot + 1
        if slot > 3 then
          break
        end
      end
    end
  end
 
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

function dataobj:GetHealthColor(current, max)
  local pct = (100.0 * current) / max -- just so we get a float
  if pct == 100.0 then
    return "00FF00"
  elseif pct > 75.0 then
    return "00DD00"
  elseif pct > 50.0 then
    return "88DD00"
  elseif pct > 25.0 then
    return "DD8800"
  elseif pct > 0.0 then
    return "DD0000"
  else
    return "FF0000"
  end
end
