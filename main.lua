local ReplicatedStorage = game:GetService("ReplicatedStorage")
local API = ReplicatedStorage:WaitForChild("API")
local HttpService = game:GetService("HttpService")

local LocalPlayer = game:GetService("Players").LocalPlayer

-- Load external modules using HttpGet and loadstring
local TaskPlanner = loadstring(game:HttpGet(('https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/TaskPlanner.lua'), true))()
local PlanFormatter = loadstring(game:HttpGet(('https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/PlanFormatter.lua'), true))()

local SmartFurnitureMap = {}

local AILMENT_TO_FURNITURE_MODEL_MAP = {
    thirsty = "AilmentsRefresh2024CheapWaterBowl",
    hungry = "AilmentsRefresh2024CheapWaterBowl",
    toilet = "AilmentsRefresh2024LitterBox",
    dirty = "ModernShower",
    sleepy = "BasicCrib"
}

-- [[ STUB FUNCTIONS FOR "catch" AILMENT - USER TO IMPLEMENT/REFINE ]] --
-- Attempt to define or access ClientData for stubbing equip manager
local ClientData = ClientData or {} -- Use existing ClientData if global, otherwise create local stub
ClientData.equip_manager = ClientData.equip_manager or {}
ClientData.equip_manager.inventory = ClientData.equip_manager.inventory or {}
ClientData.equip_manager.inventory.toys = ClientData.equip_manager.inventory.toys or {} -- Stub: Array of equipped toy items

ClientData.inventory = ClientData.inventory or {}
ClientData.inventory.toys = ClientData.inventory.toys or { -- Stub: Player's owned toys
    { Name = "Red Ball", UniqueId = "toy_ball_01", IsThrowable = true, SomeOtherProperty = "value1" },
    { Name = "Plushie", UniqueId = "toy_plush_01", IsThrowable = false, SomeOtherProperty = "value2" },
    { Name = "Frisbee", UniqueId = "toy_frisbee_01", IsThrowable = true, SomeOtherProperty = "value3" },
}

local function GetPlayerOwnedToys()
    -- STUB: Replace with actual logic to get player's toy inventory (e.g., from ClientData)
    warn("GetPlayerOwnedToys: Using STUBBED toy inventory.")
    return ClientData.inventory.toys 
end

local function FindFirstThrowableToyInList(OwnedToysTable)
    -- STUB: Assumes toys have an 'IsThrowable' boolean property.
    -- Replace with actual logic based on your toy item structure.
    if type(OwnedToysTable) ~= "table" then return nil end
    for _, ToyItem in ipairs(OwnedToysTable) do
        if ToyItem and ToyItem.IsThrowable then
            return ToyItem
        end
    end
    return nil
end

local function GetPetUniqueIdString(PetModel)
    -- STUB: Assumes PetModel.unique contains the string ID as seen in API examples.
    -- Adjust if the unique ID is stored differently (e.g., PetModel.Name, or another property).
    if PetModel and PetModel.unique and type(PetModel.unique) == "string" then
        return PetModel.unique
    elseif PetModel and PetModel.Name then
        warn("GetPetUniqueIdString: PetModel.unique not found or not a string, using PetModel.Name ('" .. PetModel.Name .. "') as a fallback. This might not be the correct format for PetObjectAPI.")
        return PetModel.Name -- Fallback, may not be the correct ID format like "2_xxxx"
    end
    warn("GetPetUniqueIdString: Could not determine unique ID for PetModel.")
    return "stub_pet_unique_id_error"
end

local function IsToyEquippedByPlayer(ToyItemToVerify)
    -- STUB: Implement logic to check if ToyItemToVerify.UniqueId is in ClientData.equip_manager.inventory.toys
    -- This function is crucial for the full 'WaitForCompletion' logic of the 'catch' ailment.
    warn("IsToyEquippedByPlayer: STUB returning TRUE. Implement actual check against ClientData.equip_manager.inventory.toys for toy '" .. (ToyItemToVerify and ToyItemToVerify.Name or "nil") .. "'.")
    return true -- Placeholder, so it doesn't block completion loop during stub phase
