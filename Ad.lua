local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Fsys = ReplicatedStorage:FindFirstChild("Fsys")
local ClientData = require(ReplicatedStorage["ClientModules"]["Core"]["ClientData"])
local SharedConstants = require(ReplicatedStorage["ClientDB"]["SharedConstants"])

local EquippedPetsModule = (function()
  if (not Fsys) then
    Log("Fsys module loader not found in ReplicatedStorage. EquippedPets module cannot be loaded.", true)
    return nil
  end

  local LoadSuccess, Module = pcall(function()
    return require(Fsys).load("EquippedPets")
  end)

  if (not LoadSuccess or not Module) then
    Log("Failed to load EquippedPets module: " .. tostring(Module), true)
    return nil
  end

  Log("EquippedPets module loaded successfully.")
  return Module
end)()

local Ad = {["SmartFurnitureMap"] = {}}
local Config = getgenv().Config

local function Log(Message, IsWarning)
  if not Config.Debug then return end
  (IsWarning and warn or print)(Message)
end

do -- Initialize API
  local API = ReplicatedStorage:WaitForChild("API")
  loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/RenderAPI.lua"), true))()

  Ad.__api = {
    ["ailments"] = {
      ["choose_mystery_ailment"] = function(PetUniqueId, Choice)
        API["AilmentAPI/ChooseMysteryAilment"]:FireServer(PetUniqueId, "mystery", 1, Choice)
      end
    };
    ["housing"] = {
      ["activate_interior_furniture"] = function(InteriorUniqueId, FurnitureUniqueId, UseBlock, PetModel)
        API["HousingAPI/ActivateInteriorFurniture"]:InvokeServer(InteriorUniqueId, FurnitureUniqueId, UseBlock, PetModel)
      end,
      ["push_furniture_changes"] = function(FurnitureChanges)
        API["HousingAPI/PushFurnitureChanges"]:FireServer(FurnitureChanges)
      end,
      ["subscribe_to_house"] = function(Player)
        API["HousingAPI/SubscribeToHouse"]:FireServer(Player)
      end,
      ["buy_furnitures"] = function(ItemsToBuy)
        API["HousingAPI/BuyFurnitures"]:InvokeServer(ItemsToBuy)
      end,
      ["activate_furniture"] = function(Player, FurnitureName, SeatToUse, PositionData, PetModel)
        API["HousingAPI/ActivateFurniture"]:InvokeServer(Player, FurnitureName, SeatToUse, PositionData, PetModel)
      end
    };
    ["pet_object"] = {
      ["create_pet_object"] = function(CreatorType, ObjectData)
        API["PetObjectAPI/CreatePetObject"]:InvokeServer(CreatorType, ObjectData)
      end,
      ["consume_food_object"] = function(FoodObject, PetUniqueId)
        API["PetObjectAPI/ConsumeFoodObject"]:FireServer(FoodObject, PetUniqueId)
      end
    };
    ["tool"] = {
      ["unequip"] = function(ToolUniqueId, Options)
        API["ToolAPI/Unequip"]:InvokeServer(ToolUniqueId, Options)
      end,
      ["equip"] = function(ToolUniqueId, Options)
        API["ToolAPI/Equip"]:InvokeServer(ToolUniqueId, Options)
      end,
      ["unequip_all"] = function()
        API["ToolAPI/UnequipAll"]:InvokeServer()
      end
    };
    ["adopt"] = {
      ["use_stroller"] = function(Player, PetModel, TouchToSit)
        API["AdoptAPI/UseStroller"]:InvokeServer(Player, PetModel, TouchToSit)
      end,
      ["hold_baby"] = function(PetModel)
        API["AdoptAPI/HoldBaby"]:FireServer(PetModel)
      end,
      ["eject_baby"] = function(PetModel)
        API["AdoptAPI/EjectBaby"]:FireServer(PetModel)
      end
    };
    ["location"] = {
      ["set_location"] = function(LocationName, Player, TeleportType)
        API["LocationAPI/SetLocation"]:FireServer(LocationName, Player, TeleportType)
      end
    };
    ["pet"] = {
      ["exit_furniture_use_states"] = function()
        API["PetAPI/ExitFurnitureUseStates"]:InvokeServer()
      end
    };
    ["shop"] = {
      ["buy_item"] = function(Category, ItemName, Options)
        return API["ShopAPI/BuyItem"]:InvokeServer(Category, ItemName, Options)
      end
    };
  }
end

local AILMENT_TO_FURNITURE_MODEL_MAP = {
  ["thirsty"] = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" };
  ["hungry"] = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" };
  ["toilet"] = { "AilmentsRefresh2024LitterBox", "ailments_refresh_2024_litter_box" };
  ["dirty"] = { "ModernShower", "modernshower" };
  ["sleepy"] = { "BasicCrib", "basiccrib" };
}

local AILMENT_KEYWORDS_MAP = {
  ["dirty"] = {"shower", "bath", "tub"};
  ["sleepy"] = {"pet bed", "crib"};
  ["toilet"] = {"toilet", "litter box"};
}

--[[
  @param self table -- The table that contains the function
  @param PetModel table -- The pet model
  @return table -- The first sitable furniture
]]
function Ad:STUBBED_find_first_sitable(PetModel)
  return nil
end

--[[
  Checks if the given pet is currently equipped by the player.
  @param PetModel Model -- The pet model to check
  @return boolean -- true if equipped, false otherwise (stub: always returns true)

  Example:
  ```lua
  local IsEquipped = Ad:is_pet_equipped(PetModel)
  ```
]]
function Ad:STUBBED_is_pet_equipped(PetModel)
  -- STUB: Implement actual equipped check
  return true
end

--[[
  Checks if the given item (by unique ID) is currently equipped by the player.
  @param ItemUniqueId string -- The unique ID of the item
  @return boolean -- true if equipped, false otherwise (stub: always returns true)

  Example:
  ```lua
  local IsEquipped = Ad:is_item_equipped(ItemUniqueId)
  ```
]]
function Ad:STUBBED_is_item_equipped(ItemUniqueId)
  -- STUB: Implement actual equipped check
  return true
end

--[[
  Gets the player's current location as a string or enum.
  @return string -- The player's current location (stub: always returns 'Unknown')

  Example:
  ```lua
  local Location = Ad:get_player_location()
  ```
]]
function Ad:STUBBED_get_player_location()
  -- STUB: Implement actual location retrieval
  return "Unknown"
end

--[[
  Checks if the given pet is currently performing the specified task.
  @param PetModel Model -- The pet model to check
  @param TaskName string -- The name of the task
  @return boolean -- true if the pet is doing the task, false otherwise (stub: always returns false)

  Example:
  ```lua
  local IsDoingTask = Ad:is_pet_doing_task(PetModel, "ride")
  ```
]]
function Ad:STUBBED_is_pet_doing_task(PetModel, TaskName)
  -- STUB: Implement actual task check
  return false
end

