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
  --local c1 = C_PetBattles.GetHealth(1, 1)
  --local c2 = C_PetBattles.GetHealth(1, 2)
  --local c3 = C_PetBattles.GetHealth(1, 3)
  --local m1 = C_PetBattles.GetMaxHealth(1, 1)
  --local m2 = C_PetBattles.GetMaxHealth(1, 2)
  --local m3 = C_PetBattles.GetMaxHealth(1, 3)
  --local i1 = C_PetBattles.GetIcon(1, 1)
  --local i2 = C_PetBattles.GetIcon(1, 2)
  --local i3 = C_PetBattles.GetIcon(1, 3)
  total, owned = C_PetJournal.GetNumPets
  current = {}
  max = {}
  icon = {}
  slot = 1
  for i = 1, total do
    petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    if owned then
      slotted = C_PetJournal.PetIsSlotted(petID)
      if slotted then
        health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats("petID")
        current[slot] = health
        max[slot] = maxHealth

        speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        icon[slot] = speciesIcon

        slot = slot + 1
        if slot > 3 then
          break
        end
      end
    end
  end
  dataobj.text = string.format("|T%s:16|t %d/%d", icon[1], current[1], max[1])
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
