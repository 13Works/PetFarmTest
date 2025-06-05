--!strict
--/PetFarmOfficial.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local API = ReplicatedStorage:WaitForChild("API")
local Fsys = ReplicatedStorage:FindFirstChild("Fsys")
local SharedConstants = require(ReplicatedStorage["ClientDB"]["SharedConstants"])
local ClientData = require(ReplicatedStorage["ClientModules"]["Core"]["ClientData"])

-- Dehash the API
table.foreach(getupvalue(require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init, 7), function(RemoteName, Hashedremote)
  if typeof(Hashedremote) ~= "Instance" then return end
  if Hashedremote.Parent ~= API then return end
  if not (Hashedremote:IsA("RemoteEvent") or Hashedremote:IsA("RemoteFunction")) then return end
  Hashedremote.Name = RemoteName
end)

local TaskPlanner = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/TaskPlanner.lua?token=GHSAT0AAAAAADD7DUXO7CE6XP4Y42FDBXXA2CBJBEA"), true))()
local PlanFormatter = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/PlanFormatter.lua?token=GHSAT0AAAAAADD7DUXPNZPH4HSMNYXJHEW22CBJCCA"), true))()

local LocalPlayer = Players.LocalPlayer

local EquippedPetsModule = nil
if (Fsys) then
  local LoadSuccess, Module = pcall(function()
    return require(Fsys).load("EquippedPets")
  end)
  if (LoadSuccess and Module) then
    EquippedPetsModule = Module
    print("EquippedPets module loaded successfully.")
  else
    warn("Failed to load EquippedPets module:", Module)
  end
else
  warn("Fsys module loader not found in ReplicatedStorage. EquippedPets module cannot be loaded.")
end

local SmartFurnitureMap = {} -- Renamed to PascalCase as it's mutable state

local AILMENT_TO_FURNITURE_MODEL_MAP = {
  ["thirsty"] = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" };
  ["hungry"] = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" };
  ["toilet"] = { "AilmentsRefresh2024LitterBox", "ailments_refresh_2024_litter_box" };
  ["dirty"] = { "ModernShower", "modernshower" };
  ["sleepy"] = { "BasicCrib", "basiccrib" };
}

local function GetPlayerOwnedToys()
  return ClientData.get_data()[LocalPlayer["Name"]]["inventory"]["toys"]
end

local function FindFirstThrowableToyInList(OwnedToysTable)
  if (typeof(OwnedToysTable) ~= "table") then return nil end
  for _, ToyItem in OwnedToysTable do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization
    if (ToyItem and ToyItem["IsThrowable"]) then
      return ToyItem
    end
  end
  return nil
end

local function GetPetUniqueIdString(PetModel)
  if (not PetModel) then
    warn("GetPetUniqueIdString: Called with a nil PetModel.")
    return "stub_pet_unique_id_error"
  end

  if (EquippedPetsModule) then
    local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
    if (EquippedWrappers) then
      for _, Wrapper in EquippedWrappers do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization
        if (Wrapper["char"] == PetModel) then
          if (Wrapper["pet_unique"] and typeof(Wrapper["pet_unique"]) == "string") then
            return Wrapper["pet_unique"]
          else
            warn(string.format("GetPetUniqueIdString: PetModel '%s' found in EquippedPetsModule, but its 'pet_unique' property is missing or not a string. Trying other methods.", PetModel["Name"] or "Unnamed"))
          end
        end
      end
    else
      warn("GetPetUniqueIdString: EquippedPetsModule.get_my_equipped_char_wrappers() returned nil or an empty list. Cannot check module for ID.")
    end
  end

  if (PetModel["unique"] and typeof(PetModel["unique"]) == "string") then
    return PetModel["unique"]
  end

  if (PetModel["Name"] and typeof(PetModel["Name"]) == "string") then
    warn(string.format("GetPetUniqueIdString: Using PetModel.Name ('%s') as fallback for unique ID. This may not be the correct format for API calls.", PetModel["Name"]))
    return PetModel["Name"]
  end

  local PetIdentifierDescription = "an unknown PetModel instance"
  if (PetModel["Name"] and typeof(PetModel["Name"]) == "string") then
    PetIdentifierDescription = string.format("PetModel named '%s'", PetModel["Name"])
  elseif (typeof(PetModel) == "Instance") then
    PetIdentifierDescription = string.format("PetModel instance '%s'", PetModel:GetFullName())
  elseif (PetModel) then
    PetIdentifierDescription = string.format("PetModel (type: %s, tostring: %s)", typeof(PetModel), tostring(PetModel))
  end

  warn(string.format("GetPetUniqueIdString: Could not determine a string unique ID for %s using any available method.", PetIdentifierDescription))
  return "stub_pet_unique_id_error"
end

local function IsToyEquippedByPlayer(ToyItemToVerify)
  warn("IsToyEquippedByPlayer: STUB returning TRUE. Implement actual check against ClientData.equip_manager.inventory.toys for toy '" .. (ToyItemToVerify and ToyItemToVerify["Name"] or "nil") .. "'.")
  return true
end
-- [[ END OF STUB FUNCTIONS ]] --

local AILMENT_KEYWORDS_MAP = {
  ["dirty"] = {"shower", "bath", "tub"};
  ["sleepy"] = {"bed", "crib", "cot", "hammock"};
  ["toilet"] = {"toilet", "litter box", "potty"}; -- Using "litter box" to match common pet item phrasing
}

local function GetFurnitureUniqueIdFromModel(ActualFurnitureModel, FunctionContextName, ParentContainerForContext) -- Added FunctionContextName
  if not ActualFurnitureModel then
    warn(string.format("%s: Called GetFurnitureUniqueIdFromModel with a nil ActualFurnitureModel.", FunctionContextName))
    return nil, nil
  end

  local FurnitureUniqueId = nil
  local IdSource = nil
  local ContainerNameForWarning = (ParentContainerForContext and ParentContainerForContext["Name"]) or "UnknownContainer"

  FurnitureUniqueId = ActualFurnitureModel:GetAttribute("furniture_unique")
  if (FurnitureUniqueId and typeof(FurnitureUniqueId) == "string") then
    IdSource = "attribute (furniture_unique on model)"
  else
    warn(string.format("%s: Model '%s' in container '%s' is missing 'furniture_unique' string attribute. Falling back to model name.", FunctionContextName, ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarning))
    FurnitureUniqueId = ActualFurnitureModel["Name"]
    if (typeof(FurnitureUniqueId) == "string") then
      IdSource = "model_name (fallback)"
    else
      warn(string.format("%s: Model '%s' in container '%s' also has an invalid non-string model name. Cannot derive ID.", FunctionContextName, ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarning))
      FurnitureUniqueId = nil
      IdSource = nil
    end
  end
  return FurnitureUniqueId, IdSource
end

local function GetVacantSeatFromModel(FurnitureModel)
  if not FurnitureModel then
    -- This warning might be too noisy if called speculatively. Consider if needed.
    -- warn("GetVacantSeatFromModel: Called with a nil FurnitureModel.") 
    return nil
  end
  local UseBlocks = FurnitureModel:FindFirstChild("UseBlocks")
  if UseBlocks then
    local Seats = UseBlocks:GetChildren()
    if #Seats > 0 then
      return Seats[1] -- Return the first seat found
    end
  end
  return nil -- No UseBlocks or no seats in UseBlocks
end