--[[
  Checks if the pet was unequipped or the player died during a task process.
  @param PetModel Model -- The pet model to check
  @return boolean -- true if unequipped or player died, false otherwise (stub: always returns false)

  Example:
  ```lua
  local WasInterrupted = Ad:was_pet_unequipped_or_player_died(PetModel)
  ```
]]
function Ad:STUBBED_was_pet_unequipped_or_player_died(PetModel)
  -- STUB: Implement actual interruption check
  return false
end

--[[
  Returns the unique ID of the default squeaky bone toy ('squeaky_bone_default') from the player's toy inventory.
  @param self table -- The table that contains the function
  @return string? -- The unique ID if found, or nil if not found

  Example:
  ```lua
  local UniqueId = Ad:get_default_throw_toy_unique()
  ```
]]
function Ad:get_default_throw_toy_unique()
  local PlayerData = self:get_player_data()
  if not PlayerData then return end

  local Toys = PlayerData["inventory"].toys
  if not Toys then
    Log("get_default_throw_toy_unique: Could not access player toy inventory.", true)
    return nil
  end

  for UniqueId, Info in Toys do
    if (Info and string.lower(Info["kind"] or "") == "squeaky_bone_default") then
      return UniqueId
    end
  end
  Log("get_default_throw_toy_unique: Could not find 'squeaky_bone_default' in toy inventory.", true)
  return nil
end

--[[
  Returns the unique ID of the default stroller ('stroller-default') from the player's inventory.
  @return string? -- The unique ID if found, or nil if not found

  Example:
  ```lua
  local UniqueId = Ad:get_default_stroller_unique()
  ```
]]
function Ad:get_default_stroller_unique()
  local PlayerData = self:get_player_data()
  if not PlayerData then return end
  local Strollers = PlayerData["inventory"] and PlayerData["inventory"].strollers
  if not Strollers then
    Log("get_default_stroller_unique: Could not access player stroller inventory.", true)
    return nil
  end
  for UniqueId, Info in Strollers do
    if (Info and string.lower(Info["kind"] or "") == "stroller-default") then
      return UniqueId
    end
  end
  Log("get_default_stroller_unique: Could not find 'stroller-default' in stroller inventory.", true)
  return nil
end

--[[
  @param self table -- The table that contains the function
  @param PetModel table -- The pet model
  @return string -- The unique ID of the pet
]]
function Ad:get_pet_unique_id_string(PetModel)
  if (not PetModel) then
    Log("GetPetUniqueIdString: Called with a nil PetModel.", true)
    return "stub_pet_unique_id_error"
  end

  if (EquippedPetsModule) then
    local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
    if (EquippedWrappers) then
      for _, Wrapper in EquippedWrappers do
        if (Wrapper["char"] == PetModel) then
          if (Wrapper["pet_unique"] and typeof(Wrapper["pet_unique"]) == "string") then
            return Wrapper["pet_unique"]
          else
            Log(string.format("GetPetUniqueIdString: PetModel '%s' found in EquippedPetsModule, but its 'pet_unique' property is missing or not a string. Trying other methods.", PetModel["Name"] or "Unnamed"), true)
          end
        end
      end
    else
      Log("GetPetUniqueIdString: EquippedPetsModule.get_my_equipped_char_wrappers() returned nil or an empty list. Cannot check module for ID.", true)
    end
  end

  local PetIdentifierDescription = "an unknown PetModel instance"
  if (PetModel["Name"] and typeof(PetModel["Name"]) == "string") then
    PetIdentifierDescription = string.format("PetModel named '%s'", PetModel["Name"])
  elseif (typeof(PetModel) == "Instance") then
    PetIdentifierDescription = string.format("PetModel instance '%s'", PetModel:GetFullName())
  elseif (PetModel) then
    PetIdentifierDescription = string.format("PetModel (type: %s, tostring: %s)", typeof(PetModel), tostring(PetModel))
  end

  Log(string.format("GetPetUniqueIdString: Could not determine a string unique ID for %s using any available method.", PetIdentifierDescription), true)
  return "stub_pet_unique_id_error"
end

--[[
  @param self table -- The table that contains the function
  @param ActualFurnitureModel table -- The furniture model
  @param FunctionContextName string -- The name of the function calling this
  @param ParentContainerForContext table -- The parent container for the context
  @return string -- The unique ID of the furniture
]]
function Ad:get_furniture_unique_id_from_model(ActualFurnitureModel, FunctionContextName, ParentContainerForContext)
  if not ActualFurnitureModel then
    Log(string.format("%s: Called GetFurnitureUniqueIdFromModel with a nil ActualFurnitureModel.", FunctionContextName), true)
    return nil, nil
  end

  local FurnitureUniqueId = nil
  local IdSource = nil
  local ContainerNameForWarning = (ParentContainerForContext and ParentContainerForContext["Name"]) or "UnknownContainer"

  FurnitureUniqueId = ActualFurnitureModel:GetAttribute("furniture_unique")
  if (FurnitureUniqueId and typeof(FurnitureUniqueId) == "string") then
    IdSource = "attribute (furniture_unique on model)"
  else
    Log(string.format("%s: Model '%s' in container '%s' is missing 'furniture_unique' string attribute. Falling back to model name.", FunctionContextName, ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarning), true)
    FurnitureUniqueId = ActualFurnitureModel["Name"]
    if (typeof(FurnitureUniqueId) == "string") then
      IdSource = "model_name (fallback)"
    else
      Log(string.format("%s: Model '%s' in container '%s' also has an invalid non-string model name. Cannot derive ID.", FunctionContextName, ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarning), true)
      FurnitureUniqueId = nil
      IdSource = nil
    end
  end
  return FurnitureUniqueId, IdSource
end

--[[
  @param self table -- The table that contains the function
  @param FurnitureModel table -- The furniture model
  @return table -- The vacant seat in the furniture
]]
function Ad:get_vacant_seat_from_model(FurnitureModel)
  if not FurnitureModel then
    -- warn("GetVacantSeatFromModel: Called with a nil FurnitureModel.") 
    return nil
  end
  local UseBlocks = FurnitureModel:FindFirstChild("UseBlocks")
  if UseBlocks then
    local Seats = UseBlocks:GetChildren()
    if #Seats > 0 then
      return Seats[1]
    end
  end
  return nil
end

