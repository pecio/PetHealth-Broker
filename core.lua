-- PetHealth-Broker
-------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigReg = LibStub("AceConfigRegistry-3.0")
local AceConsole = LibStub("AceConsole-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("PetHealthBroker")

local UPDATEPERIOD, elapsed = 0.5, 0
local dataobj = ldb:NewDataObject(L["Pet Health"], { type = "data source", text = "Pet Health Info"})
local f = CreateFrame("frame")

PetHealthBroker = LibStub("AceAddon-3.0"):NewAddon("PetHealth-Broker")

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
            rarity = {
              type = 'toggle',
              name = L['Show Rarity'],
              desc = L['Colorize max health or percent sign based on pet rarity'],
              set = function(info, val) PetHealthBroker.config.profile.rarity = val end,
              get = function(info) return PetHealthBroker.config.profile.rarity end
            }
          }
        },
        rbp = {
          type = 'group',
          -- The following name will be overwriten with the spell name
          -- in the current locale
          name = 'Revive Battle Pets',
          inline = true,
          args = {
            cooldown = {
              type = 'toggle',
              name = L['Show Cooldown'],
              desc = L['Show cooldown time for Revive Battle Pets spell in bar'],
              set = function(info, val) PetHealthBroker.config.profile.cooldown = val end,
              get = function(info) return PetHealthBroker.config.profile.cooldown end
            },
            notify = {
              type = 'select',
              name = L['Notify Availability'],
              desc = L['Notify the player when cooldown time finishes'],
              -- Weird option names, as AceConfig will sort by them
              values = {
                n1 = L['None'],
                n2 = L['With Level Up sound'],
                n3 = L['In chat'],
                n4 = L['Both']
              },
              set = function(info, val) PetHealthBroker.config.profile.notify = val end,
              get = function(info) return PetHealthBroker.config.profile.notify end
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

  -- Get and store Revive Battle Pets icon and name
  local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(125439)
  PetHealthBroker.RBPicon = icon
  PetHealthBroker.RBPname = name

  options.args.main.args.rbp.name = name
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.config)

  AceConfigReg:RegisterOptionsTable(PetHealthBroker.name, options)
  PetHealthBroker.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PetHealth-Broker", L["Pet Health"], "Broker")

  -- Register event handler
  f:SetScript("OnEvent", PetHealthBroker.eventHandler)
  f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  f:RegisterEvent("PET_BATTLE_OVER")
end

function PetHealthBroker:OnInitialize()
  self.config = LibStub("AceDB-3.0"):New("PetHealthBrokerConfig")
  -- Default for notify
  if not self.config.profile.notify then
    self.config.profile.notify = 'n1' -- None
  end
end

f:SetScript("OnUpdate", function(self, elap)
  elapsed = elapsed + elap
  if elapsed < UPDATEPERIOD then return end

  elapsed = 0

  PetHealthBroker:UpdateStatus()
end)

function PetHealthBroker:UpdateStatus()
  local result = ""
  for slot = 1,3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    if not petID then break end

    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

    local color = dataobj:GetHealthColor(health, maxHealth)

    local qcolor = 'FFFFFFFF'
    if PetHealthBroker.config.profile.rarity then
      local r, g, b, hex = GetItemQualityColor(rarity - 1)
      qcolor = hex
    end

    if PetHealthBroker.config.profile.pct then
      result = result .. string.format("|T%s:16|t |cFF%s%.1f|r|c%s%%|r ", icon, color, (health * 100.0) / maxHealth, qcolor)
    else
      result = result .. string.format("|T%s:16|t |cFF%s%d|r/|c%s%d|r ", icon, color, health, qcolor, maxHealth)
    end

    if locked then
      break
    end
  end

  if PetHealthBroker.config.profile.cooldown then
    result = result .. string.format("|T%s:16|t ", PetHealthBroker.RBPicon)
    local start, duration, enabled = GetSpellCooldown(125439)
    local cooldown = start + duration - GetTime()
    if cooldown > 0 then
      PetHealthBroker.inCooldown = true
      local min = math.floor(cooldown / 60)
      local seg = cooldown % 60
      result = result .. string.format("|cFFFFFFFF%d:%02d|r", min, seg)
    else
      if PetHealthBroker.inCooldown then
        if PetHealthBroker.config.profile.notify == 'n2' or PetHealthBroker.config.profile.notify == 'n4' then -- sound or both
          PlaySound("LEVELUP")
        end
        if PetHealthBroker.config.profile.notify == 'n3' or PetHealthBroker.config.profile.notify == 'n4' then -- chat or both
          AceConsole:Printf(L["%s is ready"], string.format("|T%s:16|t %s", PetHealthBroker.RBPicon, PetHealthBroker.RBPname))
        end
      end
      PetHealthBroker.inCooldown = false
      result = result .. string.format("|cFF00FF00%s|r", "Ready")
    end
  end

  dataobj.text = result
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

  -- Bottom instructions
  self:AddLine(" ")
  self:AddLine(L["Left Click to open Pet Journal"])
  self:AddLine(L["Right Click to open Options"])
  self:AddLine(L["Control-Left Click to rearrange pets by health"])
end

function dataobj:OnClick(button)
  if (button == "LeftButton") then
    if IsControlKeyDown() then
      PetHealthBroker:Rearrange()
    else
      TogglePetJournal(2)
    end
  elseif (button == "RightButton") then
    InterfaceOptionsFrame_OpenToCategory(PetHealthBroker.menu)
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
  local r = math.min(255, (510 * (max - current)) / max)
  local g = math.min(255, (510 * current) / max)
  return string.format("%02X%02X00", r, g)
end

function PetHealthBroker:Rearrange()
  local data = {}
  for slot = 1,3 do
    local petID, ability1, ability2, ability3, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)

    data[slot] = { petID = petID, health = health }
  end

  table.sort(data, function(item1, item2) return item1.health > item2.health end)

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