local function FindFirstAilmentFurniture(AilmentName)
  local Keywords = AILMENT_KEYWORDS_MAP[AilmentName]
  if not Keywords then
    warn("FindFirstAilmentFurniture: No keywords defined for ailment: " .. AilmentName)
    return nil
  end

  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if not FurnitureFolder then
    warn("FindFirstAilmentFurniture: workspace.HouseInteriors.furniture not found.")
    return nil
  end

  for _, ContainerFolderInstance in FurnitureFolder:GetChildren() do
    if ContainerFolderInstance:IsA("Folder") or ContainerFolderInstance:IsA("Model") then
      for _, ActualFurnitureModel in ContainerFolderInstance:GetChildren() do
        if ActualFurnitureModel:IsA("Model") or ActualFurnitureModel:IsA("BasePart") then
          local FurnitureUniqueId, IdSource = GetFurnitureUniqueIdFromModel(ActualFurnitureModel, "FindFirstAilmentFurniture", ContainerFolderInstance)

          if FurnitureUniqueId then
            local LowercaseActualModelName = string.lower(ActualFurnitureModel["Name"])
            for _, Keyword in Keywords do
              if string.find(LowercaseActualModelName, string.lower(Keyword)) then
                local VacantSeatInstance = GetVacantSeatFromModel(ActualFurnitureModel)

                warn(string.format("FindFirstAilmentFurniture: Found generic furniture. UniqueID: '%s' (source: %s), ModelName (actual): '%s', Container: '%s', For Ailment: '%s', Keyword: '%s', VacantSeat: %s",
                  FurnitureUniqueId, IdSource, ActualFurnitureModel["Name"], ContainerFolderInstance["Name"], AilmentName, Keyword, VacantSeatInstance and VacantSeatInstance["Name"] or "nil"))

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

  warn("FindFirstAilmentFurniture: No suitable owned furniture found for ailment: " .. AilmentName .. " (matching keywords, with a valid unique ID from model attribute or model name, and correct model structure).")
  return nil
end

-- Updated VerifyAilmentExists function
function VerifyAilmentExists(PetModel, AilmentName)
  if (not PetModel) then
    warn("VerifyAilmentExists: PetModel is nil.")
    return false
  end
  if (not AilmentName) then
    warn("VerifyAilmentExists: AilmentName is nil.")
    return false
  end

  local PetUniqueId = GetPetUniqueIdString(PetModel)
  if (not PetUniqueId or PetUniqueId == "stub_pet_unique_id_error") then
    warn("VerifyAilmentExists: Could not get a valid Unique ID for PetModel: " .. PetModel["Name"] .. ". Cannot verify ailment.")
    return false
  end

  local PlayerData = ClientData.get_data()[LocalPlayer["Name"]]

  if (not PlayerData or not PlayerData["ailments_manager"] or not PlayerData["ailments_manager"]["ailments"]) then
    warn("VerifyAilmentExists: Could not find ailment data path for LocalPlayer ('" .. LocalPlayer["Name"] .. "') in ClientData.")
    return false
  end

  local AllPetsAilmentInfo = PlayerData["ailments_manager"]["ailments"]
  local PetSpecificAilmentsInfo = AllPetsAilmentInfo[PetUniqueId]

  if (PetSpecificAilmentsInfo and typeof(PetSpecificAilmentsInfo) == "table") then
    for _, AilmentDataEntry in PetSpecificAilmentsInfo do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization
      if (typeof(AilmentDataEntry) == "table" and AilmentDataEntry["kind"] == AilmentName) then
        print(string.format("VerifyAilmentExists: Ailment '%s' FOUND for pet '%s'.", AilmentName, PetUniqueId))
        return true
      end
    end
  end

  print(string.format("VerifyAilmentExists: Ailment '%s' NOT FOUND for pet '%s'.", AilmentName, PetUniqueId))
  return false
end

-- Find the first piece of furniture that a pet can sit on
function FindFirstSitable(PetModel)
  return nil
end

local function GetSmartFurniture()
  local FoundItems = {}
  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if (not FurnitureFolder) then
    warn("GetSmartFurniture: workspace.HouseInteriors.furniture not found!")
    return FoundItems
  end

  for Ailment, FurnitureData in AILMENT_TO_FURNITURE_MODEL_MAP do
    local ModelNameKey = FurnitureData[1]
    local ActualFurnitureModel = FurnitureFolder:FindFirstChild(ModelNameKey, true)

    if (ActualFurnitureModel) then
      local ParentContainer = ActualFurnitureModel["Parent"]
      
      if not (ParentContainer and ParentContainer["Parent"] == FurnitureFolder) then
        local ContainerNameForContext = ParentContainer and ParentContainer["Name"] or "N/A (Parent not found or no name)"
        warn(string.format("GetSmartFurniture: Smart furniture model '%s' (searched as '%s') found, but its parent ('%s') is not a direct container in FurnitureFolder. Skipping for ailment '%s'.", ActualFurnitureModel["Name"], ModelNameKey, ContainerNameForContext, Ailment))
      else
        local FurnitureUniqueId, IdSource = GetFurnitureUniqueIdFromModel(ActualFurnitureModel, "GetSmartFurniture", ParentContainer)

        if (FurnitureUniqueId) then
          local VacantSeatInstance = GetVacantSeatFromModel(ActualFurnitureModel)
          
          FoundItems[Ailment] = {
            ["name"] = FurnitureUniqueId;
            ["model"] = ActualFurnitureModel;
            ["vacant_seat"] = VacantSeatInstance;
          }
          print(string.format("GetSmartFurniture: Found/processed smart furniture. UniqueID: '%s' (source: %s), Model: '%s'. For ailment '%s'. Searched for: %s", FurnitureUniqueId, IdSource, ActualFurnitureModel["Name"], Ailment, ModelNameKey))
        else
          local ContainerNameForWarn = ParentContainer and ParentContainer["Name"] or "UnknownContainer"
          warn(string.format("GetSmartFurniture: Could not derive Unique ID for smart model '%s' (container: '%s') for ailment '%s'. It will not be registered as smart furniture.", ActualFurnitureModel["Name"] or "UnnamedModel", ContainerNameForWarn, Ailment))
        end
      end
    end
  end
  return FoundItems
end

