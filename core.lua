-- PetHealth-Broker
-------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigReg = LibStub("AceConfigRegistry-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("PetHealthBroker")

local UPDATEPERIOD, elapsed = 0.5, 0
local dataobj = ldb:NewDataObject(L["Pet Health"], { type = "data source", text = "Pet Health Info"})
local f = CreateFrame("frame")

PetHealthBroker = LibStub("AceAddon-3.0"):NewAddon("PetHealth-Broker", 'AceConsole-3.0')

local rearrangeOptions = {
  c1 = L['Nothing'],
  c2 = L['Healthiest first (absolute)'],
  c3 = L['Healthiest first (relative)'],
  c4 = L['Lowest level first'],
  c5 = L['Highest level first']
}

local options = {
  name = "PetHealth-Broker",
  handler = PetHealthBroker,
  type = 'group',
  args = {
    main = {
      type = "group",
      name = "Main",
      args = {
        health = {
          type = 'group',
          name = 'Health',
          inline = true,
          args = {
            pct = {
              type = 'toggle',
              name = L['Show Percentages'],
              desc = L['Show Percentages instead of current/max health'],
              set = function(info, val) PetHealthBroker.config.profile.pct = val end,
              get = function(info) return PetHealthBroker.config.profile.pct end
            },
            quality = {
              type = 'toggle',
              name = L['Show Quality'],
              desc = L['Colorize max health or percent sign based on pet quality'],
              set = function(info, val) PetHealthBroker.config.profile.quality = val end,
              get = function(info) return PetHealthBroker.config.profile.quality end
            }
          }
        },
        multiclick = {
          type = 'group',
          name = L['One Click Rearrange'],
          inline = true,
          args = {
            control = {
              type = 'select',
              name = L['Control Left Click'],
              desc = L['Action to perform when Control Left Clicking in the text'],
              values = rearrangeOptions,
              set = function(info, val) PetHealthBroker.config.profile.controlClick = val end,
              get = function(info) return PetHealthBroker.config.profile.controlClick end
            },
            alt = {
              type = 'select',
              name = L['Alt Left Click'],
              desc = L['Action to perform when Alt Left Clicking in the text'],
              values = rearrangeOptions,
              set = function(info, val) PetHealthBroker.config.profile.altClick = val end,
              get = function(info) return PetHealthBroker.config.profile.altClick end
            }
          }
        }
      }
    }
  }
}

local defaultOptions = {
  profile = {
    quality = false,
    pct = false,
    controlClick = 'c2',
    altClick = 'c4'
  }
}

function PetHealthBroker:OnEnable()
  local brokerOptions = AceConfigReg:GetOptionsTable("Broker", "dialog", "LibDataBroker-1.1")
  if not brokerOptions then
    brokerOptions = {
      type = "group",
      name = "Broker",
      args = {}
    }
    AceConfigReg:RegisterOptionsTable("Broker", brokerOptions)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Broker", "Broker")
  end

  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.config)

  AceConfigReg:RegisterOptionsTable(PetHealthBroker.name, options)
  PetHealthBroker.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PetHealth-Broker", L["Pet Health"], "Broker")

  dataobj.icon = "Interface\\Icons\\Petjournalportrait"

  -- Register event handler
  f:SetScript("OnEvent", PetHealthBroker.eventHandler)
  f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  f:RegisterEvent("PET_BATTLE_OVER")
end

function PetHealthBroker:OnInitialize()
  self.config = LibStub("AceDB-3.0"):New("PetHealthBrokerConfig", defaultOptions, true)
end

f:SetScript("OnUpdate", function(self, elap)
  elapsed = elapsed + elap
  if elapsed < UPDATEPERIOD then return end

  elapsed = 0

  PetHealthBroker:UpdateStatus()
end)