end
-- [[ END OF STUB FUNCTIONS ]] --

local AILMENT_KEYWORDS_MAP = {
    dirty = {"shower", "bath", "tub"},
    sleepy = {"bed", "crib", "cot", "hammock"},
    toilet = {"toilet", "litter box", "potty"} -- Using "litter box" to match common pet item phrasing
}

local function FindFirstAilmentFurniture(AilmentName)
    local Keywords = AILMENT_KEYWORDS_MAP[AilmentName]
    if not Keywords then
        warn("FindFirstAilmentFurniture: No keywords defined for ailment: " .. AilmentName)
        return nil
    end

    local FurnitureFolder = workspace.HouseInteriors and workspace.HouseInteriors:FindFirstChild("furniture")
    if not FurnitureFolder then
        warn("FindFirstAilmentFurniture: workspace.HouseInteriors.furniture not found.")
        return nil
    end

    for _, FurnitureInstance in ipairs(FurnitureFolder:GetChildren()) do
        if FurnitureInstance:IsA("Model") or FurnitureInstance:IsA("BasePart") then -- Ensure it's a physical item
            local LowercaseFurnitureName = string.lower(FurnitureInstance.Name)
            for _, Keyword in ipairs(Keywords) do
                if string.find(LowercaseFurnitureName, string.lower(Keyword)) then
                    warn(string.format("FindFirstAilmentFurniture: Found generic furniture '%s' for ailment '%s' using keyword '%s'.", FurnitureInstance.Name, AilmentName, Keyword))
                    return FurnitureInstance
                end
            end
        end
    end
    
    warn("FindFirstAilmentFurniture: No suitable owned furniture found for ailment: " .. AilmentName)
    return nil
end

function VerifyAilmentExists(PetModel, AilmentName)
  -- Stub
  return false
end

-- Find the first piece of furniture that a pet can sit on
function FindFirstSitable(PetModel)
  -- Stub
  return nil
end

local function GetSmartFurniture()
    local FoundItems = {}
    local FurnitureFolder = workspace.HouseInteriors and workspace.HouseInteriors:FindFirstChild("furniture")
    if not FurnitureFolder then
        warn("GetSmartFurniture: workspace.HouseInteriors.furniture not found!")
        return FoundItems
    end

    for Ailment, ModelName in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
        local Item = FurnitureFolder:FindFirstChild(ModelName)
        if Item then
            FoundItems[Ailment] = Item
        end
    end
    return FoundItems
end

local function InitializeSmartFurniture()
    local CurrentSmartFurnitureItems = GetSmartFurniture()
    local FurnitureFolder = workspace.HouseInteriors and workspace.HouseInteriors:FindFirstChild("furniture")

    if not FurnitureFolder then
        warn("InitializeSmartFurniture: workspace.HouseInteriors.furniture not found! Cannot process smart furniture.")
        SmartFurnitureMap = CurrentSmartFurnitureItems
        return
    end

    local ItemsToBuy = {}
    local ItemKindsToModelNames = {}

    for Ailment, ModelName in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
        if not CurrentSmartFurnitureItems[Ailment] then
            local KindName = ModelName
            KindName = KindName:gsub("([A-Z]+)([A-Z][a-z])", "%1_%2")
            KindName = KindName:gsub("([a-z%d])([A-Z])", "%1_%2")
            KindName = KindName:lower()
            
            table.insert(ItemsToBuy, { kind = KindName, properties = { cframe = CFrame.new(0, -1000, 0) } })
            ItemKindsToModelNames[KindName] = ModelName
            warn(string.format("InitializeSmartFurniture: Queuing purchase for '%s' (model: %s) for ailment '%s'.", KindName, ModelName, Ailment))
        end
    end

    if #ItemsToBuy > 0 then
        local Success, Error = pcall(function()
            API["HousingAPI/BuyFurnitures"]:InvokeServer(unpack(ItemsToBuy))
        end)

        if not Success then
            warn(string.format("InitializeSmartFurniture: Error purchasing furniture: %s", tostring(Error)))
            SmartFurnitureMap = CurrentSmartFurnitureItems
            return
        end

        task.wait() 
        API["HousingAPI/PushFurnitureChanges"]:FireServer({})
        task.wait() 

        for _, BoughtItemInfo in ipairs(ItemsToBuy) do
            local ModelNameToFind = ItemKindsToModelNames[BoughtItemInfo.kind]
            if ModelNameToFind then
                local NewItem = FurnitureFolder:FindFirstChild(ModelNameToFind)
                if NewItem then
                    for Ailment, MN in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
                        if MN == ModelNameToFind and not CurrentSmartFurnitureItems[Ailment] then
                            CurrentSmartFurnitureItems[Ailment] = NewItem
                            warn(string.format("InitializeSmartFurniture: Successfully found purchased item '%s' for ailment '%s'.", ModelNameToFind, Ailment))
                            break
                        end
                    end
                else
                    warn(string.format("InitializeSmartFurniture: Failed to find purchased item '%s' (kind: %s) in workspace after buying.", ModelNameToFind, BoughtItemInfo.kind))
                end
            end
        end
    end
    SmartFurnitureMap = CurrentSmartFurnitureItems