local function InitializeSmartFurniture()
  local ClientDataModule = require(ReplicatedStorage["ClientModules"]["Core"]["ClientData"])
  local FurnitureDB = require(ReplicatedStorage["ClientDB"]["Housing"]["FurnitureDB"])
  local PlayerData = ClientDataModule.get_data()[LocalPlayer["Name"]]
  local CurrentMoney = nil
  if (PlayerData and PlayerData["money"]) then
    CurrentMoney = PlayerData["money"]
  else
    warn("InitializeSmartFurniture: Could not retrieve player money from ClientData. Cannot perform cost checks.")
  end
  if (not FurnitureDB) then
    warn("InitializeSmartFurniture: FurnitureDB module not found or failed to load. Cannot perform cost checks or determine item costs.")
  end
  local CurrentSmartFurnitureItems = GetSmartFurniture()
  local FurnitureFolder = workspace["HouseInteriors"] and workspace["HouseInteriors"]:FindFirstChild("furniture")
  if (not FurnitureFolder) then
    warn("InitializeSmartFurniture: workspace.HouseInteriors.furniture not found! Cannot process smart furniture.")
    SmartFurnitureMap = CurrentSmartFurnitureItems
    return
  end
  local ItemsToBuy = {}
  local ItemKindsToModelNames = {}
  for Ailment, FurnitureData in AILMENT_TO_FURNITURE_MODEL_MAP do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization
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
            warn(string.format("InitializeSmartFurniture: Cannot afford '%s' (model: %s) for ailment '%s'. Cost: %d, Player Money: %d.", KindName, ModelName, Ailment, Cost, CurrentMoney))
          end
        else
          warn(string.format("InitializeSmartFurniture: Could not find cost information for '%s' (model: %s) in FurnitureDB. Assuming it's free or data is missing.", KindName, ModelName))
        end
      elseif (CurrentMoney == nil and FurnitureDB and FurnitureDB[KindName] and FurnitureDB[KindName]["cost"] and FurnitureDB[KindName]["cost"] > 0) then
        warn(string.format("InitializeSmartFurniture: Player money not available, but '%s' (model: %s) has a cost in DB. Purchase might fail.", KindName, ModelName))
      end
      if (CanAfford) then
        table.insert(ItemsToBuy, { ["kind"] = KindName; ["properties"] = { cframe = CFrame.new(0, -1000, 0) }; })
        ItemKindsToModelNames[KindName] = ModelName
        warn(string.format("InitializeSmartFurniture: Queuing purchase for '%s' (model: %s, cost: %d) for ailment '%s'. Player Money: %s", KindName, ModelName, Cost, Ailment, CurrentMoney or 'Unknown'))
      end
    end
  end
  if (#ItemsToBuy > 0) then
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage to avoid conflict with error() global
      API["HousingAPI/BuyFurnitures"]:InvokeServer(ItemsToBuy)
    end)
    if (not Success) then
      warn(string.format("InitializeSmartFurniture: Error purchasing furniture: %s", tostring(ErrorMessage)))
      SmartFurnitureMap = CurrentSmartFurnitureItems
      return
    end
    task.wait()
    -- API["HousingAPI/PushFurnitureChanges"]:FireServer({})
    task.wait()
    for _, BoughtItemInfo in ItemsToBuy do -- This is an array, so generic loop is fine STYLE_GUIDE.md > Performance Guidelines > Loop Optimization
      local ModelNameToFind = ItemKindsToModelNames[BoughtItemInfo["kind"]]
      if (ModelNameToFind) then
        local ActualNewFurnitureModel = FurnitureFolder:FindFirstChild(ModelNameToFind, true)
        if (ActualNewFurnitureModel) then
          local ParentContainer = ActualNewFurnitureModel["Parent"]
          
          if not (ParentContainer and ParentContainer["Parent"] == FurnitureFolder) then
            local ContainerNameForContext = ParentContainer and ParentContainer["Name"] or "N/A (Parent not found or no name)"
            warn(string.format("InitializeSmartFurniture: Found purchased model '%s' (Kind: %s), but its parent structure is unexpected ('%s' is not in FurnitureFolder). Cannot add to smart map.", ActualNewFurnitureModel["Name"] or "UnnamedModel", BoughtItemInfo["kind"], ContainerNameForContext))
          else
            local FurnitureUniqueId, IdSource = GetFurnitureUniqueIdFromModel(ActualNewFurnitureModel, "InitializeSmartFurniture", ParentContainer)

            if (FurnitureUniqueId) then
              local VacantSeatInstance = GetVacantSeatFromModel(ActualNewFurnitureModel)

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
                  warn(string.format("InitializeSmartFurniture: Successfully processed purchased item '%s' (UniqueID from %s: '%s', Container: '%s') for ailment '%s'.", ActualNewFurnitureModel["Name"] or "UnnamedModel", IdSource or "N/A", FurnitureUniqueId, ContainerNameForLog, AilmentInner))
                  break
                end
              end
            else
              local ContainerNameForWarn = ParentContainer and ParentContainer["Name"] or "UnknownContainer"
              warn(string.format("InitializeSmartFurniture: Could not derive a Unique ID for purchased model '%s' (Kind: %s, Container: '%s') after attribute/name check. Cannot add to smart map.", ActualNewFurnitureModel["Name"] or "UnnamedModel", BoughtItemInfo["kind"], ContainerNameForWarn))
            end
          end
        else
          warn(string.format("InitializeSmartFurniture: Failed to find purchased item model '%s' (kind: %s) recursively in workspace after buying.", ModelNameToFind, BoughtItemInfo["kind"]))
        end
      end
    end
  end
  SmartFurnitureMap = CurrentSmartFurnitureItems
end

--[[
  Teleports the player to a specific ailment location or sets their CFrame directly for certain locations.
  @param Location string -- The location name (e.g., "beach", "park", "camping")
]]
function TeleportToAilmentLocation(Location)
  local MainLocationMap = {
    ["beach"] = workspace["StaticMap"]["Beach"]["BeachPartyAilmentTarget"]["CFrame"];
    ["park"] = workspace["StaticMap"]["Park"]["BoredAilmentTarget"]["CFrame"];
    ["camping"] = workspace["StaticMap"]["Campsite"]["CampsiteOrigin"]["CFrame"];
  }

  local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
    if (MainLocationMap[Location]) then
      API["LocationAPI/SetLocation"]:FireServer("MainMap", _, "Default")
      task.wait()
      LocalPlayer["Character"]["HumanoidRootPart"]["CFrame"] = MainLocationMap[Location] * CFrame.new(0, 5, 0)
    else
      API["LocationAPI/SetLocation"]:FireServer(Location)
    end
  end)

  if (not Success) then
    warn(string.format("Error teleporting to %s: %s", Location, ErrorMessage or "Unknown error"))
  end
end

--[[
  Places and uses a sitable furniture object at a given CFrame for a pet.
  @param SitableFurnitureObject table -- The furniture object to use
  @param TargetCFrame CFrame -- The CFrame to place the furniture at
  @param PetModel Instance -- The pet model to use the furniture
]]
function PlaceAndUseSitableAtCFrame(SitableFurnitureObject, TargetCFrame, PetModel)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not TargetCFrame) then
    warn(string.format("PlaceAndUseSitableAtCFrame: Invalid arguments. SitableFurnitureObject: %s, TargetCFrame: %s", tostring(SitableFurnitureObject), tostring(TargetCFrame)))
    return
  end

  task.wait()

  local SeatToUse = "UseBlock"
  if (SitableFurnitureObject["vacant_seat"] and SitableFurnitureObject["vacant_seat"]["Name"]) then
    SeatToUse = SitableFurnitureObject["vacant_seat"]["Name"]
  end

  API["HousingAPI/ActivateFurniture"]:InvokeServer(
    LocalPlayer,
    SitableFurnitureObject["name"],
    SeatToUse,
    { ["cframe"] = TargetCFrame },
    PetModel
  )
end

--[[
  Uses a sitable furniture object at the player's character CFrame for a pet.
  @param SitableFurnitureObject table -- The furniture object to use
  @param PetModel Instance -- The pet model to use the furniture
]]
function UseSitableAtCharacterCFrame(SitableFurnitureObject, PetModel)
  if (not SitableFurnitureObject or not SitableFurnitureObject["name"] or not SitableFurnitureObject["model"] or not PetModel) then
    warn(string.format("UseSitableAtCharacterCFrame: Invalid arguments. SitableFurnitureObject: %s, PetModel: %s", tostring(SitableFurnitureObject), tostring(PetModel)))
    return
  end

  if (not LocalPlayer["Character"] or not LocalPlayer["Character"]:FindFirstChild("HumanoidRootPart")) then
    warn("UseSitableAtCharacterCFrame: LocalPlayer.Character.HumanoidRootPart not found. Cannot determine target CFrame.")
    return
  end
  local TargetCFrame = LocalPlayer["Character"]["HumanoidRootPart"]["CFrame"]

  local SeatToUse = "UseBlock"
  if (SitableFurnitureObject["vacant_seat"] and SitableFurnitureObject["vacant_seat"]["Name"]) then
    SeatToUse = SitableFurnitureObject["vacant_seat"]["Name"]
  end

  warn(string.format("UseSitableAtCharacterCFrame: Activating furniture '%s' (Seat: '%s') at player CFrame for Pet: '%s'", SitableFurnitureObject["name"], SeatToUse, PetModel["Name"]))

  API["HousingAPI/ActivateFurniture"]:InvokeServer(
    LocalPlayer,
    SitableFurnitureObject["name"],
    SeatToUse,
    { ["cframe"] = TargetCFrame },
    PetModel
  )