--[[
  @param self table -- The table that contains the function
  @param AilmentName string -- The name of the ailment
  @return table -- The first furniture that matches the ailment
]]
function Ad:find_first_ailment_furniture(AilmentName)
  local Keywords = AILMENT_KEYWORDS_MAP[AilmentName]
  if not Keywords then
    Log("FindFirstAilmentFurniture: No keywords defined for ailment: " .. AilmentName, true)
    return nil
  end

  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if not FurnitureFolder then
    Log("FindFirstAilmentFurniture: workspace.HouseInteriors.furniture not found.", true)
    return nil
  end

  for _, ContainerFolderInstance in FurnitureFolder:GetChildren() do
    if ContainerFolderInstance:IsA("Folder") or ContainerFolderInstance:IsA("Model") then
      for _, ActualFurnitureModel in ContainerFolderInstance:GetChildren() do
        if ActualFurnitureModel:IsA("Model") or ActualFurnitureModel:IsA("BasePart") then
          local FurnitureUniqueId, IdSource = self:get_furniture_unique_id_from_model(ActualFurnitureModel, "FindFirstAilmentFurniture", ContainerFolderInstance)

          if FurnitureUniqueId then
            local LowercaseActualModelName = string.lower(ActualFurnitureModel["Name"])
            for _, Keyword in Keywords do
              if string.find(LowercaseActualModelName, string.lower(Keyword)) then
                local VacantSeatInstance = self:get_vacant_seat_from_model(ActualFurnitureModel)

                Log(string.format("FindFirstAilmentFurniture: Found generic furniture. UniqueID: '%s' (source: %s), ModelName (actual): '%s', Container: '%s', For Ailment: '%s', Keyword: '%s', VacantSeat: %s",
                  FurnitureUniqueId, IdSource, ActualFurnitureModel["Name"], ContainerFolderInstance["Name"], AilmentName, Keyword, VacantSeatInstance and VacantSeatInstance["Name"] or "nil"), true)

                return {
                  ["name"] = FurnitureUniqueId;
                  ["model"] = ActualFurnitureModel;
                  ["vacant_seat"] = VacantSeatInstance;
                }
              end
            end
          end
        end
      end
    end
  end

  Log("FindFirstAilmentFurniture: No suitable owned furniture found for ailment: " .. AilmentName .. " (matching keywords, with a valid unique ID from model attribute or model name, and correct model structure).", true)
  return nil
end

--[[
  @param self table -- The table that contains the function
  @param PetModel table -- The pet model
  @param AilmentName string -- The name of the ailment
  @return boolean -- Whether the ailment exists for the pet
]]
function Ad:verify_ailment_exists(PetModel, AilmentName)
  if (not PetModel) then
    Log("VerifyAilmentExists: PetModel is nil.", true)
    return false
  end
  if (not AilmentName) then
    Log("VerifyAilmentExists: AilmentName is nil.", true)
    return false
  end

  local PetUniqueId = self:get_pet_unique_id_string(PetModel)
  if (not PetUniqueId or PetUniqueId == "stub_pet_unique_id_error") then
    Log("VerifyAilmentExists: Could not get a valid Unique ID for PetModel: " .. PetModel["Name"] .. ". Cannot verify ailment.", true)
    return false
  end

  local PlayerData = self:get_player_data()
  if not PlayerData then return false end

  if (not PlayerData["ailments_manager"] or not PlayerData["ailments_manager"]["ailments"]) then
    Log("VerifyAilmentExists: Could not find ailment data path for LocalPlayer ('" .. LocalPlayer["Name"] .. "') in ClientData.", true)
    return false
  end

  local AllPetsAilmentInfo = PlayerData["ailments_manager"]["ailments"]
  local PetSpecificAilmentsInfo = AllPetsAilmentInfo[PetUniqueId]

  if (PetSpecificAilmentsInfo and typeof(PetSpecificAilmentsInfo) == "table") then
    for _, AilmentDataEntry in PetSpecificAilmentsInfo do
      if (typeof(AilmentDataEntry) == "table" and AilmentDataEntry["kind"] == AilmentName) then
        -- print(string.format("VerifyAilmentExists: Ailment '%s' FOUND for pet '%s'.", AilmentName, PetUniqueId))
        return true
      end
    end
  end

  -- print(string.format("VerifyAilmentExists: Ailment '%s' NOT FOUND for pet '%s'.", AilmentName, PetUniqueId))
  return false
end

--[[
  @param self table -- The table that contains the function
  @return table -- The smart furniture
]]
function Ad:get_smart_furniture()
  local FoundItems = {}
  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if (not FurnitureFolder) then
    Log("GetSmartFurniture: workspace.HouseInteriors.furniture not found!", true)
    return FoundItems
  end

  for Ailment, FurnitureData in AILMENT_TO_FURNITURE_MODEL_MAP do
    local ModelNameKey = FurnitureData[1]
    local ActualFurnitureModel = FurnitureFolder:FindFirstChild(ModelNameKey, true)

    if (ActualFurnitureModel) then
      local ParentContainer = ActualFurnitureModel["Parent"]

      if not (ParentContainer and ParentContainer["Parent"] == FurnitureFolder) then
        local ContainerNameForContext = ParentContainer and ParentContainer["Name"] or "N/A (Parent not found or no name)"
        Log(string.format("GetSmartFurniture: Smart furniture model '%s' (searched as '%s') found, but its parent ('%s') is not a direct container in FurnitureFolder. Skipping for ailment '%s'.", ActualFurnitureModel["Name"], ModelNameKey, ContainerNameForContext, Ailment), true)
      else
        local FurnitureUniqueId, IdSource = self:get_furniture_unique_id_from_model(ActualFurnitureModel, "GetSmartFurniture", ParentContainer)

        if (FurnitureUniqueId) then
          local VacantSeatInstance = self:get_vacant_seat_from_model(ActualFurnitureModel)

          FoundItems[Ailment] = {
            ["name"] = FurnitureUniqueId;
            ["model"] = ActualFurnitureModel;
            ["vacant_seat"] = VacantSeatInstance;
          }
          Log(string.format("GetSmartFurniture: Found/processed smart furniture. UniqueID: '%s' (source: %s), Model: '%s'. For ailment '%s'. Searched for: %s", FurnitureUniqueId, IdSource, ActualFurnitureModel["Name"], Ailment, ModelNameKey))
        else
          local ContainerNameForWarn = ParentContainer and ParentContainer["Name"] or "UnknownContainer"
          Log(string.format("GetSmartFurniture: Could not derive Unique ID for smart model '%s' (container: '%s') for ailment '%s'. It will not be registered as smart furniture.", ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarn, Ailment), true)
        end
      end
    end
  end
  return FoundItems
end