end

function TeleportToAilmentLocation(Location)
  local MainLocationMap = {
    ["beach"] = workspace.StaticMap.Beach.BeachPartyAilmentTarget.CFrame;
    ["park"] = workspace.StaticMap.Park.BoredAilmentTarget.CFrame;
    ["camping"] = workspace.StaticMap.Campsite.CampsiteOrigin.CFrame;
  }

  local Success, Error = pcall(function()
    if MainLocationMap[Location] then
      API["LocationAPI/SetLocation"]:FireServer("MainMap", _, "Default")
      task.wait()
      LocalPlayer.Character.HumanoidRootPart.CFrame = MainLocationMap[Location] * CFrame.new(0, 5, 0)
    else
      API["LocationAPI/SetLocation"]:FireServer(Location)
    end
  end)

  if not Success then
    warn(string.format("Error teleporting to %s: %s", Location, Error or "Unknown error"))
  end
end

function PlaceAndUseSitableAtCFrame(Sitable, TargetCFrame, PetModel)
  if not Sitable or not TargetCFrame then warn("Attempting to place and use a sitable with no sitable or target cframe") return end

  API["HousingAPI/PushFurnitureChanges"]:FireServer({
    [1] = {
      ["unique"] = Sitable.name,
      ["cframe"] = TargetCFrame
    }
  })

  task.wait()

  API["HousingAPI/ActivateFurniture"]:InvokeServer(
    LocalPlayer,
    Sitable.name,
    Sitable.vacant_seat or "UseBlock", -- Added fallback for vacant_seat
    {["cframe"] = TargetCFrame},
    PetModel
  )
end

local function HandleSmartOrTeleportAilment(AilmentTargetCFrame, LocationName, PetModel, AilmentName)
  local FurnitureToUse = nil
  if next(SmartFurnitureMap) == nil then 
      InitializeSmartFurniture()
  end
  
  FurnitureToUse = SmartFurnitureMap[AilmentName] -- Try specific smart furniture first

  if not FurnitureToUse then -- If no specific smart furniture, try generic ailment furniture
      FurnitureToUse = FindFirstAilmentFurniture(AilmentName)
  end
  
  -- Note: FindFirstSitable(PetModel) is not currently called as a fallback here.
  -- If FurnitureToUse is still nil, it means neither specific smart nor generic owned furniture was found.

  if FurnitureToUse then
      PlaceAndUseSitableAtCFrame(FurnitureToUse, AilmentTargetCFrame, PetModel)
      return
  end

  -- Only teleport if no furniture solution was found AND it's a location-based ailment handled by this function.
  -- For non-location ailments (like sleepy/dirty/toilet if no furniture), this function would effectively do nothing more if teleport isn't desired.
  -- The current AilmentActions for sleepy/dirty/toilet do NOT call HandleSmartOrTeleportAilment, they manage furniture directly.
  -- So this TeleportToAilmentLocation below is primarily for bored, beach, camping.
  TeleportToAilmentLocation(LocationName)