end

local function HandleSmartOrTeleportAilment(AilmentTargetCFrame, LocationName, PetModel, AilmentName)
  local FurnitureToUse = nil
  if (next(SmartFurnitureMap) == nil) then
    InitializeSmartFurniture()
  end

  FurnitureToUse = SmartFurnitureMap[AilmentName]

  if (not FurnitureToUse) then
    FurnitureToUse = FindFirstAilmentFurniture(AilmentName)
  end

  if (FurnitureToUse) then
    PlaceAndUseSitableAtCFrame(FurnitureToUse, AilmentTargetCFrame, PetModel)
    return
  end

  TeleportToAilmentLocation(LocationName)
end

--[[
  Feeds a pet with a given food item.
  @param FoodName string -- The name of the food item to feed the pet
]]
function FeedPet(FoodName)
  API["ShopAPI/BuyItem"]:InvokeServer("food", FoodName, {})
	local Inventory = ClientData.get_data()[LocalPlayer["Name"]]["inventory"]
	local Success = false

	for Unique, Info in Inventory.food do
		if Info.kind == FoodName then
			API["PetAPI/CreatePetObject"]:InvokeServer("__Enum_PetObjectCreatorType_2", {["unique_id"] = Unique})
			API["PetAPI/ConsumeFoodObject"]:FireServer(Unique); Success = true
			break
		end
	end

	if not Success then
		warn("Error feeding pet. Skipping task.")
	end
end

