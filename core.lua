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
  local slot = 1
  local result = ""
  for i = 1, total do
    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    if canBattle and owned then
      local slotted = C_PetJournal.PetIsSlotted(petID)
      if slotted then
        local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

        local color = dataobj:GetHealthColor(health, maxHealth)

        result = result .. string.format("|T%s:16|t |cFF%s%d|r/%d ", icon, color, health, maxHealth)

        slot = slot + 1
        if slot > 3 then
          break
        end
      end
    end
  end

  if slot <= 3 then
    for i = slot, 3 do
      result = result .. "|cFF888888Empty?|r "
    end
  end
  dataobj.text = result
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

        self:AddDoubleLine(string.format("Level %d %s", level, name), string.format("|cFF%s%d|r/%d (%.1f%%)", healthColor, health, maxHealth, (100.0 * health / maxHealth)), r, g, b, 1, 1, 1)

        local class = _G["BATTLE_PET_NAME_"..petType]
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
        self:AddDoubleLine(string.format("%s", class), string.format("%d/%d XP", xp, maxXp), 1, 1, 1, 1, 1, 1)

        slot = slot + 1
        if slot > 3 then
          break
        end

        -- Separator
        self:AddLine(" ")
      end
    end
  end

  if slot <= 3 then
    for i = slot, 3 do
      self:AddLine("Empty or filtered slot")
      self:AddLine("We can only show pets visible in Pet Journal")
      if i < 3 then
        self:AddLine(" ")
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