end

local AilmentActions = {
  ["bored"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "bored") then return end
      local AilmentTargetCFrame = workspace.StaticMap.Park.BoredAilmentTarget.CFrame
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "park", PetModel, "bored")

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "bored")
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'bored' ailment: %s", Error or "Unknown error"))
    end
  end;
  ["beach"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "beach_party") then return end -- Assuming beach_party is the ailment name to check
      local AilmentTargetCFrame = workspace.StaticMap.Beach.BeachPartyAilmentTarget.CFrame
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "beach", PetModel, "beach_party") 

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "beach_party")
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'beach' ailment: %s", Error or "Unknown error"))
    end
  end;
  ["camping"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "camping") then return end
      local AilmentTargetCFrame = workspace.StaticMap.Campsite.CampsiteOrigin.CFrame
      task.spawn(HandleSmartOrTeleportAilment, AilmentTargetCFrame, "campsite", PetModel, "camping")

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "camping")
      end
    end)

    if not Success then 
      warn(string.format("Error executing 'camping' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["hungry"] = {
    Standard = function(PetModel, WaitForCompletion)
      local Success, Error = pcall(function()
        if not VerifyAilmentExists(PetModel, "hungry") then return end
        warn(string.format("PetFarmOfficial.AilmentActions.hungry.Standard: Simulating purchase of Apple and feeding to %s. Implement actual item purchase and use API.", PetModel.Name))
        -- Add actual API calls here when available
        if WaitForCompletion then
          repeat task.wait(1) until not VerifyAilmentExists(PetModel, "hungry")
        end
      end)
      if not Success then
        warn(string.format("Error executing 'hungry.Standard' ailment: %s", Error or "Unknown error"))
      end
    end,
    Smart = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, Error = pcall(function()
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
          repeat task.wait(1) until not VerifyAilmentExists(PetModel, "hungry")
        end
      end)
      if not Success then
        warn(string.format("Error executing 'hungry.Smart' ailment: %s", Error or "Unknown error"))
      end
    end
  };

  ["thirsty"] = {
    Standard = function(PetModel, WaitForCompletion)
      local Success, Error = pcall(function()
        if not VerifyAilmentExists(PetModel, "thirsty") then return end
        warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Standard: Simulating purchase of CupOfTea and feeding to %s. Implement actual item purchase and use API.", PetModel.Name))
        -- Add actual API calls here when available
        if WaitForCompletion then
          repeat task.wait(1) until not VerifyAilmentExists(PetModel, "thirsty")
        end
      end)
      if not Success then
        warn(string.format("Error executing 'thirsty.Standard' ailment: %s", Error or "Unknown error"))
      end
    end,
    Smart = function(PetModel, TargetCFrame, WaitForCompletion)
      local Success, Error = pcall(function()
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
          repeat task.wait(1) until not VerifyAilmentExists(PetModel, "thirsty")
        end
      end)
      if not Success then
        warn(string.format("Error executing 'thirsty.Smart' ailment: %s", Error or "Unknown error"))
      end
    end
  };

  ["sick"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "sick") then return end -- Added ailment verification
      API["LocationAPI/SetLocation"]:FireServer("Hospital")
      task.wait()
      API["HousingAPI/ActivateInteriorFurniture"]:InvokeServer({"f-14", "UseBlock", "Yes", LocalPlayer.Character})
      if WaitForCompletion then -- Added WaitForCompletion loop here for consistency
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "sick")
      end
    end)

    if not Success then
      warn(string.format("Error executing 'sick' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["salon"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "salon") then return end
      TeleportToAilmentLocation("Salon")
      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "salon")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'salon' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["school"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "school") then return end
      TeleportToAilmentLocation("School")
      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "school")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'school' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["pizza_party"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "pizza_party") then return end
      TeleportToAilmentLocation("PizzaShop") 
      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "pizza_party")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'pizza_party' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["sleepy"] = function(PetModel, TargetCFrame, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "sleepy") then return end
      if next(SmartFurnitureMap) == nil then
        InitializeSmartFurniture()
      end
      local FurnitureItem = SmartFurnitureMap["sleepy"] -- Prioritize specific smart item
      if not FurnitureItem then
        FurnitureItem = FindFirstAilmentFurniture("sleepy") -- Fallback to generic owned furniture
      end

      if FurnitureItem then
        PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
      else
        warn("PetFarmOfficial.AilmentActions.sleepy: No suitable smart or generic owned crib/bed found. Ailment may not be completable by this action.")
      end

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "sleepy")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'sleepy' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["dirty"] = function(PetModel, TargetCFrame, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "dirty") then return end
      if next(SmartFurnitureMap) == nil then
        InitializeSmartFurniture()
      end
      local FurnitureItem = SmartFurnitureMap["dirty"] -- Prioritize specific smart item
      if not FurnitureItem then
        FurnitureItem = FindFirstAilmentFurniture("dirty") -- Fallback to generic owned furniture
      end

      if FurnitureItem then
        PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
      else
        warn("PetFarmOfficial.AilmentActions.dirty: No suitable smart or generic owned shower/bath found. Ailment may not be completable by this action.")
      end

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "dirty")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'dirty' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["catch"] = function(PetModel, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "catch") then return end

      local OwnedToys = GetPlayerOwnedToys()
      local ThrowableToy = FindFirstThrowableToyInList(OwnedToys)

      if not ThrowableToy then
        warn("PetFarmOfficial.AilmentActions.catch: No throwable toy found in player inventory. Cannot perform 'catch' action.")
        return
      end

      warn(string.format("PetFarmOfficial.AilmentActions.catch: Player must have toy '%s' (UniqueId: %s) equipped for the 'catch' action to proceed correctly. This is an assumed prerequisite state.", ThrowableToy.Name, ThrowableToy.UniqueId))

      local PetUniqueId = GetPetUniqueIdString(PetModel)
      if PetUniqueId == "stub_pet_unique_id_error" then
          warn("PetFarmOfficial.AilmentActions.catch: Could not get a valid unique ID for the pet. Aborting 'catch' action.")
          return
      end
            
      API["PetObjectAPI/CreatePetObject"]:InvokeServer("_Enum_PetObjectCreatorType_1", {
        reaction_name = "ThrowToyReaction",
        unique_id = PetUniqueId
      })
      -- Assuming CreatePetObject initiates the throw and pet interaction.

      if WaitForCompletion then
        warn("PetFarmOfficial.AilmentActions.catch: Waiting for 'catch' ailment to clear. For full completion, also ensure IsToyEquippedByPlayer("..ThrowableToy.Name..") is implemented and added to the wait condition.")
        repeat
          task.wait(1)
        until not VerifyAilmentExists(PetModel, "catch") -- TODO: Extend condition with 'and IsToyEquippedByPlayer(ThrowableToy)' once IsToyEquippedByPlayer is fully implemented.
      end
    end)
    if not Success then
      warn(string.format("Error executing 'catch' ailment: %s", Error or "Unknown error"))
    end
  end;

  ["toilet"] = function(PetModel, TargetCFrame, WaitForCompletion)
    local Success, Error = pcall(function()
      if not VerifyAilmentExists(PetModel, "toilet") then return end
      if next(SmartFurnitureMap) == nil then
        InitializeSmartFurniture()
      end
      local FurnitureItem = SmartFurnitureMap["toilet"] -- Prioritize specific smart item (LitterBox)
      if not FurnitureItem then
        FurnitureItem = FindFirstAilmentFurniture("toilet") -- Fallback to generic owned furniture
      end

      if FurnitureItem then
        PlaceAndUseSitableAtCFrame(FurnitureItem, TargetCFrame, PetModel)
      else
        warn("PetFarmOfficial.AilmentActions.toilet: No suitable smart or generic owned toilet/litter box found. Ailment may not be completable by this action.")
      end

      if WaitForCompletion then
        repeat task.wait(1) until not VerifyAilmentExists(PetModel, "toilet")
      end
    end)
    if not Success then
      warn(string.format("Error executing 'toilet' ailment: %s", Error or "Unknown error"))
    end
  end;
}