function PetHealthBroker:UpdateStatus()
  local result = {}
  for slot = 1,3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    if not petID then break end

    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

    local health, maxHealth, power, speed, quality = C_PetJournal.GetPetStats(petID)

    local color = dataobj:GetHealthColor(health, maxHealth)

    local qcolor = 'FFFFFFFF'
    if PetHealthBroker.config.profile.quality then
      local r, g, b, hex = GetItemQualityColor(quality - 1)
      qcolor = hex
    end

    if PetHealthBroker.config.profile.pct then
      table.insert(result,
        string.format("|T%s:16|t|cFF%s%.1f|r|c%s%%|r",
          icon, color, (health * 100.0) / maxHealth, qcolor))
    else
      table.insert(result,
        string.format("|T%s:16|t|cFF%s%d|r/|c%s%d|r",
          icon, color, health, qcolor, maxHealth))
    end

    if locked then
      break
    end
  end

  dataobj.text = table.concat(result, " ")
end

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
    local health, maxHealth, power, speed, quality = C_PetJournal.GetPetStats(petID)
    -- quality
    local r, g, b, hex = GetItemQualityColor(quality - 1)

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

  -- Bottom instructions
  self:AddLine(" ")
  self:AddLine(L["Left Click to open Pet Journal"])
  self:AddLine(L["Right Click to open Options"])
  if (not (PetHealthBroker.config.profile.controlClick == 'c1')) then
    self:AddLine(string.format(L["Control-Left Click to Rearrange %s"], rearrangeOptions[PetHealthBroker.config.profile.controlClick]))
  end
  if (not (PetHealthBroker.config.profile.altClick == 'c1')) then
    self:AddLine(string.format(L["Alt-Left Click to Rearrange %s"], rearrangeOptions[PetHealthBroker.config.profile.altClick]))
  end
end

function dataobj:OnClick(button)
  if (button == "LeftButton") then
    if IsControlKeyDown() then
      PetHealthBroker:Rearrange(PetHealthBroker.config.profile.controlClick)
    elseif IsAltKeyDown() then
      PetHealthBroker:Rearrange(PetHealthBroker.config.profile.altClick)
    else
      ToggleCollectionsJournal(2)
    end
  elseif (button == "RightButton") then
    InterfaceOptionsFrame_OpenToCategory(PetHealthBroker.menu)
  end
end

function dataobj:OnEnter()
  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
  GameTooltip:ClearLines()
  dataobj.OnTooltipShow(GameTooltip)
  GameTooltip:Show()
end

function dataobj:OnLeave()
  GameTooltip:Hide()
end

function dataobj:GetHealthColor(current, max)
  local r = math.min(255, (510 * (max - current)) / max)
  local g = math.min(255, (510 * current) / max)
  return string.format("%02X%02X00", r, g)
end

function PetHealthBroker:Rearrange(mode)
  -- Do nothing if configured so or if player is in combat
  -- (changing active pets is a protected action)
  if mode == 'c1' or InCombatLockdown() then return end

  local data = {}
  for slot = 1,3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    local health, maxHealth, power, speed, quality = C_PetJournal.GetPetStats(petID)
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

    data[slot] = { petID = petID, health = health, max = maxHealth, level = level }
  end

  local sortFunction
  if mode == 'c2' then -- healthiest (absolute) first
    sortFunction = function(pet1, pet2)
      return pet1.health > pet2.health
    end
  elseif mode == 'c3' then -- healthiest (relative) first
    sortFunction = function(pet1, pet2)
      return pet1.health / pet1.max > pet2.health / pet2.max
    end
  elseif mode == 'c4' then -- Lowest level first
    sortFunction = function(pet1, pet2)
      return pet1.level < pet2.level
    end
  elseif mode == 'c5' then -- Highest level first
    sortFunction = function(pet1, pet2)
      return pet1.level > pet2.level
    end
  else
    PetHealthBroker:Printf("unknown click mode: %s!", mode or 'nil')
    return
  end

  table.sort(data, sortFunction)

  -- We should only need to set the two first slots
  for i=1,2 do
    C_PetJournal.SetPetLoadOutInfo(i, data[i].petID)
  end
end

PetHealthBroker.eventHandler = function(self, event, ...)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit, name, rank, line, spellID = ...
    if (spellID == 125439 or spellID == 133994) and unit == 'player' then
      PetHealthBroker:UpdateStatus()
    end
  elseif event == "PET_BATTLE_OVER" then
    PetHealthBroker:UpdateStatus()
  end
end