--[[
  @param self table -- The table that contains the function
  @return table -- The smart furniture
]]
function Ad:initialize_smart_furniture()
  local FurnitureDB = require(ReplicatedStorage["ClientDB"]["Housing"]["FurnitureDB"])
  local PlayerData = self:get_player_data()
  local CurrentMoney = nil
  if (PlayerData and PlayerData["money"]) then
    CurrentMoney = PlayerData["money"]
  else
    Log("InitializeSmartFurniture: Could not retrieve player money from ClientData. Cannot perform cost checks.", true)
  end
  if (not FurnitureDB) then
    Log("InitializeSmartFurniture: FurnitureDB module not found or failed to load. Cannot perform cost checks or determine item costs.", true)
  end
  local CurrentSmartFurnitureItems = self:get_smart_furniture()
  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if (not FurnitureFolder) then
    Log("InitializeSmartFurniture: workspace.HouseInteriors.furniture not found! Cannot process smart furniture.", true)
    self.SmartFurnitureMap = CurrentSmartFurnitureItems
    return
  end
  local ItemsToBuy = {}
  local ItemKindsToModelNames = {}
  for Ailment, FurnitureData in AILMENT_TO_FURNITURE_MODEL_MAP do
    if (not CurrentSmartFurnitureItems[Ailment]) then
      local ModelName = FurnitureData[1]
      local KindName = FurnitureData[2]
      local CanAfford = true
      local Cost = 0
      if (FurnitureDB and CurrentMoney ~= nil) then
        local ItemDBInfo = FurnitureDB[KindName]
        if (ItemDBInfo and ItemDBInfo["cost"]) then
          Cost = ItemDBInfo["cost"]
          if (CurrentMoney < Cost) then
            CanAfford = false
            Log(string.format("InitializeSmartFurniture: Cannot afford '%s' (model: %s) for ailment '%s'. Cost: %d, Player Money: %d.", KindName, ModelName, Ailment, Cost, CurrentMoney), true)
          end
        else
          Log(string.format("InitializeSmartFurniture: Could not find cost information for '%s' (model: %s) in FurnitureDB. Assuming it's free or data is missing.", KindName, ModelName), true)
        end
      elseif (CurrentMoney == nil and FurnitureDB and FurnitureDB[KindName] and FurnitureDB[KindName]["cost"] and FurnitureDB[KindName]["cost"] > 0) then
        Log(string.format("InitializeSmartFurniture: Player money not available, but '%s' (model: %s) has a cost in DB. Purchase might fail.", KindName, ModelName), true)
      end
      if (CanAfford) then
        table.insert(ItemsToBuy, { ["kind"] = KindName; ["properties"] = { cframe = CFrame.new(0, -1000, 0) }; })
        ItemKindsToModelNames[KindName] = ModelName
        Log(string.format("InitializeSmartFurniture: Queuing purchase for '%s' (model: %s, cost: %d) for ailment '%s'. Player Money: %s", KindName, ModelName, Cost, Ailment, CurrentMoney or 'Unknown'), true)
      end
    end
  end
  if (#ItemsToBuy > 0) then
    local Success, ErrorMessage = pcall(function()
      Ad.__api.housing.buy_furnitures(ItemsToBuy)
    end)
    if (not Success) then
      Log(string.format("InitializeSmartFurniture: Error purchasing furniture: %s", tostring(ErrorMessage)), true)
      self.SmartFurnitureMap = CurrentSmartFurnitureItems
      return
    end

    task.wait()

    local Success, ErrorMessage = pcall(function()
      Ad.__api.housing.push_furniture_changes({})
    end)
    if (not Success) then
      Log(string.format("InitializeSmartFurniture: Error pushing furniture changes: %s", ErrorMessage or "Unknown error"), true)
    end

    task.wait()

    for _, BoughtItemInfo in ItemsToBuy do
      local ModelNameToFind = ItemKindsToModelNames[BoughtItemInfo["kind"]]
      if (ModelNameToFind) then
        local ActualNewFurnitureModel = FurnitureFolder:FindFirstChild(ModelNameToFind, true)
        if (ActualNewFurnitureModel) then
          local ParentContainer = ActualNewFurnitureModel["Parent"]

          if not (ParentContainer and ParentContainer["Parent"] == FurnitureFolder) then
            local ContainerNameForContext = ParentContainer and ParentContainer["Name"] or "N/A (Parent not found or no name)"
            Log(string.format("InitializeSmartFurniture: Found purchased model '%s' (Kind: %s), but its parent structure is unexpected ('%s' is not in FurnitureFolder). Cannot add to smart map.", ActualNewFurnitureModel["Name"] or "UnnamedModel", BoughtItemInfo["kind"], ContainerNameForContext), true)
          else
            local FurnitureUniqueId, IdSource = self:get_furniture_unique_id_from_model(ActualNewFurnitureModel, "InitializeSmartFurniture", ParentContainer)

            if (FurnitureUniqueId) then
              local VacantSeatInstance = self:get_vacant_seat_from_model(ActualNewFurnitureModel)

              local FurnitureObject = {
                ["name"] = FurnitureUniqueId;
                ["model"] = ActualNewFurnitureModel;
                ["vacant_seat"] = VacantSeatInstance;
              }

              for AilmentInner, FurnitureDataInner in AILMENT_TO_FURNITURE_MODEL_MAP do
                local CurrentModelNameFromMap = FurnitureDataInner[1]
                if ActualNewFurnitureModel["Name"] == CurrentModelNameFromMap and not CurrentSmartFurnitureItems[AilmentInner] then
                  CurrentSmartFurnitureItems[AilmentInner] = FurnitureObject
                  local ContainerNameForLog = ParentContainer and ParentContainer["Name"] or "UnknownContainer"
                  Log(string.format("InitializeSmartFurniture: Successfully processed purchased item '%s' (UniqueID from %s: '%s', Container: '%s') for ailment '%s'.", ActualNewFurnitureModel["Name"] or "UnnamedModel", IdSource or "N/A", FurnitureUniqueId, ContainerNameForLog, AilmentInner), true)
                  break
                end
              end
            else
              local ContainerNameForWarn = ParentContainer and ParentContainer["Name"] or "UnknownContainer"
              Log(string.format("InitializeSmartFurniture: Could not derive a Unique ID for purchased model '%s' (Kind: %s, Container: '%s') after attribute/name check. Cannot add to smart map.", ActualNewFurnitureModel["Name"] or "UnnamedModel", BoughtItemInfo["kind"], ContainerNameForWarn), true)
            end
          end
        else
          Log(string.format("InitializeSmartFurniture: Failed to find purchased item model '%s' (kind: %s) recursively in workspace after buying.", ModelNameToFind, BoughtItemInfo["kind"]), true)
        end
      end
    end
  end
  self.SmartFurnitureMap = CurrentSmartFurnitureItems
end

--[[
  Teleports the player to a specific ailment location or sets their CFrame directly for certain locations.
  @param Location string -- The location name (e.g., "beach", "park", "camping")
]]
function Ad:teleport_to_ailment_location(Location)
  local MainLocationMap = {
    ["beach"] = workspace["StaticMap"]["Beach"]["BeachPartyAilmentTarget"]["CFrame"];
    ["park"] = workspace["StaticMap"]["Park"]["BoredAilmentTarget"]["CFrame"];
    ["camping"] = workspace["StaticMap"]["Campsite"]["CampsiteOrigin"]["CFrame"];
  }

  local Success, ErrorMessage = pcall(function()
    if (MainLocationMap[Location]) then
      Ad.__api.location.set_location("MainMap", nil, "Default")
      task.wait()
      LocalPlayer["Character"]["HumanoidRootPart"]["CFrame"] = MainLocationMap[Location] * CFrame.new(0, 5, 0)
    else
      Ad.__api.location.set_location(Location, nil, "Default")
    end
  end)

  if (not Success) then
    Log(string.format("Error teleporting to %s: %s", Location, ErrorMessage or "Unknown error"), true)
  end
end

--[[
  @param SitableFurnitureObject table -- The furniture object to check
  @return boolean -- Whether the furniture is owned
]]
function Ad:is_sitable_owned(SitableFurnitureObject)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"]) then
    Log(string.format("is_sitable_owned: Invalid arguments. SitableFurnitureObject: %s", tostring(SitableFurnitureObject)), true)
    return
  end
  local ParentName = SitableFurnitureObject["model"].Parent.Name
  local Segments = string.split(ParentName, "/")
  local OwnerName = Segments[1]
  if (OwnerName and OwnerName:lower() == LocalPlayer.Name:lower()) then
    return true
  end
  return false
end

--[[
  Places a sitable furniture object at a given CFrame.
  @param SitableFurnitureObject table -- The furniture object to use
  @param TargetCFrame CFrame -- The CFrame to place the furniture at
]]
function Ad:place_sitable_at_cframe(SitableFurnitureObject, TargetCFrame)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not TargetCFrame) then
    Log(string.format("PlaceSitableAtCFrame: Invalid arguments. SitableFurnitureObject: %s, TargetCFrame: %s", tostring(SitableFurnitureObject), tostring(TargetCFrame)), true)
    return
  end
  local Success, ErrorMessage = pcall(function()
    Ad.__api.housing.push_furniture_changes({{unique = SitableFurnitureObject["name"], cframe = TargetCFrame}})
  end)
  if (not Success) then
    Log(string.format("PlaceSitableAtCFrame: Error placing furniture: %s", ErrorMessage or "Unknown error"), true)
  end