-- Updated GetCurrentAilments function
local function GetCurrentAilments()
  local ClientDataModule = require(ReplicatedStorage.ClientModules.Core.ClientData) 
  local PlayerData = ClientDataModule.get_data()[LocalPlayer.Name]
  local PetAilmentsResult = {}

  if not PlayerData or not PlayerData.ailments_manager or not PlayerData.ailments_manager.ailments then
    warn("GetCurrentAilments: Could not find ailment data for LocalPlayer ('" .. LocalPlayer.Name .. "') in ClientData. Structure might be unexpected or data not yet available.")
    return PetAilmentsResult -- Return empty if path is invalid
  end
  
  -- Iterate through all pets and their ailments
  for PetUnique, AilmentInfo in pairs(PlayerData.ailments_manager.ailments) do -- Use pairs for dictionaries
    local CurrentPetSpecificAilments = {}
    
    -- Extract ailment kinds for this pet
    if type(AilmentInfo) == "table" then
        for AilmentName, AilmentData in pairs(AilmentInfo) do -- Use pairs for dictionaries
            if type(AilmentData) == "table" and AilmentData.kind then
                table.insert(CurrentPetSpecificAilments, AilmentData.kind)
            end
        end
    end
    
    -- Add to results if pet has ailments
    if #CurrentPetSpecificAilments > 0 then
      table.insert(PetAilmentsResult, {
        unique = PetUnique,
        ailments = CurrentPetSpecificAilments
      })
    end
  end
  
  return PetAilmentsResult
