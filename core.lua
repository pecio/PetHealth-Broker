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

  local result = ""
  for slot = 1,3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

    local color = dataobj:GetHealthColor(health, maxHealth)

    result = result .. string.format("|T%s:16|t |cFF%s%d|r/%d ", icon, color, health, maxHealth)

    if locked then
      break
    end
  end

  dataobj.text = result
end)

function dataobj:OnTooltipShow()
  self:AddLine("Pet Health")

  for slot = 1, 3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    if locked then
      break
    end

    -- Separator
    if slot > 1 then
      self:AddLine(" ")
    end

    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
    -- rarity
    local r, g, b, hex = GetItemQualityColor(rarity - 1)

    -- status
    local healthColor = dataobj:GetHealthColor(health, maxHealth)

    local displayName
    if customName then
      displayName = customName
    else
      displayName = name -- Species name
    end

    self:AddDoubleLine(string.format("[%d] %s", level, displayName), string.format("|cFF%s%d|r/%d (%.1f%%)", healthColor, health, maxHealth, (100.0 * health / maxHealth)), r, g, b, 1, 1, 1)

    local class = _G["BATTLE_PET_NAME_"..petType]
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
    self:AddDoubleLine(string.format("%s", class), string.format("%d/%d XP", xp, maxXp), 1, 1, 1, 1, 1, 1)
  end
end

function dataobj:OnClick(button)
  if (button == "LeftButton") then
    if IsShiftKeyDown() then
      print("Clearing pet filters")
      C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, true)
      C_PetJournal.AddAllPetSourcesFilter()
      C_PetJournal.AddAllPetTypesFilter()
      C_PetJournal.SetSearchFilter("")
    else
      print("Opening pet journal")
      TogglePetJournal(2)
    end
  elseif (button == "RightButton") then
    print("pending")
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