end

--[[
  Uses a sitable furniture object at a given CFrame for a pet.
  @param SitableFurnitureObject table -- The furniture object to use
  @param TargetCFrame CFrame -- The CFrame to place the furniture at
  @param PetModel Instance -- The pet model to use the furniture
]]
function Ad:use_sitable_at_cframe(SitableFurnitureObject, TargetCFrame, PetModel)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not TargetCFrame or not PetModel) then
    Log(string.format("UseSitableAtCFrame: Invalid arguments. SitableFurnitureObject: %s, TargetCFrame: %s, PetModel: %s", tostring(SitableFurnitureObject), tostring(TargetCFrame), tostring(PetModel)), true)
    return
  end

  local SeatToUse = "UseBlock"
  if (SitableFurnitureObject["vacant_seat"] and SitableFurnitureObject["vacant_seat"]["Name"]) then
    SeatToUse = SitableFurnitureObject["vacant_seat"]["Name"]
  end

  local Success, ErrorMessage = pcall(function()
    Ad.__api.housing.activate_furniture(LocalPlayer, SitableFurnitureObject["name"], SeatToUse, {["cframe"] = TargetCFrame}, PetModel)
  end)
  if (not Success) then
    Log(string.format("UseSitableAtCFrame: Error activating furniture: %s", ErrorMessage or "Unknown error"), true)
  end
end

--[[
  Places and uses a sitable furniture object at a given CFrame for a pet.
  @param SitableFurnitureObject table -- The furniture object to use
  @param TargetCFrame CFrame -- The CFrame to place the furniture at
  @param PetModel Instance -- The pet model to use the furniture
]]
function Ad:place_and_use_sitable_at_cframe(SitableFurnitureObject, TargetCFrame, PetModel)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not TargetCFrame) then
    Log(string.format("PlaceAndUseSitableAtCFrame: Invalid arguments. SitableFurnitureObject: %s, TargetCFrame: %s", tostring(SitableFurnitureObject), tostring(TargetCFrame)), true)
    return
  end

  local Success, ErrorMessage = pcall(function()
    Ad.__api.housing.push_furniture_changes({{unique = SitableFurnitureObject["name"], cframe = TargetCFrame}})
  end)
  if (not Success) then
    Log(string.format("PlaceAndUseSitableAtCFrame: Error placing furniture: %s", ErrorMessage or "Unknown error"), true)
  end

  task.wait()

  local SeatToUse = "UseBlock"
  if (SitableFurnitureObject["vacant_seat"] and SitableFurnitureObject["vacant_seat"]["Name"]) then
    SeatToUse = SitableFurnitureObject["vacant_seat"]["Name"]
  end
  local Success, ErrorMessage = pcall(function()
    Ad.__api.housing.activate_furniture(LocalPlayer, SitableFurnitureObject["name"], SeatToUse, {["cframe"] = TargetCFrame}, PetModel)
  end)
  if (not Success) then
    Log(string.format("PlaceAndUseSitableAtCFrame: Error activating furniture: %s", ErrorMessage or "Unknown error"), true)
  end
end

--[[
  Uses a sitable furniture object at the player's character CFrame for a pet.
  @param SitableFurnitureObject table -- The furniture object to use
  @param PetModel Instance -- The pet model to use the furniture
]]
function Ad:use_sitable_at_character_cframe(SitableFurnitureObject, PetModel)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not PetModel) then
    Log(string.format("UseSitableAtCharacterCFrame: Invalid arguments. SitableFurnitureObject: %s, PetModel: %s", tostring(SitableFurnitureObject), tostring(PetModel)), true)
    return
  end

  if (not LocalPlayer["Character"] or not LocalPlayer["Character"]:FindFirstChild("HumanoidRootPart")) then
    Log("UseSitableAtCharacterCFrame: LocalPlayer.Character.HumanoidRootPart not found. Cannot determine target CFrame.", true)
    return
  end
  local TargetCFrame = LocalPlayer["Character"]["HumanoidRootPart"]["CFrame"]

  local SeatToUse = "UseBlock"
  if (SitableFurnitureObject["vacant_seat"] and SitableFurnitureObject["vacant_seat"]["Name"]) then
    SeatToUse = SitableFurnitureObject["vacant_seat"]["Name"]
  end

  Log(string.format("UseSitableAtCharacterCFrame: Activating furniture '%s' (Seat: '%s') at player CFrame for Pet: '%s'", SitableFurnitureObject["name"], SeatToUse, PetModel["Name"]), true)
  local Success, ErrorMessage = pcall(function()
    Ad.__api.housing.activate_furniture(LocalPlayer, SitableFurnitureObject["name"], SeatToUse, {["cframe"] = TargetCFrame}, PetModel)
  end)
  if (not Success) then
    Log(string.format("UseSitableAtCharacterCFrame: Error activating furniture: %s", ErrorMessage or "Unknown error"), true)
  end
end

--[[
  @param self table -- The table that contains the function
  @param AilmentTargetCFrame CFrame -- The CFrame to place the furniture at
  @param LocationName string -- The name of the location
  @param PetModel table -- The pet model
  @param AilmentName string -- The name of the ailment
]]
function Ad:handle_smart_or_teleport_ailment(AilmentTargetCFrame, LocationName, PetModel, AilmentName)
  local FurnitureToUse = nil
  if (next(self.SmartFurnitureMap) == nil) then
    self:initialize_smart_furniture() 
  end

  FurnitureToUse = self.SmartFurnitureMap[AilmentName]

  if (not FurnitureToUse) then
    FurnitureToUse = self:find_first_ailment_furniture(AilmentName)
  end

  if (FurnitureToUse) then
    self:place_and_use_sitable_at_cframe(FurnitureToUse, AilmentTargetCFrame, PetModel)
    return
  end

  self:teleport_to_ailment_location(LocationName)
end

