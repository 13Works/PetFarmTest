local ReplicatedStorage = game:GetService("ReplicatedStorage")
local API = ReplicatedStorage:WaitForChild("API")

-- Dehash API
table.foreach(getupvalue(require(ReplicatedStorage.ClientModules.Core.RouterClient.RouterClient).init, 7), function(RemoteName, Hashedremote)
  if typeof(Hashedremote) ~= "Instance" then return end
  if Hashedremote.Parent ~= API then return end
  if not (Hashedremote:IsA("RemoteEvent") or Hashedremote:IsA("RemoteFunction")) then return end
  Hashedremote.Name = RemoteName
end)

local HttpService = game:GetService("HttpService")

local LocalPlayer = game:GetService("Players").LocalPlayer

-- Load Fsys and EquippedPets module
local Fsys = ReplicatedStorage:FindFirstChild("Fsys")
local EquippedPetsModule = nil
if Fsys then
    local loadSuccess, module = pcall(function()
        return require(Fsys).load("EquippedPets")
    end)
    if loadSuccess and module then
        EquippedPetsModule = module
        print("EquippedPets module loaded successfully.")
    else
        warn("Failed to load EquippedPets module:", module) -- 'module' here would be error message from pcall
    end
else
    warn("Fsys module loader not found in ReplicatedStorage. EquippedPets module cannot be loaded.")
end

-- Load external modules using HttpGet and loadstring
local TaskPlanner = loadstring(game:HttpGet(('https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/TaskPlanner.lua'), true))()
local PlanFormatter = loadstring(game:HttpGet(('https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/PlanFormatter.lua'), true))()

local SmartFurnitureMap = {}

