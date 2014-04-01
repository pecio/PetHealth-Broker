-- PetHealth-Broker
-------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigReg = LibStub("AceConfigRegistry-3.0")

local UPDATEPERIOD, elapsed = 0.5, 0
local dataobj = ldb:NewDataObject("Pet Health", { type = "data source", text = "Pet Health Info"})
local f = CreateFrame("frame")

PetHealthBroker = LibStub("AceAddon-3.0"):NewAddon("PetHealth-Broker")

local options = {
  name = "PetHealth-Broker",
  handler = PetHealthBroker,
  type = 'group',
  args = {
    main = {
      type = "group",
      name = "Main",
      args = {
        pct = {
          type = 'toggle',
          name = 'Show Percentages',
          desc = 'Show Percentages instead of current/max health',
          set = function(info, val) PetHealthBroker.config.profile.pct = val end,
          get = function(info) return PetHealthBroker.config.profile.pct end
        },
        cooldown = {
          type = 'toggle',
          name = 'Show Revive Battle Pets cooldown',
          desc = 'Show cooldown time for Revive Battle Pets spell in bar',
          set = function(info, val) PetHealthBroker.config.profile.cooldown = val end,
          get = function(info) return PetHealthBroker.config.profile.cooldown end
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

  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.config)

  AceConfigReg:RegisterOptionsTable(PetHealthBroker.name, options)
  PetHealthBroker.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PetHealth-Broker", "Pet Health", "Broker")

  -- Get and store Revive Battle Pets icon
  local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(125439)
  PetHealthBroker.RBPicon = icon
end

function PetHealthBroker:OnInitialize()
  self.config = LibStub("AceDB-3.0"):New("PetHealthBrokerConfig")
end

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

    if PetHealthBroker.config.profile.pct then
      result = result .. string.format("|T%s:16|t |cFF%s%.1f|r|cFFFFFFFF%%|r ", icon, color, (health * 100.0) / maxHealth)
    else
      result = result .. string.format("|T%s:16|t |cFF%s%d|r/%d ", icon, color, health, maxHealth)
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
      local min = math.floor(cooldown / 60)
      local seg = cooldown % 60
      result = result .. string.format("|cFFFFFFFF%d:%02d|r", min, seg)
    else
      result = result .. string.format("|cFF00FF00%s|r", "Ready")
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

  -- Bottom instructions
  self:AddLine(" ")
  self:AddLine("Left Click to open Pet Journal")
  self:AddLine("Right Click to open Options")
end

function dataobj:OnClick(button)
  if (button == "LeftButton") then
    TogglePetJournal(2)
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