function Ad:handle_main_map_ailment(AilmentTargetCFrame, PetModel)
  local Success, ErrorMessage = pcall(function()
    Ad.__api.adopt.hold_baby(PetModel)
  end)
  if (not Success) then
    Log("handle_main_map_ailment: Failed to hold pet: " .. (ErrorMessage or "Unknown error"), true)
    return
  end

  task.wait(0.5)

  local Character = LocalPlayer["Character"]
  if (not Character or not Character:FindFirstChild("HumanoidRootPart")) then
    Log("handle_main_map_ailment: LocalPlayer.Character.HumanoidRootPart not found. Cannot move to target CFrame.", true)
    return
  end

  local NewPivot = CFrame.new(AilmentTargetCFrame.Position + Vector3.new(0, 5, 0))
  Character:PivotTo(NewPivot)
end

--[[
  Returns the PlayerData table for the LocalPlayer from ClientData.
  @param self table -- The table that contains the function
  @return table? -- The PlayerData table, or nil if not found

  Example:
  ```lua
  local PlayerData = Ad:get_player_data()
  ```
]]
function Ad:get_player_data()
  local PlayerData = ClientData.get_data()[LocalPlayer["Name"]]
  if not PlayerData then
    Log("Ad:get_player_data: Failed to retrieve PlayerData", true)
  end
  return PlayerData
end

--[[
  Purchases an edible item by name (from the 'food' category) and has the pet consume it. Handles all API calls and error conditions for the process.

  @param self table -- The table that contains the function
  @param PetModel Model -- The pet model to feed
  @param ItemName string -- The name of the item to purchase and consume (e.g., "water", "apple")
  @return boolean -- true if the process was initiated, false if failed

  Example:
  ```lua
  local Success = Ad:purchase_and_consume_item(PetModel, "water")
  ```
]]
function Ad:purchase_and_consume_item(PetModel, ItemName)
  if (not PetModel) then Log("purchase_and_consume_item: PetModel is nil.", true) return false end
  if (not ItemName or typeof(ItemName) ~= "string") then Log("purchase_and_consume_item: ItemName is invalid.", true) return false end

  local PetUniqueId = self:get_pet_unique_id_string(PetModel)
  if (not PetUniqueId or PetUniqueId == "stub_pet_unique_id_error") then
    Log("purchase_and_consume_item: Could not get a valid unique ID for PetModel.", true)
    return false
  end

  -- Always use 'food' as the category for edible items
  local Category = "food"

  local BuySuccess, BuyResult = pcall(function()
    return Ad.__api.shop.buy_item(Category, ItemName, {})
  end)
  if (not BuySuccess) then
    Log("purchase_and_consume_item: Failed to purchase item: " .. tostring(BuyResult), true)
    return false
  end

  task.wait(0.5)

  local PlayerData = self:get_player_data()
  if not PlayerData then return false end

  local Inventory = PlayerData["inventory"]
  local ItemTable = Inventory[Category]
  if (not ItemTable) then
    Log("purchase_and_consume_item: Inventory category not found: " .. tostring(Category), true)
    return false
  end

  local LowerItem = string.lower(ItemName)
  local FoundUniqueId = nil
  for UniqueId, Info in ItemTable do
    if (Info and string.lower(Info["kind"] or "") == LowerItem) then
      FoundUniqueId = UniqueId
      break
    end
  end
  if (not FoundUniqueId) then
    Log("purchase_and_consume_item: Could not find purchased item in inventory: " .. tostring(ItemName), true)
    return false
  end

  local CreateSuccess, CreateResult = pcall(function()
    return Ad.__api.pet_object.create_pet_object(
      "__Enum_PetObjectCreatorType_2",
      {
        ["additional_consume_uniques"] = {};
        ["pet_unique"] = PetUniqueId;
        ["unique_id"] = FoundUniqueId;
      }
    )
  end)
  if (not CreateSuccess) then
    Log("purchase_and_consume_item: Failed to create item object: " .. tostring(CreateResult), true)
    return false
  end

  local ConsumeSuccess, ConsumeResult = pcall(function()
    Ad.__api.pet_object.consume_food_object(Instance.new("Model", nil), PetUniqueId)
  end)
  if (not ConsumeSuccess) then
    Log("purchase_and_consume_item: Failed to fire consume event: " .. tostring(ConsumeResult), true)
    return false
  end

  return true
end

--[[
  @param self table -- The table that contains the function
  @param PetModel table -- The pet model
  @param AilmentName string -- The name of the ailment
  @param TimeoutDurationSeconds number -- The timeout duration in seconds
  @param OptionalExtraConditionFn function -- The optional extra condition function
  @param ActionLambda function -- The action lambda function
]]
function Ad:execute_action_with_timeout(PetModel, AilmentName, TimeoutDurationSeconds, OptionalExtraConditionFn, ActionLambda)
  local ActionCoroutine = coroutine.create(function()
    return pcall(ActionLambda)
  end)

  local CoroutineResumeSuccess, WasActionPcallSuccessful, ActionPcallResultOrError = coroutine.resume(ActionCoroutine)

  if not CoroutineResumeSuccess then
    Log(string.format("ExecuteActionWithTimeout: Coroutine for action '%s' failed to resume: %s", AilmentName, tostring(WasActionPcallSuccessful)), true) -- Second arg is error if resume fails
    return false, "Coroutine resume failure: " .. tostring(WasActionPcallSuccessful)
  end

  if not WasActionPcallSuccessful then
    Log(string.format("ExecuteActionWithTimeout: ActionLambda for '%s' (pcall inside coroutine) failed: %s", AilmentName, tostring(ActionPcallResultOrError)), true)
    -- Decide if we should still wait for ailment clearance. For now, let's assume an action error means it likely won't clear as expected.
    -- However, the original script often waits even if the action has issues, so we'll proceed with waiting but acknowledge the error.
  end

  local StartTime = os.clock()
  local AilmentCleared = false
  local TimedOut = false
  local FinalMessage = ""

  repeat
    task.wait(0.2)

    local CurrentAilmentExists = self:verify_ailment_exists(PetModel, AilmentName)
    local ExtraConditionMet = true
    if OptionalExtraConditionFn then
      local ExtraSuccess, ExtraResult = pcall(OptionalExtraConditionFn)
      ExtraConditionMet = ExtraSuccess and ExtraResult
      if not ExtraSuccess then
        Log(string.format("ExecuteActionWithTimeout: Error in OptionalExtraConditionFn for '%s': %s", AilmentName, tostring(ExtraResult)), true)
      end
    end

    if not CurrentAilmentExists and ExtraConditionMet then
      AilmentCleared = true
      FinalMessage = string.format("Ailment '%s' for pet '%s' cleared successfully.", AilmentName, self:get_pet_unique_id_string(PetModel))
      if not WasActionPcallSuccessful then
        FinalMessage = FinalMessage .. string.format(" (Note: Initial action reported an error: %s)", tostring(ActionPcallResultOrError))
      end
      break
    end

    if os.clock() - StartTime > TimeoutDurationSeconds then
      TimedOut = true
      FinalMessage = string.format("TIMEOUT waiting for ailment '%s' on pet '%s' to clear after %d seconds. AilmentStillExists: %s, ExtraConditionMet: %s",
        AilmentName, self:get_pet_unique_id_string(PetModel), TimeoutDurationSeconds, tostring(CurrentAilmentExists), tostring(ExtraConditionMet))
      if not WasActionPcallSuccessful then
        FinalMessage = FinalMessage .. string.format(" (Note: Initial action also reported an error: %s)", tostring(ActionPcallResultOrError))
      end
      break
    end
  until AilmentCleared or TimedOut

  if TimedOut then
    local CoroutineStatus = coroutine.status(ActionCoroutine)
    if CoroutineStatus ~= "dead" then
      Log(string.format("ExecuteActionWithTimeout: Action coroutine for '%s' is still '%s' after timeout. It may complete or be stuck if it doesn't yield.", AilmentName, CoroutineStatus), true)
    end
  end

  return AilmentCleared, FinalMessage