local AilmentActions = {
  ["bored"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "bored") then return end
      local AilmentTargetCFrame = workspace["StaticMap"]["Park"]["BoredAilmentTarget"]["CFrame"]
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "park", PetModel, "bored")

      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "bored", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.bored: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "bored", GetPetUniqueIdString(PetModel)))
        end
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'bored' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;
  ["beach_party"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "beach_party") then return end 
      local AilmentTargetCFrame = workspace["StaticMap"]["Beach"]["BeachPartyAilmentTarget"]["CFrame"]
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "beach", PetModel, "beach_party") 

      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "beach_party", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.beach: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "beach_party", GetPetUniqueIdString(PetModel)))
        end
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'beach' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;
  ["camping"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "camping") then return end
      local AilmentTargetCFrame = workspace["StaticMap"]["Campsite"]["CampsiteOrigin"]["CFrame"]
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "campsite", PetModel, "camping")

      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "camping", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.camping: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "camping", GetPetUniqueIdString(PetModel)))
        end
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'camping' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["hungry"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "hungry") then return end

        FeedPet("teachers_apple")

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "hungry", 25) -- 25s timeout (SharedConstants.full_food_bowl_drink_duration is ~16s)
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Standard: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "hungry", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("Error executing 'hungry.Standard' ailment: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "hungry") then return end
        if next(SmartFurnitureMap) == nil then
          InitializeSmartFurniture()
        end
        local Bowl = SmartFurnitureMap["hungry"]
        if Bowl then
          PlaceAndUseSitableAtCFrame(Bowl, TargetCFrame, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.hungry.Smart: Smart food bowl not available. Consider falling back to Standard or checking configuration.")
        end
        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "hungry", 25) -- 25s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Smart: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "hungry", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("Error executing 'hungry.Smart' ailment: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["thirsty"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "thirsty") then return end
        
        FeedPet("water")

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "thirsty", 25) -- 25s timeout (SharedConstants.full_water_bowl_drink_duration is ~16s)
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Standard: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "thirsty", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("Error executing 'thirsty.Standard' ailment: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "thirsty") then return end
        if next(SmartFurnitureMap) == nil then
          InitializeSmartFurniture()
        end
        local Bowl = SmartFurnitureMap["thirsty"]
        if Bowl then
          PlaceAndUseSitableAtCFrame(Bowl, TargetCFrame, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.thirsty.Smart: Smart water bowl not available. Consider falling back to Standard or checking configuration.")
        end
        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "thirsty", 25) -- 25s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Smart: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "thirsty", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("Error executing 'thirsty.Smart' ailment: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["sick"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "sick") then return end
      API["LocationAPI/SetLocation"]:FireServer("Hospital")
      task.wait(1) -- Allow time for teleport

      local HealingSpotCFrame = nil
      local HealingFurnitureName = "f-14" 

      if workspace["StaticMap"] and 
        workspace["StaticMap"]["Hospital"] and 
        workspace["StaticMap"]["Hospital"]:FindFirstChild("SickAilmentTarget") and 
        workspace["StaticMap"]["Hospital"]["SickAilmentTarget"]:IsA("BasePart") then 
        HealingSpotCFrame = workspace["StaticMap"]["Hospital"]["SickAilmentTarget"]["CFrame"]
      else
        warn(string.format("PetFarmOfficial.AilmentActions.sick: Could not find predefined SickAilmentTarget CFrame in workspace.StaticMap.Hospital. The interaction might fail or use a default/incorrect CFrame if not explicitly set for \"%s\".", HealingFurnitureName))
        HealingSpotCFrame = CFrame.new() 
      end

      API["HousingAPI/ActivateFurniture"]:InvokeServer(
        LocalPlayer,
        HealingFurnitureName, 
        "UseBlock",             
        { ["cframe"] = HealingSpotCFrame },
        PetModel                
      )

      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "sick", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.sick: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "sick", GetPetUniqueIdString(PetModel)))
        end
      end
    end)

    if not Success then
      warn(string.format("PetFarmOfficial.AilmentActions.sick: Error executing 'sick' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["salon"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "salon") then return end
      TeleportToAilmentLocation("Salon")
      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "salon", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.salon: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "salon", GetPetUniqueIdString(PetModel)))
        end
      end
    end)
    if not Success then
      warn(string.format("Error executing 'salon' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["school"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "school") then return end
      TeleportToAilmentLocation("School")
      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "school", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.school: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "school", GetPetUniqueIdString(PetModel)))
        end
      end
    end)
    if not Success then
      warn(string.format("Error executing 'school' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["pizza_party"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "pizza_party") then return end
      TeleportToAilmentLocation("PizzaShop") 
      if WaitForCompletion then
        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "pizza_party", 30) -- 30s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.pizza_party: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "pizza_party", GetPetUniqueIdString(PetModel)))
        end
      end
    end)
    if not Success then
      warn(string.format("Error executing 'pizza_party' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["sleepy"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "sleepy") then return end

        local FurnitureItem = SmartFurnitureMap["sleepy"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.sleepy.Standard: SmartFurnitureMap does NOT have 'sleepy' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("sleepy")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          UseSitableAtCharacterCFrame(FurnitureItem, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.sleepy.Standard: No suitable smart or generic owned crib/bed found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "sleepy", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "sleepy", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "sleepy") then return end

        local FurnitureItem = SmartFurnitureMap["sleepy"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.sleepy.Smart: SmartFurnitureMap does NOT have 'sleepy' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("sleepy")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.sleepy.Smart: No suitable smart or generic owned crib/bed found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "sleepy", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "sleepy", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["dirty"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "dirty") then return end

        local FurnitureItem = SmartFurnitureMap["dirty"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.dirty.Standard: SmartFurnitureMap does NOT have 'dirty' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("dirty")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          UseSitableAtCharacterCFrame(FurnitureItem, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.dirty.Standard: No suitable smart or generic owned shower/bath found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "dirty", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "dirty", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "dirty") then return end

        local FurnitureItem = SmartFurnitureMap["dirty"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.dirty.Smart: SmartFurnitureMap does NOT have 'dirty' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("dirty")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.dirty.Smart: No suitable smart or generic owned shower/bath found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "dirty", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "dirty", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["play"] = function(PetModel, WaitForCompletion)
    local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
      if not VerifyAilmentExists(PetModel, "play") then return end

      local OwnedToys = GetPlayerOwnedToys()
      local ThrowableToy = FindFirstThrowableToyInList(OwnedToys)

      if not ThrowableToy then
        warn("PetFarmOfficial.AilmentActions.play: No throwable toy found in player inventory. Cannot perform 'play' action.")
        return
      end

      warn(string.format("PetFarmOfficial.AilmentActions.play: Player must have toy '%s' (UniqueId: %s) equipped for the 'play' action to proceed correctly. This is an assumed prerequisite state.", ThrowableToy["Name"], ThrowableToy["UniqueId"]))

      local PetUniqueId = GetPetUniqueIdString(PetModel)
      if PetUniqueId == "stub_pet_unique_id_error" then
        warn("PetFarmOfficial.AilmentActions.play: Could not get a valid unique ID for the pet. Aborting 'play' action.")
        return
      end

      API["PetObjectAPI/CreatePetObject"]:InvokeServer("_Enum_PetObjectCreatorType_1", {
        ["reaction_name"] = "ThrowToyReaction",
        ["unique_id"] = PetUniqueId
      })

      if WaitForCompletion then
        warn("PetFarmOfficial.AilmentActions.play: Waiting for 'play' ailment to clear. For full completion, also ensure IsToyEquippedByPlayer("..tostring(ThrowableToy and ThrowableToy["Name"])..") is implemented and added to the wait condition.")

        local ExtraCondition = function()
          return IsToyEquippedByPlayer(ThrowableToy) 
        end

        local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "play", 20, ExtraCondition) -- 20s timeout
        if not Cleared then
          warn(string.format("PetFarmOfficial.AilmentActions.play: Ailment '%s' for pet '%s' (or extra condition) did NOT clear/meet within the timeout.", "play", GetPetUniqueIdString(PetModel)))
        end
      end
    end)
    if not Success then
      warn(string.format("Error executing 'play' ailment: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["toilet"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "toilet") then return end

        local FurnitureItem = SmartFurnitureMap["toilet"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.toilet.Standard: SmartFurnitureMap does NOT have 'toilet' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("toilet")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          UseSitableAtCharacterCFrame(FurnitureItem, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.toilet.Standard: No suitable smart or generic owned toilet/litter box found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "toilet", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "toilet", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, ErrorMessage = pcall(function() -- Renamed Error to ErrorMessage
        if not VerifyAilmentExists(PetModel, "toilet") then return end

        local FurnitureItem = SmartFurnitureMap["toilet"]
        if not FurnitureItem then
          warn("PetFarmOfficial.AilmentActions.toilet.Smart: SmartFurnitureMap does NOT have 'toilet' entry. Trying FindFirstAilmentFurniture.")
          FurnitureItem = FindFirstAilmentFurniture("toilet")
        end

        if FurnitureItem then
          warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
        else
          warn("PetFarmOfficial.AilmentActions.toilet.Smart: No suitable smart or generic owned toilet/litter box found.")
        end

        if WaitForCompletion then
          local Cleared = WaitForAilmentClearanceWithTimeout(PetModel, "toilet", 30) -- 30s timeout
          if not Cleared then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Ailment '%s' for pet '%s' did NOT clear within the timeout.", "toilet", GetPetUniqueIdString(PetModel)))
          end
        end
      end)
      if not Success then
        warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };
}

-- Updated GetCurrentAilments function
local function GetCurrentAilments()
  local ClientDataModule = require(ReplicatedStorage["ClientModules"]["Core"]["ClientData"]) 
  local PlayerData = ClientDataModule.get_data()[LocalPlayer["Name"]]
  local PetAilmentsResult = {}

  if not PlayerData or not PlayerData["ailments_manager"] or not PlayerData["ailments_manager"]["ailments"] then
    warn("GetCurrentAilments: Could not find ailment data for LocalPlayer ('" .. LocalPlayer["Name"] .. "') in ClientData. Structure might be unexpected or data not yet available.")
    return PetAilmentsResult -- Return empty if path is invalid
  end

  -- Iterate through all pets and their ailments
  for PetUnique, AilmentInfo in PlayerData["ailments_manager"]["ailments"] do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaces pairs)
    local CurrentPetSpecificAilments = {}

    -- Extract ailment kinds for this pet
    if type(AilmentInfo) == "table" then
      for AilmentName, AilmentData in AilmentInfo do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaces pairs)
        if type(AilmentData) == "table" and AilmentData["kind"] then
          table.insert(CurrentPetSpecificAilments, AilmentData["kind"])
        end
      end
    end

    -- Add to results if pet has ailments
    if #CurrentPetSpecificAilments > 0 then
      table.insert(PetAilmentsResult, {
        ["unique"] = PetUnique;
        ["ailments"] = CurrentPetSpecificAilments;
      })
    end
  end

  return PetAilmentsResult
end

-- Updated GetPetModelByUniqueId function
local function GetPetModelByUniqueId(PetUniqueIdToFind) 
  if not EquippedPetsModule then
    warn("GetPetModelByUniqueId: EquippedPetsModule is not loaded. Cannot fetch pet model.")
    return nil
  end

  if not PetUniqueIdToFind then
    warn("GetPetModelByUniqueId: PetUniqueIdToFind is nil.")
    return nil
  end

  print(string.format("DEBUG: GetPetModelByUniqueId calling EquippedPetsModule.get_wrapper_from_unique for ID: %s", tostring(PetUniqueIdToFind)))
  local Wrapper = EquippedPetsModule.get_wrapper_from_unique(PetUniqueIdToFind, LocalPlayer) -- Renamed wrapper to Wrapper

  if Wrapper then
    print(string.format("DEBUG: GetPetModelByUniqueId: Wrapper FOUND for ID: %s. Wrapper type: %s", tostring(PetUniqueIdToFind), type(Wrapper)))
    local PetModel = Wrapper["char"]
    if PetModel and PetModel:IsA("Model") then
      return PetModel
    else
      warn("GetPetModelByUniqueId: Wrapper found for " .. PetUniqueIdToFind .. ", but .char (PetModel) is missing or not a Model.")
      return nil
    end
  else
    print(string.format("DEBUG: GetPetModelByUniqueId: Wrapper NOT FOUND for ID: %s", tostring(PetUniqueIdToFind)))
    warn("GetPetModelByUniqueId: No wrapper found for unique ID: " .. PetUniqueIdToFind .. ". Pet might not be equipped or ID is invalid.")
    return nil
  end
end

local function GetMyEquippedPetModels()
  if not EquippedPetsModule then
    warn("GetMyEquippedPetModels: EquippedPetsModule is not loaded. Cannot fetch pet models.")
    return {}
  end

  local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
  local PetModels = {}

  if not EquippedWrappers or #EquippedWrappers == 0 then
    return PetModels
  end

  for _, Wrapper in EquippedWrappers do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaces ipairs)
    local PetModel = Wrapper["char"]
    if PetModel and PetModel:IsA("Model") then
      table.insert(PetModels, PetModel)
    else
      local PetUniqueId = Wrapper["pet_unique"]
      if PetUniqueId then
        warn("GetMyEquippedPetModels: Wrapper found for unique:", PetUniqueId, "- but pet model (char) is missing or invalid.")
      else
        warn("GetMyEquippedPetModels: Wrapper found but pet model (char) is missing/invalid and no unique ID on wrapper.")
      end
    end
  end
  return PetModels
end

local function GetMyEquippedPetUniques()
  if not EquippedPetsModule then
    warn("GetMyEquippedPetUniques: EquippedPetsModule is not loaded. Cannot fetch pet unique IDs.")
    return {}
  end

  print("DEBUG: GetMyEquippedPetUniques calling EquippedPetsModule.get_my_equipped_char_wrappers()")
  local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()

  if not EquippedWrappers then
    print("DEBUG: GetMyEquippedPetUniques: EquippedPetsModule.get_my_equipped_char_wrappers() returned nil")
  else
    print("DEBUG: GetMyEquippedPetUniques: EquippedPetsModule.get_my_equipped_char_wrappers() returned a table with " .. #EquippedWrappers .. " wrappers.")
  end

  local PetUniqueIds = {}

  if not EquippedWrappers or #EquippedWrappers == 0 then
    return PetUniqueIds
  end

  for _, Wrapper in EquippedWrappers do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaces ipairs)
    local PetUniqueId = Wrapper["pet_unique"]
    if PetUniqueId and type(PetUniqueId) == "string" then
      table.insert(PetUniqueIds, PetUniqueId)
    else
      warn("GetMyEquippedPetUniques: Wrapper found but pet_unique ID is missing or not a string.")
    end
  end
  return PetUniqueIds
end

local function SetupSafetyPlatforms()
  local SafetyPlatformsFolder = workspace:FindFirstChild("SafetyPlatforms")
  if not SafetyPlatformsFolder then
    SafetyPlatformsFolder = Instance.new("Folder")
    SafetyPlatformsFolder.Name = "SafetyPlatforms"
    SafetyPlatformsFolder.Parent = workspace
  end

  local PlatformSize = Vector3.new(250, 4, 250) 
  local PlatformColor = Color3.fromRGB(120, 130, 140) 
  local PlatformMaterial = Enum.Material.Concrete

  local function CreatePlatformIfMissing(Name, TargetCFrame)
    if not TargetCFrame then
      warn("SetupSafetyPlatforms: Cannot create platform '", Name, "' because TargetCFrame is nil.")
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
    Platform.CFrame = TargetCFrame * CFrame.new(0, -(PlatformSize.Y / 2) - 2, 0) 
    Platform.Parent = SafetyPlatformsFolder
    print(string.format("SetupSafetyPlatforms: Created platform '%s'. Target CFrame: %s, Platform CFrame: %s", Name, tostring(TargetCFrame), tostring(Platform.CFrame)))
  end

  local ParkStaticMap = workspace:FindFirstChild("StaticMap")
  if ParkStaticMap then
    local ParkTarget = ParkStaticMap:FindFirstChild("Park")
    if ParkTarget and ParkTarget:FindFirstChild("BoredAilmentTarget") and ParkTarget.BoredAilmentTarget:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Park", ParkTarget.BoredAilmentTarget.CFrame)
    else
      warn("SetupSafetyPlatforms: Could not find StaticMap.Park.BoredAilmentTarget CFrame or it's not a BasePart.")
    end
    local BeachTarget = ParkStaticMap:FindFirstChild("Beach")
    if BeachTarget and BeachTarget:FindFirstChild("BeachPartyAilmentTarget") and BeachTarget.BeachPartyAilmentTarget:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Beach", BeachTarget.BeachPartyAilmentTarget.CFrame)
    else
      warn("SetupSafetyPlatforms: Could not find StaticMap.Beach.BeachPartyAilmentTarget CFrame or it's not a BasePart.")
    end
    local CampsiteTarget = ParkStaticMap:FindFirstChild("Campsite")
    if CampsiteTarget and CampsiteTarget:FindFirstChild("CampsiteOrigin") and CampsiteTarget.CampsiteOrigin:IsA("BasePart") then
      CreatePlatformIfMissing("SafetyPlatform_Campsite", CampsiteTarget.CampsiteOrigin.CFrame)
    else
      warn("SetupSafetyPlatforms: Could not find StaticMap.Campsite.CampsiteOrigin CFrame or it's not a BasePart.")
    end
  else
    warn("SetupSafetyPlatforms: Could not find StaticMap.")
  end

  if LocalPlayer and LocalPlayer["Name"] then -- Changed LocalPlayer.Name
    local HouseInteriors = workspace:FindFirstChild("HouseInteriors")
    if HouseInteriors then
      local BlueprintFolder = HouseInteriors:FindFirstChild("blueprint")
      if BlueprintFolder then
        local PlayerHouseBlueprint = BlueprintFolder:FindFirstChild(LocalPlayer["Name"]) -- Changed LocalPlayer.Name
        if PlayerHouseBlueprint then
          local FloorsFolder = PlayerHouseBlueprint:FindFirstChild("Floors")
          if FloorsFolder then
            local FloorParts = FloorsFolder:GetChildren()
            if #FloorParts > 0 and FloorParts[1]:IsA("BasePart") then
              local MainFloorPart = FloorParts[1]
              local HomeFloorTopCFrame = MainFloorPart.CFrame * CFrame.new(0, MainFloorPart.Size.Y / 2, 0)
              CreatePlatformIfMissing("SafetyPlatform_Home_" .. LocalPlayer["Name"], HomeFloorTopCFrame) -- Changed LocalPlayer.Name
            else
              warn("SetupSafetyPlatforms: Could not find suitable floor part for player: ", LocalPlayer["Name"]) -- Changed LocalPlayer.Name
            end
          else
            warn("SetupSafetyPlatforms: Could not find FloorsFolder for player: ", LocalPlayer["Name"]) -- Changed LocalPlayer.Name
          end
        else
          warn("SetupSafetyPlatforms: Could not find PlayerHouseBlueprint for player: ", LocalPlayer["Name"]) -- Changed LocalPlayer.Name
        end
      else
        warn("SetupSafetyPlatforms: Could not find HouseInteriors.blueprint folder.")
      end
    else
      warn("SetupSafetyPlatforms: Could not find HouseInteriors folder.")
    end
  else
    warn("SetupSafetyPlatforms: LocalPlayer or LocalPlayer.Name not available for Home platform.")
  end
end

-- [[ FUNCTION TO PROCESS TASK PLAN - TO BE EXPANDED ]] --
local function ProcessTaskPlan(PetUniqueId, PetModel, GeneratedPlan, AllAilmentActions, OriginalAilmentsFlatList)
  print(string.format("--- Starting Task Plan Execution for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
  print("    DEBUG: AllAilmentActions keys available at start of ProcessTaskPlan:")

  local ActionKeys = {}

  for Key, _ in AllAilmentActions do 
    table.insert(ActionKeys, Key) 
  end 

  table.sort(ActionKeys)

  for _, KeyName in ActionKeys do
    print(string.format("      - %s (type: %s)", KeyName, type(AllAilmentActions[KeyName])))
  end

  if GeneratedPlan and #GeneratedPlan > 0 then
    print(string.format("  Initial ailments for this plan: [%s]", table.concat(OriginalAilmentsFlatList or {}, ", ")))
  else
    print(string.format("ProcessTaskPlan: No tasks in the generated plan for %s. Initial ailments: [%s]", PetUniqueId, table.concat(OriginalAilmentsFlatList or {}, ", ")))
  end

  if GeneratedPlan and #GeneratedPlan > 0 then
    for TaskIndex, TaskData in GeneratedPlan do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced ipairs)
      print(string.format("  [%d/%d] Attempting Task: Type='%s', Ailment/Desc='%s', Time='%s'", 
        TaskIndex, #GeneratedPlan, TaskData["type"], TaskData["ailment"] or TaskData["description"] or "N/A", tostring(TaskData["time"] or TaskData["adjustedTime"] or 0)))

      local ActionToExecute = nil
      local ActionRequiresTargetCFrame = false
      local AilmentNameForAction = TaskData["ailment"] 

      if TaskData["type"] == "location" or TaskData["type"] == "instant" or TaskData["type"] == "remaining" then
        if AilmentNameForAction then
          local FoundAction = AllAilmentActions[AilmentNameForAction]
          if FoundAction then 
            ActionToExecute = FoundAction
            if AilmentNameForAction == "sleepy" or AilmentNameForAction == "dirty" or AilmentNameForAction == "toilet" then
              ActionRequiresTargetCFrame = true
            end
          end
        end
      elseif TaskData["type"] == "location_bonus" then 
        if AilmentNameForAction then
          local FoundAction = AllAilmentActions[AilmentNameForAction]
          if FoundAction and type(FoundAction) == "table" then 
            ActionToExecute = FoundAction 
            ActionRequiresTargetCFrame = true 
          elseif FoundAction then 
            ActionToExecute = FoundAction
          end
        end
      else 
        AilmentNameForAction = TaskData["ailment"] or TaskData["description"] 
        if AilmentNameForAction then
          local FoundAction = AllAilmentActions[AilmentNameForAction]
          if FoundAction then
            ActionToExecute = FoundAction
          end
        end
      end

      if ActionToExecute ~= nil then 
        local TargetCFrame = nil
        if ActionRequiresTargetCFrame then
          if PetModel and PetModel.PrimaryPart then -- Standard Roblox Instance property access
            TargetCFrame = PetModel.PrimaryPart.CFrame * CFrame.new(0,0,-3) 
            print(string.format("    Using placeholder TargetCFrame for '%s' action near pet.", AilmentNameForAction))
          else
            warn(string.format("    ProcessTaskPlan: Cannot determine TargetCFrame for action '%s': PetModel or PrimaryPart missing. Skipping this task.", tostring(AilmentNameForAction)))
            ActionRequiresTargetCFrame = false 
          end
        end

        print(string.format("    Executing action for: %s", tostring(AilmentNameForAction or TaskData["type"])))
        local Success, ErrorMessage -- Renamed ErrorMsg to ErrorMessage for pcall
        if ActionRequiresTargetCFrame and TargetCFrame then 
          if type(ActionToExecute) == "table" and ActionToExecute["Smart"] then -- Table key access for action sub-method
            warn(string.format("    ProcessTaskPlan: For '%s', Smart method selected with TargetCFrame.", tostring(AilmentNameForAction)))
            Success, ErrorMessage = pcall(ActionToExecute["Smart"], PetModel, TargetCFrame, true)
          elseif type(ActionToExecute) == "function" then 
            warn(string.format("    ProcessTaskPlan: WARNING - ActionRequiresTargetCFrame is true, but ActionToExecute for '%s' is a direct function. Calling with TargetCFrame anyway.", tostring(AilmentNameForAction)))
            Success, ErrorMessage = pcall(ActionToExecute, PetModel, TargetCFrame, true) 
          else
            warn(string.format("    ProcessTaskPlan: WARNING - ActionToExecute for '%s' is not a table with .Smart or a direct function. Cannot execute with TargetCFrame.", tostring(AilmentNameForAction)))
            Success = false
            ErrorMessage = "Action structure incompatible with TargetCFrame requirement."
          end
        else
          if type(ActionToExecute) == "table" and ActionToExecute["Standard"] then -- Table key access for action sub-method
            warn(string.format("    ProcessTaskPlan: For '%s', Standard method selected (or no TargetCFrame needed/available).", tostring(AilmentNameForAction)))
            Success, ErrorMessage = pcall(ActionToExecute["Standard"], PetModel, true)
          elseif type(ActionToExecute) == "function" then 
            warn(string.format("    ProcessTaskPlan: For '%s', direct function call (no TargetCFrame needed/available).", tostring(AilmentNameForAction)))
            Success, ErrorMessage = pcall(ActionToExecute, PetModel, true) 
          else
            warn(string.format("    ProcessTaskPlan: WARNING - ActionToExecute for '%s' is not a table with .Standard or a direct function. Cannot execute.", tostring(AilmentNameForAction)))
            Success = false
            ErrorMessage = "Action structure incompatible for non-TargetCFrame execution."
          end
        end

        if not Success then
          warn(string.format("    Error executing action '%s': %s", tostring(AilmentNameForAction or TaskData["type"]), tostring(ErrorMessage)))
        else
          print(string.format("    Action completed for: %s", tostring(AilmentNameForAction or TaskData["type"])))
        end
        task.wait(1) 
      else
        warn(string.format("    No specific action found in AilmentActions for task type: %s with ailment/desc: %s", tostring(TaskData["type"]), tostring(TaskData["ailment"] or TaskData["description"] or "N/A")))
      end
    end
  end

  if OriginalAilmentsFlatList and #OriginalAilmentsFlatList > 0 then
    print(string.format("--- Checking unresolved ailments for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
    local UnresolvedCount = 0
    for _, AilmentName in OriginalAilmentsFlatList do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced ipairs)
      if VerifyAilmentExists(PetModel, AilmentName) then
        UnresolvedCount = UnresolvedCount + 1
        warn(string.format("  FLAGGED: Initial ailment '%s' for pet '%s' was NOT resolved by the plan.", AilmentName, PetUniqueId))
      end
    end
    if UnresolvedCount == 0 then
      print("  All initial ailments for this plan were successfully resolved.")
    else
      print(string.format("  Total unresolved ailments from initial plan: %d", UnresolvedCount))
    end
  end

  print("--- Finished Task Plan Execution for Pet: " .. PetUniqueId .. " ---")
end
-- [[ END FUNCTION TO PROCESS TASK PLAN ]] --

-- Main loop to monitor _G.PetFarm
local CurrentInstanceLoopId = HttpService:GenerateGUID(false) -- Renamed variable
_G.PetFarmLoopInstanceId = CurrentInstanceLoopId
print("PetFarmOfficial.luau loop started with ID: " .. CurrentInstanceLoopId .. ". To stop this specific loop instance if script is re-run, simply re-run the script. To pause operations, set _G.PetFarm = false.")

SetupSafetyPlatforms() -- Call the function to create platforms

local LoopCounter = 0
local IsEquippedPetsModuleReportingNoPets = false

while _G.PetFarmLoopInstanceId == CurrentInstanceLoopId and task.wait(5) do
  LoopCounter = LoopCounter + 1
  if _G.PetFarm == true then
    if LoopCounter % 5 == 0 and not IsEquippedPetsModuleReportingNoPets then 
      print("PetFarm is ACTIVE (loop ID: " .. CurrentInstanceLoopId .. ", checked at " .. os.date("%X") .. ")")
    end

    local CurrentEquippedPetUniqueIds = GetMyEquippedPetUniques()

    if #CurrentEquippedPetUniqueIds == 0 then
      if not IsEquippedPetsModuleReportingNoPets then
        warn(os.date("%X") .. " - PetFarm CRITICAL WARNING: EquippedPetsModule is reporting NO equipped pets. All PetFarm operations requiring pet models will be paused until the module provides pet data. (Loop ID: " .. CurrentInstanceLoopId .. ")")
        IsEquippedPetsModuleReportingNoPets = true
      elseif LoopCounter % 10 == 0 then 
        warn(os.date("%X") .. " - PetFarm INFO: EquippedPetsModule continues to report NO equipped pets. Operations remain paused. (Loop ID: " .. CurrentInstanceLoopId .. ")")
      end
    else 
      if IsEquippedPetsModuleReportingNoPets then
        print(os.date("%X") .. " - PetFarm INFO: EquippedPetsModule is NOW reporting equipped pets (" .. #CurrentEquippedPetUniqueIds .. " found). Resuming normal operations. (Loop ID: " .. CurrentInstanceLoopId .. ")")
        IsEquippedPetsModuleReportingNoPets = false 
      end

      print(os.date("%X") .. " - DEBUG: Equipped Pet Unique IDs from Module: [" .. table.concat(CurrentEquippedPetUniqueIds, ", ") .. "] (Loop ID: " .. CurrentInstanceLoopId .. ")")

      local AllPetsAilmentsData = GetCurrentAilments()
      local PlannerAilmentCategories = TaskPlanner:GetAilmentCategories() 

      if #AllPetsAilmentsData > 0 then
        print(os.date("%X") .. " - Raw Detected Pet Ailments Report (Loop ID: " .. CurrentInstanceLoopId .. "):")
        for _, PetRawDataEntry in AllPetsAilmentsData do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced ipairs), Renamed PetRawDataLoopVar
          print(string.format("  Pet Unique ID: %s, Ailments: [%s]", PetRawDataEntry["unique"], table.concat(PetRawDataEntry["ailments"], ", ")))
        end
        print("---") 

        for _, PetRawData in AllPetsAilmentsData do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced ipairs)
          local PetUniqueId = PetRawData["unique"]
          local PetModel = GetPetModelByUniqueId(PetUniqueId)
          local ShouldProcessPet = true 

          if not PetModel then
            warn(string.format("PetFarm: Pet '%s' has ailments but its model was not found via EquippedPetsModule. Attempting to equip... (Loop ID: %s)", PetUniqueId, CurrentInstanceLoopId))
            API["ToolAPI/Equip"]:InvokeServer(PetUniqueId, {["use_sound_delay"] = false, ["equip_as_last"] = false}) -- String keys for properties table
            task.wait(3) 

            PetModel = GetPetModelByUniqueId(PetUniqueId) 

            if not PetModel then
              warn(string.format("PetFarm: Failed to retrieve model for pet '%s' after equip attempt, or module did not update. Skipping plan for this pet. (Loop ID: %s)", PetUniqueId, CurrentInstanceLoopId))
              ShouldProcessPet = false 
            else
              print(string.format("PetFarm: Successfully re-acquired model for pet '%s' after equip attempt. (Loop ID: %s)", PetUniqueId, CurrentInstanceLoopId))
            end
          end

          if ShouldProcessPet and PetModel then 
            local PetDataForPlanner = {
              ["unique"] = PetRawData["unique"],
              ["ailments"] = {
                ["location"] = {},
                ["feeding"] = {},
                ["playful"] = {},
                ["static"] = {},
                ["hybrid"] = {},
                ["meta_tasks"] = {},
                ["unknown"] = {}
              }
            }

            for _, AilmentName in PetRawData["ailments"] do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced ipairs)
              local FoundCategory = false
              for CategoryName, CategoryData in PlannerAilmentCategories do -- STYLE_GUIDE.md > Performance Guidelines > Loop Optimization (replaced pairs)
                if type(CategoryData) == "table" and CategoryData[AilmentName] then
                  table.insert(PetDataForPlanner["ailments"][CategoryName], AilmentName)
                  FoundCategory = true
                  break 
                end
              end
              if not FoundCategory then
                table.insert(PetDataForPlanner["ailments"]["unknown"], AilmentName)
              end
            end

            if TaskPlanner and PlanFormatter then
              print(string.format("Generating plan for Pet: %s (Loop ID: %s)", PetDataForPlanner["unique"], CurrentInstanceLoopId))
              local GeneratedPlan = TaskPlanner:GenerateTaskPlan(PetDataForPlanner, true)
              PlanFormatter.Print(GeneratedPlan, PetDataForPlanner["unique"], PlannerAilmentCategories)

              ProcessTaskPlan(PetDataForPlanner["unique"], PetModel, GeneratedPlan, AilmentActions, PetRawData["ailments"])
            else
              warn("TaskPlanner or PlanFormatter not loaded correctly. Cannot generate or print plan. (Loop ID: " .. CurrentInstanceLoopId .. ")")
            end
          end
        end

      else
        if LoopCounter % 10 == 0 then 
          print(os.date("%X") .. " - No current pet ailments detected for any pet (and module is reporting pets). (Loop ID: " .. CurrentInstanceLoopId .. ")")
        end
      end
    end 
  else
    if LoopCounter % 30 == 0 then 
      print("PetFarm is INACTIVE (loop ID: " .. CurrentInstanceLoopId .. ", checked at " .. os.date("%X") .. ")")
    end
  end
end

if _G.PetFarmLoopInstanceId ~= CurrentInstanceLoopId then
  print("PetFarmOfficial.luau loop with ID: " .. CurrentInstanceLoopId .. " stopping as a new instance has started (new active ID: " .. tostring(_G.PetFarmLoopInstanceId) .. ").")
else
  print("PetFarmOfficial.luau loop with ID: " .. CurrentInstanceLoopId .. " stopping. If _G.PetFarmLoopInstanceId was manually cleared or script execution ended, this is expected.")
end

function WaitForAilmentClearanceWithTimeout(PetModel, AilmentName, TimeoutDurationSeconds, ExtraSuccessConditionFunction)
  if not PetModel or not AilmentName or not TimeoutDurationSeconds then
    warn(string.format("WaitForAilmentClearanceWithTimeout: Invalid arguments. PetModel: %s, AilmentName: %s, TimeoutDurationSeconds: %s",
      tostring(PetModel), tostring(AilmentName), tostring(TimeoutDurationSeconds)))
    return false 
  end

  local StartTime = os.clock()
  local ConditionMet = false

  repeat
    task.wait(1) 

    local AilmentExists = VerifyAilmentExists(PetModel, AilmentName)
    local ExtraConditionResult = true 
    if ExtraSuccessConditionFunction then
      local Success, Result = pcall(ExtraSuccessConditionFunction)
      if Success then
        ExtraConditionResult = Result
      else
        warn(string.format("WaitForAilmentClearanceWithTimeout: Error executing ExtraSuccessConditionFunction for ailment '%s': %s", AilmentName, tostring(Result)))
        ExtraConditionResult = false 
      end
    end

    if not AilmentExists and ExtraConditionResult then
      ConditionMet = true
      break
    end

    if os.clock() - StartTime > TimeoutDurationSeconds then
      warn(string.format("WaitForAilmentClearanceWithTimeout: TIMEOUT waiting for ailment '%s' on pet '%s' to clear after %d seconds. AilmentExists: %s, ExtraConditionResult: %s", 
        AilmentName, GetPetUniqueIdString(PetModel), TimeoutDurationSeconds, tostring(AilmentExists), tostring(ExtraConditionResult)))
      ConditionMet = false 
      break
    end
  until ConditionMet

  return ConditionMet
end