end

-- [[ HELPER FUNCTION TO GET PET MODEL - USER TO REFINE ]] --
local function GetPetModelByUniqueId(PetUniqueId)
    -- STUB: Assumes pets are direct children of workspace.Pets and their Name or a StringValue child named "UniqueId" matches.
    -- Adjust this to your actual pet storage and identification method.
    local PetsContainer = workspace:FindFirstChild("Pets")
    if not PetsContainer then
        warn("GetPetModelByUniqueId: workspace.Pets container not found.")
        return nil
    end

    for _, PetInstance in ipairs(PetsContainer:GetChildren()) do
        if PetInstance:IsA("Model") then
            if PetInstance.Name == PetUniqueId then
                return PetInstance
            end
            local IdValue = PetInstance:FindFirstChild("UniqueId")
            if IdValue and IdValue:IsA("StringValue") and IdValue.Value == PetUniqueId then
                return PetInstance
            end
        end
    end
    warn("GetPetModelByUniqueId: Could not find PetModel for Unique ID: " .. PetUniqueId)
    return nil
end
-- [[ END HELPER FUNCTION ]] --

-- [[ FUNCTION TO PROCESS TASK PLAN - TO BE EXPANDED ]] --
local function ProcessTaskPlan(PetUniqueId, PetModel, GeneratedPlan, AllAilmentActions)
    print(string.format("--- Starting Task Plan Execution for Pet: %s (%s) ---", PetModel.Name, PetUniqueId))
    if not GeneratedPlan or #GeneratedPlan == 0 then
        print("ProcessTaskPlan: No tasks in the generated plan for " .. PetUniqueId .. ".")
        return
    end

    for TaskIndex, TaskData in ipairs(GeneratedPlan) do
        print(string.format("  [%d/%d] Attempting Task: Type='%s', Ailment/Desc='%s', Time='%s'", 
            TaskIndex, #GeneratedPlan, TaskData.type, TaskData.ailment or TaskData.description or "N/A", tostring(TaskData.time or TaskData.adjustedTime or 0)))

        local ActionToExecute = nil
        local ActionRequiresTargetCFrame = false
        local AilmentNameForAction = TaskData.ailment

        if TaskData.type == "location" or TaskData.type == "instant" or TaskData.type == "remaining" then
            -- These types often use TaskData.ailment as the direct key in AilmentActions
            AilmentNameForAction = TaskData.ailment
            if AllAilmentActions[AilmentNameForAction] then 
                ActionToExecute = AllAilmentActions[AilmentNameForAction]
                if AilmentNameForAction == "sleepy" or AilmentNameForAction == "dirty" or AilmentNameForAction == "toilet" then
                    ActionRequiresTargetCFrame = true
                end
            end
        elseif TaskData.type == "location_bonus" then 
            AilmentNameForAction = TaskData.ailment 
            -- For location bonus, decide if it's standard or smart (e.g. hungry)
            if AllAilmentActions[AilmentNameForAction] and type(AllAilmentActions[AilmentNameForAction]) == "table" then -- e.g. hungry.Smart
                ActionToExecute = AllAilmentActions[AilmentNameForAction].Smart -- Default to Smart for bonus items like bowls
                ActionRequiresTargetCFrame = true -- Smart feeding/drinking needs a CFrame
            elseif AllAilmentActions[AilmentNameForAction] then -- simple bonus like pet_me
                ActionToExecute = AllAilmentActions[AilmentNameForAction]
            end
        else
           AilmentNameForAction = TaskData.ailment or TaskData.description -- Fallback for other types if they use ailment name
           if AllAilmentActions[AilmentNameForAction] then
                ActionToExecute = AllAilmentActions[AilmentNameForAction]
           end
        end
        
        if ActionToExecute then
            local TargetCFrame = nil
            if ActionRequiresTargetCFrame then
                if PetModel and PetModel.PrimaryPart then
                    TargetCFrame = PetModel.PrimaryPart.CFrame * CFrame.new(0,0,-3) -- Placeholder CFrame
                    print(string.format("    Using placeholder TargetCFrame for '%s' action near pet.", AilmentNameForAction))
                else
                    warn("    Cannot determine TargetCFrame for action ", AilmentNameForAction, ": PetModel or PrimaryPart missing. Skipping this task.")
                    continue -- Replaced goto next_task with continue
                end
            end

            print("    Executing action for: " .. (AilmentNameForAction or TaskData.type))
            local Success, ErrorMsg
            if ActionRequiresTargetCFrame then
                Success, ErrorMsg = pcall(ActionToExecute, PetModel, TargetCFrame, true) -- WaitForCompletion = true
            else
                 -- Handle actions like hungry/thirsty.Standard or location teleports
                if type(ActionToExecute) == "table" and ActionToExecute.Standard then -- e.g. hungry, thirsty
                     warn("    ProcessTaskPlan: For ", AilmentNameForAction, ", Standard method selected (or no CFrame method). Requires PetModel, WaitForCompletion.")
                     Success, ErrorMsg = pcall(ActionToExecute.Standard, PetModel, true)
                else -- Direct function call (e.g. sick, salon, bored, catch)
                    Success, ErrorMsg = pcall(ActionToExecute, PetModel, true) -- WaitForCompletion = true
                end
            end

            if not Success then
                warn(string.format("    Error executing action '%s': %s", AilmentNameForAction or TaskData.type, tostring(ErrorMsg)))
            else
                print("    Action completed for: " .. (AilmentNameForAction or TaskData.type))
            end
            task.wait(1) -- Small delay between tasks
        else
            warn("    No specific action found in AilmentActions for task type: ", TaskData.type, " with ailment/desc: ", TaskData.ailment or TaskData.description or "N/A")
        end
    end
    print("--- Finished Task Plan Execution for Pet: " .. PetUniqueId .. " ---")
end
-- [[ END FUNCTION TO PROCESS TASK PLAN ]] --

-- Main loop to monitor _G.PetFarm
local currentInstanceLoopId = HttpService:GenerateGUID(false)
_G.PetFarmLoopInstanceId = currentInstanceLoopId
print("PetFarmOfficial.luau loop started with ID: " .. currentInstanceLoopId .. ". To stop this specific loop instance if script is re-run, simply re-run the script. To pause operations, set _G.PetFarm = false.")

local LoopCounter = 0
while _G.PetFarmLoopInstanceId == currentInstanceLoopId and task.wait(5) do
    LoopCounter = LoopCounter + 1
    if _G.PetFarm == true then
        if LoopCounter % 5 == 0 then 
            print("PetFarm is ACTIVE (loop ID: " .. currentInstanceLoopId .. ", checked at " .. os.date("%X") .. ")")
        end
        
        local AllPetsAilmentsData = GetCurrentAilments()
        
        if #AllPetsAilmentsData > 0 then
            print(os.date("%X") .. " - Raw Detected Pet Ailments Report (Loop ID: " .. currentInstanceLoopId .. "):")
            for _, PetRawData in ipairs(AllPetsAilmentsData) do
                print(string.format("  Pet Unique ID: %s, Ailments: [%s]", PetRawData.unique, table.concat(PetRawData.ailments, ", ")))
            end
            print("---") 

            local PlannerAilmentCategories = TaskPlanner:GetAilmentCategories()

            for _, PetRawData in ipairs(AllPetsAilmentsData) do
                local PetDataForPlanner = {
                    unique = PetRawData.unique,
                    ailments = {
                        location = {},
                        feeding = {},
                        playful = {},
                        static = {},
                        hybrid = {},
                        meta_tasks = {},
                        unknown = {}
                    }
                }

                for _, AilmentName in ipairs(PetRawData.ailments) do
                    local FoundCategory = false
                    for CategoryName, CategoryData in pairs(PlannerAilmentCategories) do
                        if type(CategoryData) == "table" and CategoryData[AilmentName] then
                            table.insert(PetDataForPlanner.ailments[CategoryName], AilmentName)
                            FoundCategory = true
                            break 
                        end
                    end
                    if not FoundCategory then
                        table.insert(PetDataForPlanner.ailments.unknown, AilmentName)
                    end
                end
                
                if TaskPlanner and PlanFormatter then
                    print(string.format("Generating plan for Pet: %s (Loop ID: %s)", PetDataForPlanner.unique, currentInstanceLoopId))
                    local GeneratedPlan = TaskPlanner:GenerateTaskPlan(PetDataForPlanner, true)
                    PlanFormatter.Print(GeneratedPlan, PetDataForPlanner.unique, PlannerAilmentCategories)
                    
                    -- Attempt to execute the plan
                    local PetModel = GetPetModelByUniqueId(PetDataForPlanner.unique)
                    if PetModel then
                        ProcessTaskPlan(PetDataForPlanner.unique, PetModel, GeneratedPlan, AilmentActions)
                    else
                        warn("Could not find PetModel for " .. PetDataForPlanner.unique .. ". Skipping plan execution for this pet.")
                    end
                else
                    warn("TaskPlanner or PlanFormatter not loaded correctly. Cannot generate or print plan. (Loop ID: " .. currentInstanceLoopId .. ")")
                end
            end

        else
            if LoopCounter % 10 == 0 then 
                 print(os.date("%X") .. " - No current pet ailments detected for any pet. (Loop ID: " .. currentInstanceLoopId .. ")")
            end
        end
    else
        if LoopCounter % 30 == 0 then 
            print("PetFarm is INACTIVE (loop ID: " .. currentInstanceLoopId .. ", checked at " .. os.date("%X") .. ")")
        end
    end
end

-- Check if the loop exited due to ID mismatch or other reasons
if _G.PetFarmLoopInstanceId ~= currentInstanceLoopId then
    print("PetFarmOfficial.luau loop with ID: " .. currentInstanceLoopId .. " stopping as a new instance has started (new active ID: " .. tostring(_G.PetFarmLoopInstanceId) .. ").")
else
    print("PetFarmOfficial.luau loop with ID: " .. currentInstanceLoopId .. " stopping. If _G.PetFarmLoopInstanceId was manually cleared or script execution ended, this is expected.")
end