end

--[[
  @param self table -- The table that contains the function
  @return table -- The current ailments
]]
function Ad:get_current_ailments()
  local PlayerData = self:get_player_data()
  local PetAilmentsResult = {}

  if (not PlayerData or not PlayerData["ailments_manager"] or not PlayerData["ailments_manager"]["ailments"]) then
    Log(string.format("GetCurrentAilments: Could not find ailment data for LocalPlayer ('%s') in ClientData. Structure might be unexpected or data not yet available.", LocalPlayer["Name"]), true)
    return PetAilmentsResult
  end

  for PetUnique, AilmentInfo in PlayerData["ailments_manager"]["ailments"] do
    local CurrentPetSpecificAilments = {}

    if type(AilmentInfo) == "table" then
      for AilmentName, AilmentData in AilmentInfo do
        if type(AilmentData) == "table" and AilmentData["kind"] then
          table.insert(CurrentPetSpecificAilments, AilmentData["kind"])
        end
      end
    end

    if #CurrentPetSpecificAilments > 0 then
      table.insert(PetAilmentsResult, {
        ["unique"] = PetUnique;
        ["ailments"] = CurrentPetSpecificAilments;
      })
    end
  end

  return PetAilmentsResult
end

--[[
  @param self table -- The table that contains the function
  @param PetUniqueIdToFind string -- The unique ID of the pet to find
  @return model -- The pet model
]]
function Ad:get_pet_model_by_unique_id(PetUniqueIdToFind) 
  if not EquippedPetsModule then
    Log("GetPetModelByUniqueId: EquippedPetsModule is not loaded. Cannot fetch pet model.", true)
    return nil
  end

  if not PetUniqueIdToFind then
    Log("GetPetModelByUniqueId: PetUniqueIdToFind is nil.", true)
    return nil
  end

  -- print(string.format("DEBUG: GetPetModelByUniqueId calling EquippedPetsModule.get_wrapper_from_unique for ID: %s", tostring(PetUniqueIdToFind)))
  local Wrapper = EquippedPetsModule.get_wrapper_from_unique(PetUniqueIdToFind, LocalPlayer)

  if Wrapper then
    -- print(string.format("DEBUG: GetPetModelByUniqueId: Wrapper FOUND for ID: %s. Wrapper type: %s", tostring(PetUniqueIdToFind), type(Wrapper)))
    local PetModel = Wrapper["char"]
    if PetModel and PetModel:IsA("Model") then
      return PetModel
    else
      Log(string.format("GetPetModelByUniqueId: Wrapper found for %s, but .char (PetModel) is missing or not a Model.", PetUniqueIdToFind), true)
      return nil
    end
  else
    -- print(string.format("DEBUG: GetPetModelByUniqueId: Wrapper NOT FOUND for ID: %s", tostring(PetUniqueIdToFind)))
    Log(string.format("GetPetModelByUniqueId: No wrapper found for unique ID: %s. Pet might not be equipped or ID is invalid.", PetUniqueIdToFind), true)
    return nil
  end
end

--[[
  @param self table -- The table that contains the function
  @return table -- The equipped pet models
]]
function Ad:get_my_equipped_pet_models()
  if not EquippedPetsModule then
    Log("GetMyEquippedPetModels: EquippedPetsModule is not loaded. Cannot fetch pet models.", true)
    return {}
  end

  local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
  local PetModels = {}

  if not EquippedWrappers or #EquippedWrappers == 0 then
    return PetModels
  end

  for _, Wrapper in EquippedWrappers do
    local PetModel = Wrapper["char"]
    if PetModel and PetModel:IsA("Model") then
      table.insert(PetModels, PetModel)
    else
      local PetUniqueId = Wrapper["pet_unique"]
      if PetUniqueId then
        Log(string.format("GetMyEquippedPetModels: Wrapper found for unique: %s - but pet model (char) is missing or invalid.", tostring(PetUniqueId)), true)
      else
        Log("GetMyEquippedPetModels: Wrapper found but pet model (char) is missing/invalid and no unique ID on wrapper.", true)
      end
    end
  end
  return PetModels
end