local AILMENT_TO_FURNITURE_MODEL_MAP = {
    thirsty = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" },
    hungry = { "AilmentsRefresh2024CheapWaterBowl", "ailments_refresh_2024_cheap_water_bowl" },
    toilet = { "AilmentsRefresh2024LitterBox", "ailments_refresh_2024_litter_box" },
    dirty = { "ModernShower", "modernshower" },
    sleepy = { "BasicCrib", "basiccrib" }
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
    if not PetModel then
        warn("GetPetUniqueIdString: Called with a nil PetModel.")
        -- The caller (e.g., VerifyAilmentExists) checks for "stub_pet_unique_id_error".
        -- Returning this specific error string maintains consistency.
        return "stub_pet_unique_id_error"
    end

    -- Attempt 1: Use EquippedPetsModule if available and pet is equipped by local player
    -- This is preferred as PetModels in this script are often sourced via this module.
    if EquippedPetsModule then
        local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
        if EquippedWrappers then
            for _, Wrapper in ipairs(EquippedWrappers) do
                if Wrapper.char == PetModel then -- Direct model instance comparison
                    if Wrapper.pet_unique and type(Wrapper.pet_unique) == "string" then
                        -- Successfully found ID via EquippedPetsModule
                        return Wrapper.pet_unique
                    else
                        -- Found the PetModel in the wrapper, but its pet_unique is invalid.
                        -- Warn and let the function fall through to other methods.
                        warn(string.format("GetPetUniqueIdString: PetModel '%s' found in EquippedPetsModule, but its 'pet_unique' property is missing or not a string. Trying other methods.", PetModel.Name or "Unnamed"))
                    end
                end
            end
            -- If loop finishes, PetModel was not found among currently equipped pets known to EquippedPetsModule.
            -- This could happen if the PetModel is from another source (e.g., another player's pet, a world spawn not tied to local player's wrappers).
        else
            -- This case might indicate an issue with EquippedPetsModule itself or its state.
            warn("GetPetUniqueIdString: EquippedPetsModule.get_my_equipped_char_wrappers() returned nil or an empty list. Cannot check module for ID.")
        end
    else
        -- EquippedPetsModule not loaded; this might be normal in some environments or script setups.
        -- The function will proceed to try direct property access on the PetModel.
        -- No warning here to avoid spam if module is intentionally absent.
    end

    -- Attempt 2: Check for a direct 'unique' property on the PetModel itself
    -- This was the original stub's primary logic and serves as a good general fallback.
    if PetModel.unique and type(PetModel.unique) == "string" then
        return PetModel.unique
    end

    -- Attempt 3: Fallback to PetModel.Name if it's a string
    -- This is often not the correct ID format for APIs, so a warning is important.
    if PetModel.Name and type(PetModel.Name) == "string" then
        warn(string.format("GetPetUniqueIdString: Using PetModel.Name ('%s') as fallback for unique ID. This may not be the correct format for API calls.", PetModel.Name))
        return PetModel.Name
    end

    -- All attempts failed to find a string unique ID
    local petIdentifierDescription = "an unknown PetModel instance"
    if PetModel.Name and type(PetModel.Name) == "string" then
        petIdentifierDescription = string.format("PetModel named '%s'", PetModel.Name)
    elseif type(PetModel) == "Instance" then
        petIdentifierDescription = string.format("PetModel instance '%s'", PetModel:GetFullName())
    elseif PetModel then
         petIdentifierDescription = string.format("PetModel (type: %s, tostring: %s)", type(PetModel), tostring(PetModel))
    end

    warn(string.format("GetPetUniqueIdString: Could not determine a string unique ID for %s using any available method.", petIdentifierDescription))
    return "stub_pet_unique_id_error" -- Consistent error string for callers
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

    -- Iterate through container folders (e.g., "f-11", "f-14", or full path names if those are the direct children)
    for _, ContainerFolderInstance in ipairs(FurnitureFolder:GetChildren()) do
        -- Assuming container folders are actual Folder instances or Models that group other models.
        -- The critical part is that this ContainerFolderInstance should have the 'furniture_unique' attribute.
        if ContainerFolderInstance:IsA("Folder") or ContainerFolderInstance:IsA("Model") then 
            local UniqueNameFromContainer = ContainerFolderInstance:GetAttribute("furniture_unique")

            if UniqueNameFromContainer and type(UniqueNameFromContainer) == "string" then
                -- Now iterate through the actual furniture models *inside* this container
                for _, ActualFurnitureModel in ipairs(ContainerFolderInstance:GetChildren()) do
                    if ActualFurnitureModel:IsA("Model") or ActualFurnitureModel:IsA("BasePart") then
                        local LowercaseActualModelName = string.lower(ActualFurnitureModel.Name)
                        for _, Keyword in ipairs(Keywords) do
                            if string.find(LowercaseActualModelName, string.lower(Keyword)) then
                                -- Match found based on keyword for the ActualFurnitureModel
                                local VacantSeatInstance = nil
                                local UseBlocks = ActualFurnitureModel:FindFirstChild("UseBlocks")
                                if UseBlocks then
                                    local Seats = UseBlocks:GetChildren()
                                    if #Seats > 0 then
                                        VacantSeatInstance = Seats[1]
                                    end
                                end

                                warn(string.format("FindFirstAilmentFurniture: Found generic furniture. UniqueID (from container '%s'): '%s', ModelName (actual): '%s', For Ailment: '%s', Keyword: '%s', VacantSeat: %s",
                                    ContainerFolderInstance.Name, UniqueNameFromContainer, ActualFurnitureModel.Name, AilmentName, Keyword, VacantSeatInstance and VacantSeatInstance.Name or "nil"))
                                
                                return {
                                    name = UniqueNameFromContainer, 
                                    model = ActualFurnitureModel, 
                                    vacant_seat = VacantSeatInstance
                                }
                            end
                        end
                    end
                end
            else
                -- warn(string.format("FindFirstAilmentFurniture: Container folder '%s' is missing a valid 'furniture_unique' string attribute. Skipping its contents.", ContainerFolderInstance.Name))
            end
        end
    end
    
    warn("FindFirstAilmentFurniture: No suitable owned furniture found for ailment: " .. AilmentName .. " (matching keywords, within a container having 'furniture_unique', and with correct model structure).")
    return nil
end

-- Updated VerifyAilmentExists function
function VerifyAilmentExists(PetModel, AilmentName)
    if not PetModel then
        warn("VerifyAilmentExists: PetModel is nil.")
        return false
    end
    if not AilmentName then
        warn("VerifyAilmentExists: AilmentName is nil.")
        return false
    end

    local PetUniqueId = GetPetUniqueIdString(PetModel) 
    if not PetUniqueId or PetUniqueId == "stub_pet_unique_id_error" then
        warn("VerifyAilmentExists: Could not get a valid Unique ID for PetModel: " .. PetModel.Name .. ". Cannot verify ailment.")
        return false
    end

    local ClientDataModule = require(ReplicatedStorage.ClientModules.Core.ClientData)
    local PlayerData = ClientDataModule.get_data()[LocalPlayer.Name]

    if not PlayerData or 
       not PlayerData.ailments_manager or 
       not PlayerData.ailments_manager.ailments then
        warn("VerifyAilmentExists: Could not find ailment data path for LocalPlayer ('" .. LocalPlayer.Name .. "') in ClientData.")
        return false
    end

    local AllPetsAilmentInfo = PlayerData.ailments_manager.ailments
    local PetSpecificAilmentsInfo = AllPetsAilmentInfo[PetUniqueId]

    if PetSpecificAilmentsInfo and type(PetSpecificAilmentsInfo) == "table" then
        for _, AilmentDataEntry in pairs(PetSpecificAilmentsInfo) do
            if type(AilmentDataEntry) == "table" and AilmentDataEntry.kind == AilmentName then
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

    for Ailment, FurnitureData in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
        local ModelName = FurnitureData[1] -- ModelName is the first element (e.g., "ModernShower")
        -- Search recursively within the FurnitureFolder for this specific model name
        local ItemModel = FurnitureFolder:FindFirstChild(ModelName, true) 

        if ItemModel then
            -- The ItemModel found is the actual furniture (e.g., the "ModernShower" model).
            -- Its parent should be the container folder (e.g., "f-14").
            local ItemContainerFolder = ItemModel.Parent
            if ItemContainerFolder and ItemContainerFolder.Parent == FurnitureFolder then
                local UniqueName = ItemContainerFolder:GetAttribute("furniture_unique")
                if UniqueName and type(UniqueName) == "string" then
                    local VacantSeatInstance = nil
                    local UseBlocks = ItemModel:FindFirstChild("UseBlocks") -- Find UseBlocks in the ItemModel itself
                    if UseBlocks then
                        local Seats = UseBlocks:GetChildren()
                        if #Seats > 0 then
                            VacantSeatInstance = Seats[1]
                        end
                    end
                    FoundItems[Ailment] = {
                        name = UniqueName,       -- Unique ID from container folder's attribute
                        model = ItemModel,       -- The actual furniture model instance
                        vacant_seat = VacantSeatInstance
                    }
                    -- print(string.format("GetSmartFurniture: Found and processed smart furniture '%s' (Model: %s, Container: %s) for ailment '%s'", UniqueName, ItemModel.Name, ItemContainerFolder.Name, Ailment))
                else
                    warn(string.format("GetSmartFurniture: Smart furniture model '%s' found, its container '%s' is missing 'furniture_unique' attribute. Skipping for ailment '%s'.", ItemModel.Name, ItemContainerFolder.Name, Ailment))
                end
            else
                 warn(string.format("GetSmartFurniture: Found smart furniture model '%s', but its parent structure is unexpected or not directly under FurnitureFolder. Parent: %s. Skipping for ailment '%s'.", ItemModel.Name, ItemModel.Parent and ItemModel.Parent.Name or "nil", Ailment))
            end
        else
            -- warn(string.format("GetSmartFurniture: Smart furniture model '%s' not found recursively for ailment '%s'.", ModelName, Ailment))
        end
    end
    return FoundItems
end

local function InitializeSmartFurniture()
    local ClientDataModule = require(ReplicatedStorage.ClientModules.Core.ClientData)
    local FurnitureDB = require(ReplicatedStorage.ClientDB.Housing.FurnitureDB) -- Added FurnitureDB require

    local PlayerData = ClientDataModule.get_data()[LocalPlayer.Name]
    local CurrentMoney = nil
    if PlayerData and PlayerData.money then
        CurrentMoney = PlayerData.money
    else
        warn("InitializeSmartFurniture: Could not retrieve player money from ClientData. Cannot perform cost checks.")
        -- Decide if we proceed without money check or halt. For now, proceed but items might fail to buy if cost > 0 and money is effectively 0.
    end

    if not FurnitureDB then
        warn("InitializeSmartFurniture: FurnitureDB module not found or failed to load. Cannot perform cost checks or determine item costs.")
        -- If FurnitureDB is critical and missing, we might want to not even attempt purchases.
        -- For now, it will try to queue them, but they might fail if API expects valid kinds that DB would confirm.
    end

    local CurrentSmartFurnitureItems = GetSmartFurniture()
    local FurnitureFolder = workspace.HouseInteriors and workspace.HouseInteriors:FindFirstChild("furniture")

    if not FurnitureFolder then
        warn("InitializeSmartFurniture: workspace.HouseInteriors.furniture not found! Cannot process smart furniture.")
        SmartFurnitureMap = CurrentSmartFurnitureItems
        return
    end

    local ItemsToBuy = {}
    local ItemKindsToModelNames = {} -- Maps KindName to ModelName

    for Ailment, FurnitureData in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
        if not CurrentSmartFurnitureItems[Ailment] then
            local ModelName = FurnitureData[1] -- ModelName is the first element
            local KindName = FurnitureData[2]  -- KindName is the second element (unique key for FurnitureDB and purchase API)
            
            local CanAfford = true -- Assume can afford if money check is not possible or item is free
            local Cost = 0

            if FurnitureDB and CurrentMoney ~= nil then -- Only check cost if DB and money are available
                local ItemDBInfo = FurnitureDB[KindName]
                if ItemDBInfo and ItemDBInfo.cost then
                    Cost = ItemDBInfo.cost
                    if CurrentMoney < Cost then
                        CanAfford = false
                        warn(string.format("InitializeSmartFurniture: Cannot afford '%s' (model: %s) for ailment '%s'. Cost: %d, Player Money: %d.", KindName, ModelName, Ailment, Cost, CurrentMoney))
                    end
                else
                    warn(string.format("InitializeSmartFurniture: Could not find cost information for '%s' (model: %s) in FurnitureDB. Assuming it's free or data is missing.", KindName, ModelName))
                    -- If not in DB, it might be an old/invalid item or truly free. Proceed with caution.
                end
            elseif CurrentMoney == nil and FurnitureDB and FurnitureDB[KindName] and FurnitureDB[KindName].cost and FurnitureDB[KindName].cost > 0 then
                 warn(string.format("InitializeSmartFurniture: Player money not available, but '%s' (model: %s) has a cost in DB. Purchase might fail.", KindName, ModelName))
                 -- CanAfford remains true, letting the purchase attempt proceed and potentially fail server-side if money is an issue.
            end

            if CanAfford then
                table.insert(ItemsToBuy, { kind = KindName, properties = { cframe = CFrame.new(0, -1000, 0) } })
                ItemKindsToModelNames[KindName] = ModelName -- Map the provided KindName to its ModelName
                warn(string.format("InitializeSmartFurniture: Queuing purchase for '%s' (model: %s, cost: %d) for ailment '%s'. Player Money: %s", KindName, ModelName, Cost, Ailment, CurrentMoney or 'Unknown'))
            end
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
            local ModelNameToFind = ItemKindsToModelNames[BoughtItemInfo.kind] -- Look up ModelName using the KindName
            if ModelNameToFind then
                -- Search recursively for the newly bought item's model
                local NewItemModel = FurnitureFolder:FindFirstChild(ModelNameToFind, true) 
                
                if NewItemModel then
                    local ItemContainerFolder = NewItemModel.Parent
                    if ItemContainerFolder and ItemContainerFolder.Parent == FurnitureFolder then
                        local UniqueName = ItemContainerFolder:GetAttribute("furniture_unique")
                        if UniqueName and type(UniqueName) == "string" then
                            local VacantSeatInstance = nil
                            local UseBlocks = NewItemModel:FindFirstChild("UseBlocks") -- Find UseBlocks in the NewItemModel itself
                            if UseBlocks then
                                local Seats = UseBlocks:GetChildren()
                                if #Seats > 0 then
                                    VacantSeatInstance = Seats[1]
                                end
                            end
                            
                            local FurnitureObject = {
                                name = UniqueName,        -- Unique ID from container folder's attribute
                                model = NewItemModel,      -- The actual furniture model instance
                                vacant_seat = VacantSeatInstance
                            }

                            for Ailment, FurnitureDataInner in pairs(AILMENT_TO_FURNITURE_MODEL_MAP) do
                                local CurrentModelNameFromMap = FurnitureDataInner[1]
                                -- Check if the ModelName of the found item matches the ModelName for the Ailment in the map
                                if NewItemModel.Name == CurrentModelNameFromMap and not CurrentSmartFurnitureItems[Ailment] then
                                    CurrentSmartFurnitureItems[Ailment] = FurnitureObject -- Store the FurnitureObject
                                    warn(string.format("InitializeSmartFurniture: Successfully processed purchased item '%s' (Model: %s, Container: %s) for ailment '%s'.", UniqueName, NewItemModel.Name, ItemContainerFolder.Name, Ailment))
                                    break
                                end
                            end
                        else
                            warn(string.format("InitializeSmartFurniture: Found purchased model '%s' (Kind: %s), but its container '%s' is missing 'furniture_unique' string attribute. Cannot add to smart map.", NewItemModel.Name, BoughtItemInfo.kind, ItemContainerFolder.Name))
                        end
                    else
                        warn(string.format("InitializeSmartFurniture: Found purchased model '%s' (Kind: %s), but its parent structure is unexpected. Parent: %s. Cannot add to smart map.", NewItemModel.Name, BoughtItemInfo.kind, NewItemModel.Parent and NewItemModel.Parent.Name or "nil"))
                    end
                else
                    warn(string.format("InitializeSmartFurniture: Failed to find purchased item model '%s' (kind: %s) recursively in workspace after buying.", ModelNameToFind, BoughtItemInfo.kind))
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

function PlaceAndUseSitableAtCFrame(SitableFurnitureObject, TargetCFrame, PetModel)
  if not SitableFurnitureObject or not SitableFurnitureObject.name or not SitableFurnitureObject.model or not TargetCFrame then 
    warn(string.format("PlaceAndUseSitableAtCFrame: Invalid arguments. SitableFurnitureObject: %s, TargetCFrame: %s", tostring(SitableFurnitureObject), tostring(TargetCFrame)))
    return 
  end

  API["HousingAPI/PushFurnitureChanges"]:FireServer({
    [1] = {
      ["unique"] = SitableFurnitureObject.name, -- Use name from FurnitureObject (furniture_unique attribute)
      ["cframe"] = TargetCFrame
    }
  })

  task.wait() -- Consider if this wait is always optimal or if it can be context-dependent

  local SeatToUse = "UseBlock" -- Default seat name
  if SitableFurnitureObject.vacant_seat and SitableFurnitureObject.vacant_seat.Name then -- Assuming the seat instance itself has a .Name property
    SeatToUse = SitableFurnitureObject.vacant_seat.Name
    -- print(string.format("PlaceAndUseSitableAtCFrame: Using specific vacant seat '%s' for furniture '%s'", SeatToUse, SitableFurnitureObject.name))
  else
    -- print(string.format("PlaceAndUseSitableAtCFrame: Using default seat 'UseBlock' for furniture '%s' as no specific VacantSeat was identified in FurnitureObject.", SitableFurnitureObject.name))
  end

  API["HousingAPI/ActivateFurniture"]:InvokeServer(
    LocalPlayer,
    SitableFurnitureObject.name,    -- Use name from FurnitureObject
    SeatToUse,                      -- Use identified or default seat name
    {["cframe"] = TargetCFrame},
    PetModel                        -- Pass the PetModel as the target for activation
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

-- Updated GetPetModelByUniqueId function
local function GetPetModelByUniqueId(PetUniqueId)
    if not EquippedPetsModule then
        warn("GetPetModelByUniqueId: EquippedPetsModule is not loaded. Cannot fetch pet model.")
        return nil
    end

    if not PetUniqueId then
        warn("GetPetModelByUniqueId: PetUniqueId is nil.")
        return nil
    end

    local wrapper = EquippedPetsModule.get_wrapper_from_unique(PetUniqueId, LocalPlayer)

    if wrapper then
        local PetModel = wrapper.char
        if PetModel and PetModel:IsA("Model") then
            -- print("GetPetModelByUniqueId: Found model for " .. PetUniqueId .. ":", PetModel:GetFullName())
            return PetModel
        else
            warn("GetPetModelByUniqueId: Wrapper found for " .. PetUniqueId .. ", but .char (PetModel) is missing or not a Model.")
            return nil
        end
    else
        -- This warning might be spammy if pets are legitimately not equipped or if ID is for an unequipped pet.
        -- Consider if this level of warning is always needed or if it should be more subtle for non-critical failures.
        -- For now, keeping it to indicate that the system tried and failed for this ID.
        warn("GetPetModelByUniqueId: No wrapper found for unique ID: " .. PetUniqueId .. ". Pet might not be equipped or ID is invalid.")
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
        -- print("GetMyEquippedPetModels: No pet char wrappers found for local player. No pets appear to be equipped.")
        return PetModels
    end

    -- print("GetMyEquippedPetModels: Found", #EquippedWrappers, "equipped pet wrapper(s).")

    for _, Wrapper in ipairs(EquippedWrappers) do
        local PetModel = Wrapper.char
        if PetModel and PetModel:IsA("Model") then
            table.insert(PetModels, PetModel)
        else
            local PetUniqueId = Wrapper.pet_unique
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

    local EquippedWrappers = EquippedPetsModule.get_my_equipped_char_wrappers()
    local PetUniqueIds = {}

    if not EquippedWrappers or #EquippedWrappers == 0 then
        -- print("GetMyEquippedPetUniques: No pet char wrappers found for local player. No pets appear to be equipped.")
        return PetUniqueIds
    end

    for _, Wrapper in ipairs(EquippedWrappers) do
        local PetUniqueId = Wrapper.pet_unique
        if PetUniqueId and type(PetUniqueId) == "string" then
            table.insert(PetUniqueIds, PetUniqueId)
        else
            warn("GetMyEquippedPetUniques: Wrapper found but pet_unique ID is missing or not a string.")
        end
    end
    return PetUniqueIds
end

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