--[[
  @param self table -- The table that contains the function
  @return table -- The equipped pet unique IDs
]]
function Ad:get_my_equipped_pet_uniques()
  if not EquippedPetsModule then
    Log("GetMyEquippedPetUniques: EquippedPetsModule is not loaded. Cannot fetch pet unique IDs.", true)
    return {}
  end

  -- print("DEBUG: GetMyEquippedPetUniques calling EquippedPetsModule.get_my_equipped_char_wrappers()")
  local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()

  if not EquippedWrappers then
    -- print("DEBUG: GetMyEquippedPetUniques: EquippedPetsModule.get_my_equipped_char_wrappers() returned nil")
  else
    -- print("DEBUG: GetMyEquippedPetUniques: EquippedPetsModule.get_my_equipped_char_wrappers() returned a table with " .. #EquippedWrappers .. " wrappers.")
  end

  local PetUniqueIds = {}

  if not EquippedWrappers or #EquippedWrappers == 0 then
    return PetUniqueIds
  end

  for _, Wrapper in EquippedWrappers do
    local PetUniqueId = Wrapper["pet_unique"]
    if PetUniqueId and type(PetUniqueId) == "string" then
      table.insert(PetUniqueIds, PetUniqueId)
    else
      Log("GetMyEquippedPetUniques: Wrapper found but pet_unique ID is missing or not a string.", true)
    end
  end
  return PetUniqueIds
end

--[[
  @param self table -- The table that contains the function
]]
function Ad:setup_safety_platforms()
  local SafetyPlatformsFolder = workspace:FindFirstChild("SafetyPlatforms")
  if not SafetyPlatformsFolder then
    SafetyPlatformsFolder = Instance.new("Folder")
    SafetyPlatformsFolder.Name = "SafetyPlatforms"
    SafetyPlatformsFolder.Parent = workspace
  end

  local PlatformSize = Vector3.new(250, 4, 250) 
  local PlatformColor = Color3.fromRGB(120, 130, 140) 
  local PlatformMaterial = Enum.Material.Concrete

  local function CreatePlatformIfMissing(Name, TargetPosition)
    if not TargetPosition then
      Log(string.format("SetupSafetyPlatforms: Cannot create platform '%s' because TargetPosition is nil.", tostring(Name)), true)
      return
    end

    local ExistingPlatform = SafetyPlatformsFolder:FindFirstChild(Name)
    if ExistingPlatform and ExistingPlatform:IsA("Part") then
      return 
    elseif ExistingPlatform then
      ExistingPlatform:Destroy() 
    end

    local Platform = Instance.new("Part")
    Platform.Name = Name
    Platform.Size = PlatformSize
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Color = PlatformColor
    Platform.Material = PlatformMaterial
    Platform.TopSurface = Enum.SurfaceType.Smooth
    Platform.BottomSurface = Enum.SurfaceType.Smooth
    -- Center the platform at TargetPosition, with the top surface at TargetPosition.Y
    Platform.Position = Vector3.new(TargetPosition.X, TargetPosition.Y - (PlatformSize.Y / 2), TargetPosition.Z)
    Platform.Parent = SafetyPlatformsFolder
    Log(string.format("SetupSafetyPlatforms: Created platform '%s'. Target Position: %s, Platform Position: %s", Name, tostring(TargetPosition), tostring(Platform.Position)))
  end

  local ParkStaticMap = workspace:FindFirstChild("StaticMap")
  if ParkStaticMap then
    local ParkTarget = ParkStaticMap:FindFirstChild("Park")
    if ParkTarget and ParkTarget:FindFirstChild("BoredAilmentTarget") and ParkTarget.BoredAilmentTarget:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Park", ParkTarget.BoredAilmentTarget.Position)
    else
      Log("SetupSafetyPlatforms: Could not find StaticMap.Park.BoredAilmentTarget Position or it's not a BasePart.", true)
    end
    local BeachTarget = ParkStaticMap:FindFirstChild("Beach")
    if BeachTarget and BeachTarget:FindFirstChild("BeachPartyAilmentTarget") and BeachTarget.BeachPartyAilmentTarget:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Beach", BeachTarget.BeachPartyAilmentTarget.Position)
    else
      Log("SetupSafetyPlatforms: Could not find StaticMap.Beach.BeachPartyAilmentTarget Position or it's not a BasePart.", true)
    end
    local CampsiteTarget = ParkStaticMap:FindFirstChild("Campsite")
    if CampsiteTarget and CampsiteTarget:FindFirstChild("CampsiteOrigin") and CampsiteTarget.CampsiteOrigin:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Campsite", CampsiteTarget.CampsiteOrigin.Position)
    else
      Log("SetupSafetyPlatforms: Could not find StaticMap.Campsite.CampsiteOrigin Position or it's not a BasePart.", true)
    end
  else
    Log("SetupSafetyPlatforms: Could not find StaticMap.", true)
  end

  if not (LocalPlayer and LocalPlayer.Name) then
    Log("SetupSafetyPlatforms: LocalPlayer or LocalPlayer.Name not available for Home platform.", true)
    return
  end

  local HouseInteriors = workspace:FindFirstChild("HouseInteriors")
  if not HouseInteriors then
    Log("SetupSafetyPlatforms: Could not find HouseInteriors folder.", true)
    return
  end

  local BlueprintFolder = HouseInteriors:FindFirstChild("blueprint")
  if not BlueprintFolder then
    Log("SetupSafetyPlatforms: Could not find HouseInteriors.blueprint folder.", true)
    return
  end

  local PlayerHouseBlueprint = BlueprintFolder:FindFirstChild(LocalPlayer.Name)
  if not PlayerHouseBlueprint then
    Log(string.format("SetupSafetyPlatforms: Could not find PlayerHouseBlueprint for player: %s", tostring(LocalPlayer.Name)), true)
    return
  end

  local FloorsFolder = PlayerHouseBlueprint:FindFirstChild("Floors")
  if not FloorsFolder then
    Log(string.format("SetupSafetyPlatforms: Could not find FloorsFolder for player: %s", tostring(LocalPlayer.Name)), true)
    return
  end

  local FloorParts = FloorsFolder:GetChildren()
  if #FloorParts == 0 or not FloorParts[1]:IsA("BasePart") then
    Log(string.format("SetupSafetyPlatforms: Could not find suitable floor part for player: %s", tostring(LocalPlayer.Name)), true)
    return
  end

  local MainFloorPart = FloorParts[1]
  local HomeFloorTopPosition = MainFloorPart.Position + Vector3.new(0, MainFloorPart.Size.Y / 2, 0)
  CreatePlatformIfMissing("SafetyPlatform_Home_" .. LocalPlayer.Name, HomeFloorTopPosition)
end

local IgnoreGoHome = false
--[[
  Teleports the local player to their home by subscribing to their house and setting their location.
  @return boolean -- true if the process was initiated, false if failed
]]
function Ad:go_home()
  Log("Ad:go_home() Attempting to go home")
  local Success, ErrorMessage = pcall(function()
    Ad.__api.pet.exit_furniture_use_states()
    Ad.__api.housing.subscribe_to_house(LocalPlayer)
    Ad.__api.location.set_location("housing", LocalPlayer)
    Ad.__api.housing.push_furniture_changes({})
  end)
  if (not Success) then
    Log(string.format("Ad:go_home() Error: %s", ErrorMessage or "Unknown error"), true)
    return false
  end
  Log("Ad:go_home() Successfully went home")
  return true
end

function Ad:teleport_to_main_map()
  Ad.__api.location.set_location("MainMap", nil, "Default")
end

--[[
  Retrieves smart furniture for a given ailment, optionally purchasing if not found and/or falling back to any matching furniture.
  @param AilmentName string -- The name of the ailment (e.g., "toilet")
  @param PurchaseIfNotFound boolean -- If true, will attempt to purchase smart furniture if not found
  @param FallbackToAnyFurniture boolean -- If true, will fall back to any matching furniture if smart is not found
  @return table? -- The furniture object if found, or nil

  Example:
  ```lua
  local FurnitureItem = Ad:retrieve_smart_furniture("toilet", true, true)
  ```
]]
function Ad:retrieve_smart_furniture(AilmentName, PurchaseIfNotFound, FallbackToAnyFurniture)
  if not AilmentName or type(AilmentName) ~= "string" then
    Log("retrieve_smart_furniture: Invalid AilmentName argument.", true)
    return nil
  end

  local FurnitureItem = self.SmartFurnitureMap[AilmentName]
  if not FurnitureItem and PurchaseIfNotFound then
    self:initialize_smart_furniture()
    FurnitureItem = self.SmartFurnitureMap[AilmentName]
  end
  if not FurnitureItem and FallbackToAnyFurniture then
    Log(string.format("retrieve_smart_furniture: SmartFurnitureMap does NOT have '%s' entry. Trying find_first_ailment_furniture.", AilmentName), true)
    FurnitureItem = self:find_first_ailment_furniture(AilmentName)
  end
  return FurnitureItem
end

return Ad
