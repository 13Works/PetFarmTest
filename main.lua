--/PetFarmOfficial.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Ad = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/Ad.lua"), true))()
local TaskPlanner = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/TaskPlanner.lua"), true))()
local PlanFormatter = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/PlanFormatter.lua"), true))()

local AILMENTS = {
  ["BORED"] = "bored", ["BEACH_PARTY"] = "beach_party", ["CAMPING"] = "camping", 
  ["DIRTY"] = "dirty", ["HUNGRY"] = "hungry", ["SICK"] = "sick", 
  ["SLEEPY"] = "sleepy", ["SALON"] = "salon", ["SCHOOL"] = "school", 
  ["PIZZA_PARTY"] = "pizza_party", ["THIRSTY"] = "thirsty", ["PLAY"] = "play",
  ["TOILET"] = "toilet", ["RIDE"] = "ride", ["WALK"] = "walk", ["MYSTERY"] = "not_implemented"
}
local TIMEOUTS = {["DEFAULT"] = 50, ["CONSUMABLE"] = 25, ["INTERACTION"] = 30, ["LOCATION"] = 50, ["MOVEMENT"] = 40}
local ITEMS = {["FOOD"] = "teachers_apple", ["DRINK"] = "water", ["HEALING"] = "healing_apple"}
local FURNITURE_IDS = {["DOCTOR_INTERACTION"] = "f-14"}
local GAME_LOCATIONS = {
  ["PARK_BORED_TARGET_PATH"] = {"StaticMap", "Park", "BoredAilmentTarget"},
  ["BEACH_PARTY_TARGET_PATH"] = {"StaticMap", "Beach", "BeachPartyAilmentTarget"},
  ["CAMPSITE_ORIGIN_PATH"] = {"StaticMap", "Campsite", "CampsiteOrigin"},
}
local MISC_STRINGS = {["PET_OBJECT_CREATOR_TYPE"] = "__Enum_PetObjectCreatorType_1", ["THROW_TOY_REACTION"] = "ThrowToyReaction"}

local function GetCFrameFromPathParts(PathParts)
  local CurrentObject = workspace

  for _, PartName in PathParts do
    CurrentObject = CurrentObject:FindFirstChild(PartName)
    if not CurrentObject then
      warn(string.format("GetCFrameFromPathParts: Could not find %s at %s", table.concat(PathParts, "."), PartName))
      return nil
    end
  end

  return CurrentObject and CurrentObject.CFrame
end

local function NewAilmentAction(Config)
  -- Expected Config fields:
  -- AilmentName (string, required): The canonical name of the ailment.
  -- ActionType (string, optional): e.g., "Standard", "Smart". Used for logging.
  -- CoreAction (function(PetModel, TargetCFrame_or_nil), required): The unique logic for this action.
  -- RequiresTargetCFrame (boolean, default false): If true, expects TargetCFrame as the first arg after PetModel.
  -- DefaultTimeout (number, default TIMEOUTS.DEFAULT): Timeout for Ad:execute_action_with_timeout.
  -- PreCoreAction (function(PetModel) -> boolean, optional): Runs before CoreAction. If it returns false, CoreAction is skipped.
  -- PostExecutionAction (function(PetModel), optional): Runs after WaitForCompletion logic or non-awaited initiation.
  -- OnTimeoutFailure (function(PetModel), optional): Callback if Ad:execute_action_with_timeout fails.
  -- NonAwaitedExecutionType (string, "spawn" or "pcall", default "pcall"): How to run CoreAction if not WaitForCompletion.

  local ActionFullName = Config.AilmentName
  if Config.ActionType then
    ActionFullName = Config.AilmentName .. "." .. Config.ActionType
  end

  return function(PetModel, ...)
    local Args = { ... }
    local WaitForCompletion
    local TargetCFrame

    if Config.RequiresTargetCFrame then
      TargetCFrame = Args[1]
      WaitForCompletion = Args[2]
      if TargetCFrame == nil and WaitForCompletion == nil and #Args == 1 and typeof(Args[1]) == "boolean" then
        -- Smart action called without TargetCFrame, but with WaitForCompletion
        warn(string.format("AilmentActions.%s: Called as Smart action but TargetCFrame might be missing. Assuming WaitForCompletion is arg1.", ActionFullName))
        WaitForCompletion = Args[1]
        TargetCFrame = nil -- Explicitly nil, CoreAction must handle
      elseif TargetCFrame == nil and Config.RequiresTargetCFrame then
        warn(string.format("AilmentActions.%s: TargetCFrame is required but not provided or is nil.", ActionFullName))
        -- Depending on strictness, you might return here or let CoreAction handle nil TargetCFrame
      end
    else
      WaitForCompletion = Args[1]
    end

    local OuterPcallSuccess, OuterErrorMessage = pcall(function()
      local CompleteCoreLogic = function()
        if Config.PreCoreAction then
          local PreSuccess, PreResult = pcall(function()
            return Config.PreCoreAction(PetModel)
          end)
          if not PreSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.%s: Error in PreCoreAction: %s", ActionFullName, PreResult))
            return false
          end
          if PreResult == false then
            warn(string.format("PetFarmOfficial.AilmentActions.%s: PreCoreAction indicated failure to proceed.", ActionFullName))
            return false
          end
        end

        local CoreArgs = { PetModel }
        if Config.RequiresTargetCFrame then
          table.insert(CoreArgs, TargetCFrame)
        end

        local CoreSuccess, CoreResult = pcall(function()
          -- Pass PetModel, then TargetCFrame (if applicable), then Config
          local FinalCoreArgs = {}
          for _, Arg in ipairs(CoreArgs) do table.insert(FinalCoreArgs, Arg) end
          table.insert(FinalCoreArgs, Config) -- Add Config as the last argument
          return Config.CoreAction(table.unpack(FinalCoreArgs))
        end)
        if not CoreSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.%s: Error in CoreAction: %s", ActionFullName, CoreResult))
          return false
        end
        return CoreResult ~= false -- Propagate explicit 'false' from CoreAction, else true
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, Config.AilmentName) then
          print(string.format("AilmentActions.%s: Ailment '%s' not present for pet '%s' before action.", ActionFullName, Config.AilmentName, Ad:get_pet_unique_id_string(PetModel)))
          return
        end

        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(
          PetModel,
          Config.AilmentName,
          Config.DefaultTimeout or TIMEOUTS.DEFAULT,
          nil,
          CompleteCoreLogic
        )

        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.%s: %s", ActionFullName, ResultMessage))
          if Config.OnTimeoutFailure then
            Config.OnTimeoutFailure(PetModel)
          end
        else
          print(string.format("PetFarmOfficial.AilmentActions.%s: %s", ActionFullName, ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, Config.AilmentName) then
          print(string.format("AilmentActions.%s: Ailment '%s' not present for pet '%s' before non-awaited action.", ActionFullName, Config.AilmentName, Ad:get_pet_unique_id_string(PetModel)))
          return
        end

        local ExecutionType = Config.NonAwaitedExecutionType or "pcall"
        if ExecutionType == "spawn" then
          task.spawn(CompleteCoreLogic)
        else
          local Success, Result = pcall(CompleteCoreLogic)
          if not Success then
            warn(string.format("PetFarmOfficial.AilmentActions.%s: Error during non-awaited pcall execution: %s", ActionFullName, tostring(Result)))
          elseif Result == false then
            warn(string.format("PetFarmOfficial.AilmentActions.%s: Non-awaited pcall execution indicated failure.", ActionFullName))
          end
        end
      end

      if Config.PostExecutionAction then
        local PostSuccess, PostErr = pcall(function()
          Config.PostExecutionAction(PetModel)
        end)
        if not PostSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.%s: Error in PostExecutionAction: %s", ActionFullName, PostErr))
        end
      end
    end)

    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking '%s' ailment action: %s", ActionFullName, OuterErrorMessage or "Unknown error"))
    end
  end
end

local function FurnitureCoreAction(PetModel, Config)
  local FurnitureItem = Ad:retrieve_smart_furniture(Config.AilmentName, true, true)
  if not FurnitureItem then
    warn(string.format("PetFarmOfficial.AilmentActions.%s: No suitable furniture asset found for ailment: %s", Config.AilmentName, Config.AilmentName))
    warn("Attempting to check at home...")
    Ad:go_home()
    task.wait(0.5)
    FurnitureItem = Ad:retrieve_smart_furniture(Config.AilmentName, true, true)
    if not FurnitureItem then
      warn(string.format("PetFarmOfficial.AilmentActions.%s: No suitable furniture asset found for ailment: %s", Config.AilmentName, Config.AilmentName))
      return
    end
  end
  warn(string.format("PetFarmOfficial.AilmentActions.%s: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", Config.AilmentName, FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
  Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
end

local AilmentActions = {
  [AILMENTS.BORED] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.BORED;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["PreCoreAction"] = Ad.teleport_to_main_map;
    ["CoreAction"] = function(PetModel, Config)
      local TargetCFrame = GetCFrameFromPathParts(GAME_LOCATIONS.PARK_BORED_TARGET_PATH)
      Ad:handle_main_map_ailment(TargetCFrame, PetModel)
    end;
  };
  [AILMENTS.BEACH_PARTY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.BEACH_PARTY;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["PreCoreAction"] = Ad.teleport_to_main_map;
    ["CoreAction"] = function(PetModel, Config)
      local TargetCFrame = GetCFrameFromPathParts(GAME_LOCATIONS.BEACH_PARTY_TARGET_PATH)
      Ad:handle_main_map_ailment(TargetCFrame, PetModel)
    end;
  };
  [AILMENTS.CAMPING] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.CAMPING;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["PreCoreAction"] = Ad.teleport_to_main_map;
    ["CoreAction"] = function(PetModel, Config)
      local TargetCFrame = GetCFrameFromPathParts(GAME_LOCATIONS.CAMPSITE_ORIGIN_PATH)
      Ad:handle_main_map_ailment(TargetCFrame, PetModel)
    end;
  };
  [AILMENTS.HUNGRY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.HUNGRY;
    ["DefaultTimeout"] = TIMEOUTS.CONSUMABLE;
    ["CoreAction"] = function(PetModel, Config)
      Ad:purchase_and_consume_item(PetModel, ITEMS.FOOD)
    end;
  };
  [AILMENTS.THIRSTY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.THIRSTY;
    ["DefaultTimeout"] = TIMEOUTS.CONSUMABLE;
    ["CoreAction"] = function(PetModel, Config)
      Ad:purchase_and_consume_item(PetModel, ITEMS.DRINK)
    end;
  };
  [AILMENTS.SICK] = {
    ["Smart"] = NewAilmentAction {
      ["AilmentName"] = AILMENTS.SICK;
      ["DefaultTimeout"] = TIMEOUTS.INTERACTION;
      ["ActionType"] = "Smart";
      ["CoreAction"] = function(PetModel)
        Ad:teleport_to_ailment_location("Hospital")
        task.wait(1)
        Ad.__api.housing.activate_interior_furniture(FURNITURE_IDS.DOCTOR_INTERACTION, "UseBlock", "Yes", LocalPlayer.Character)
      end;
    };
    ["Standard"] = NewAilmentAction {
      ["AilmentName"] = AILMENTS.SICK;
      ["DefaultTimeout"] = TIMEOUTS.CONSUMABLE;
      ["ActionType"] = "Standard";
      ["CoreAction"] = function(PetModel)
        Ad:purchase_and_consume_item(PetModel, ITEMS.HEALING)
      end;
    };
  };
  [AILMENTS.SALON] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.SALON;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["CoreAction"] = function(PetModel)
      Ad:teleport_to_ailment_location("Salon")
    end;
  };
  [AILMENTS.SCHOOL] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.SCHOOL;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["CoreAction"] = function(PetModel)
      Ad:teleport_to_ailment_location("School")
    end;
  };
  [AILMENTS.PIZZA_PARTY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.PIZZA_PARTY;
    ["DefaultTimeout"] = TIMEOUTS.LOCATION;
    ["CoreAction"] = function(PetModel)
      Ad:teleport_to_ailment_location("PizzaShop")
    end;
  };
  [AILMENTS.SLEEPY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.SLEEPY;
    ["DefaultTimeout"] = TIMEOUTS.INTERACTION;
    ["CoreAction"] = FurnitureCoreAction;
  };
  [AILMENTS.DIRTY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.DIRTY;
    ["DefaultTimeout"] = TIMEOUTS.INTERACTION;
    ["CoreAction"] = FurnitureCoreAction;
  };
  [AILMENTS.TOILET] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.TOILET;
    ["DefaultTimeout"] = TIMEOUTS.INTERACTION;
    ["CoreAction"] = FurnitureCoreAction;
  };
  [AILMENTS.PLAY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.PLAY;
    ["DefaultTimeout"] = TIMEOUTS.INTERACTION;
    ["CoreAction"] = function(PetModel, CancelToken)
      local ToyUnique = Ad:get_default_throw_toy_unique()
      if not ToyUnique then return end
      -- Throw the toy every 4 seconds until the task is complete or cancelled
      while Ad:verify_ailment_exists(PetModel, "play") and not (CancelToken and CancelToken.ShouldStop) do
        local Success, Result = pcall(function()
          Ad.__api.pet_object.create_pet_object(
            MISC_STRINGS.PET_OBJECT_CREATOR_TYPE, 
            {
              ["reaction_name"] = MISC_STRINGS.THROW_TOY_REACTION, 
              ["unique_id"] = ToyUnique
            }
          )
        end)
        if not Success then
          warn("AilmentActions.play: Failed to throw toy:", Result)
        end
        for _ = 1, 40 do -- Wait up to 4 seconds, but break early if task is done
          if not Ad:verify_ailment_exists(PetModel, "play") or (CancelToken and CancelToken.ShouldStop) then break end
          task.wait(0.1)
        end
      end
      -- Unequip the toy after the task is complete
      local UnequipSuccess, UnequipResult = pcall(function()
        Ad.__api.tool.unequip(ToyUnique, {["use_sound_delay"] = false, ["equip_as_last"] = false})
      end)
      if not UnequipSuccess then
        warn("AilmentActions.play: Failed to unequip toy:", UnequipResult)
      end
    end;
  };
  [AILMENTS.RIDE] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.RIDE;
    ["DefaultTimeout"] = TIMEOUTS.MOVEMENT;
    ["CoreAction"] = function(PetModel, CancelToken)
      local StrollerUnique = Ad:get_default_stroller_unique()
      if not StrollerUnique then return end
      local EquipSuccess, EquipResult = pcall(function()
        Ad.__api.tool.equip(StrollerUnique)
      end)
      if not EquipSuccess then
        warn("AilmentActions.ride: Failed to equip stroller:", EquipResult)
        return
      end
      -- Wait for the stroller tool to appear in the player's character
      local Character = LocalPlayer.Character
      local StrollerTool = nil
      for _ = 1, 40 do -- up to 4 seconds
        StrollerTool = Character and Character:FindFirstChild("StrollerTool")
        if StrollerTool then break end
        task.wait(0.1)
      end
      if not StrollerTool then
        warn("AilmentActions.ride: StrollerTool not found in character after equip.")
        return
      end
      local ModelHandle = StrollerTool:FindFirstChild("ModelHandle")
      if not ModelHandle then
        warn("AilmentActions.ride: ModelHandle not found in StrollerTool.")
        return
      end
      local TouchToSits = ModelHandle:FindFirstChild("TouchToSits")
      if not TouchToSits then
        warn("AilmentActions.ride: TouchToSits not found in ModelHandle.")
        return
      end
      local TouchToSit = nil
      for _, obj in TouchToSits:GetChildren() do
        if obj.Name == "TouchToSit" then
          TouchToSit = obj
          break
        end
      end
      if not TouchToSit then
        warn("AilmentActions.ride: No TouchToSit found in TouchToSits.")
        return
      end
      local UseSuccess, UseResult = pcall(function()
        Ad.__api.adopt.use_stroller(LocalPlayer, PetModel, TouchToSit)
      end)
      if not UseSuccess then
        warn("AilmentActions.ride: Failed to use stroller:", UseResult)
        return
      end
      -- Set humanoid state to jumping until the ride task is over or cancelled
      local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
      if not Humanoid then
        warn("AilmentActions.ride: Humanoid not found in character.")
        return
      end
      while Ad:verify_ailment_exists(PetModel, "ride") and not (CancelToken and CancelToken.ShouldStop) do
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.5)
      end
      -- Unequip the stroller after the task is complete
      local UnequipSuccess, UnequipResult = pcall(function()
        Ad.__api.tool.unequip(StrollerUnique, {["use_sound_delay"] = false, ["equip_as_last"] = false})
      end)
      if not UnequipSuccess then
        warn("AilmentActions.ride: Failed to unequip stroller:", UnequipResult)
      end
    end;
  };
  [AILMENTS.WALK] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.WALK;
    ["DefaultTimeout"] = TIMEOUTS.MOVEMENT;
    ["CoreAction"] = function(PetModel, CancelToken)
      -- Hold the pet
      local HoldSuccess, HoldError = pcall(function()
        Ad.__api.adopt.hold_baby(PetModel)
      end)
      if not HoldSuccess then
        warn("AilmentActions.walk: Failed to hold pet:", HoldError)
        return
      end
      -- Wait for the walk ailment to clear or be cancelled
      local Character = LocalPlayer.Character
      local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
      if not Humanoid then
        warn("AilmentActions.walk: Humanoid not found in character.")
        return
      end
      while Ad:verify_ailment_exists(PetModel, "walk") and not (CancelToken and CancelToken.ShouldStop) do
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.5)
      end
      -- Drop the pet
      local EjectSuccess, EjectError = pcall(function()
        Ad.__api.adopt.eject_baby(PetModel)
      end)
      if not EjectSuccess then
        warn("AilmentActions.walk: Failed to drop pet:", EjectError)
      end
    end;
  };
  [AILMENTS.MYSTERY] = NewAilmentAction {
    ["AilmentName"] = AILMENTS.MYSTERY;
    ["DefaultTimeout"] = TIMEOUTS.CONSUMABLE;
    ["CoreAction"] = function(PetModel)
      print("AilmentActions.mystery: Not implemented")
    end;
  };
}

-- [[ FUNCTION TO PROCESS TASK PLAN - TO BE EXPANDED ]] --
--[[
  @param self table -- The table that contains the function
  @param PetUniqueId string -- The unique ID of the pet
  @param PetModel table -- The pet model
  @param GeneratedPlan table -- The generated plan
  @param AllAilmentActions table -- The all ailment actions
  @param OriginalAilmentsFlatList table -- The original ailments flat list
]]
-- [[ FUNCTION TO PROCESS TASK PLAN - REVISED ]] --
local function ProcessTaskPlan(PetUniqueId, PetModel, GeneratedPlan, AllAilmentActions, OriginalAilmentsFlatList)
  print(string.format("--- Starting Task Plan Execution for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
  if not GeneratedPlan or #GeneratedPlan == 0 then
    print(string.format("ProcessTaskPlan: No tasks in the generated plan for %s. Initial ailments: [%s]", PetUniqueId, table.concat(OriginalAilmentsFlatList or {}, ", ")))
    print(string.format("--- Finished Task Plan Execution for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
    return -- Exit early if no plan
  end

  print(string.format("  Initial ailments for this plan: [%s]", table.concat(OriginalAilmentsFlatList or {}, ", ")))

  -- Initialize SmartFurnitureMap once if needed
  if next(Ad.SmartFurnitureMap) == nil then
    Ad:initialize_smart_furniture()
  end

  local Running = {}
  local Completed = {}

  for TaskIndex, TaskData in GeneratedPlan do
    coroutine.wrap(function()
      local AilmentName = TaskData.ailment
      local WaitForAilment = TaskData.wait_for_ailment_completion

      if WaitForAilment then
        while not Completed[WaitForAilment] do
          task.wait(0.2)
        end
      end

      print(string.format("    [Task] Starting: %s (type: %s)", tostring(AilmentName), tostring(TaskData.Type)))
      local ActionTable = AllAilmentActions[AilmentName]
      local PotentialAction = typeof(ActionTable) == "table" and ActionTable.Standard or ActionTable
      if not PotentialAction or typeof(PotentialAction) ~= "function" then
        warn(string.format("    No executable action function found for ailment '%s' (TaskType: %s).", AilmentName, TaskData.Type))
        Completed[AilmentName] = true
        return
      end

      local CancelToken = nil
      if table.find({AILMENTS.RIDE, AILMENTS.WALK, AILMENTS.PLAY}, AilmentName) then
        CancelToken = {["ShouldStop"] = false}
      end

      local Success, ErrorMessage = pcall(PotentialAction, PetModel, CancelToken)
      if not Success then
        warn(string.format("    Error executing action '%s': %s", AilmentName, tostring(ErrorMessage)))
      else
        print(string.format("    Action completed for: %s", AilmentName))
      end

      if CancelToken then
        CancelToken.ShouldStop = true
      end

      Completed[AilmentName] = true
    end)()
  end

  local StartTime = os.clock()
  local TimeoutSeconds = TIMEOUTS.DEFAULT * 3
  local AllDone
  
  while true do
    AllDone = true

    for _, TaskData in GeneratedPlan do
      if Completed[TaskData.task_id] then continue end
      AllDone = false; break
    end

    if AllDone then break end
    task.wait(0.2)

    if os.clock() - StartTime > TimeoutSeconds then
      warn(string.format("ProcessTaskPlan: Timed out waiting for all tasks to complete for Pet: %s (%s)", PetModel["Name"], PetUniqueId))
      break
    end
  end

  -- Checking unresolved ailments
  if OriginalAilmentsFlatList and #OriginalAilmentsFlatList > 0 then
    print(string.format("--- Checking unresolved ailments for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
    local UnresolvedCount = 0
    for _, CurrentAilmentName in ipairs(OriginalAilmentsFlatList) do
      if Ad:verify_ailment_exists(PetModel, CurrentAilmentName) then
        UnresolvedCount = UnresolvedCount + 1
        warn(string.format("  FLAGGED: Initial ailment '%s' for pet '%s' was NOT resolved by the plan.", CurrentAilmentName, PetUniqueId))
      end
    end
    if UnresolvedCount == 0 then
      print("  All initial ailments for this plan were successfully resolved.")
    else
      print(string.format("  Total unresolved ailments from initial plan: %d", UnresolvedCount))
    end
  end

  print(string.format("--- Finished Task Plan Execution for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
  return true
end
-- [[ END FUNCTION TO PROCESS TASK PLAN ]] --

-- Main loop to monitor _G.PetFarm
local CurrentInstanceLoopId = HttpService:GenerateGUID(false)
_G.PetFarmLoopInstanceId = CurrentInstanceLoopId
print(string.format("PetFarmOfficial.luau loop started with ID: %s. To stop this specific loop instance if script is re-run, simply re-run the script. To pause operations, set _G.PetFarm = false.", CurrentInstanceLoopId))

Ad:setup_safety_platforms()

local LoopCounter = 0
local IsEquippedPetsModuleReportingNoPets = false

while _G.PetFarmLoopInstanceId == CurrentInstanceLoopId and task.wait(10) do
  LoopCounter = LoopCounter + 1
  if _G.PetFarm == true then
    if LoopCounter % 5 == 0 and not IsEquippedPetsModuleReportingNoPets then 
      print(string.format("%s - PetFarm is ACTIVE (loop ID: %s, checked at %s)", os.date("%X"), CurrentInstanceLoopId, os.date("%X")))
    end

    local CurrentEquippedPetUniqueIds = Ad:get_my_equipped_pet_uniques()

    if #CurrentEquippedPetUniqueIds == 0 then
      if not IsEquippedPetsModuleReportingNoPets then
        warn(string.format("%s - PetFarm CRITICAL WARNING: EquippedPetsModule is reporting NO equipped pets. All PetFarm operations requiring pet models will be paused until the module provides pet data. (Loop ID: %s)", os.date("%X"), CurrentInstanceLoopId))
        IsEquippedPetsModuleReportingNoPets = true
      elseif LoopCounter % 10 == 0 then 
        warn(string.format("%s - PetFarm INFO: EquippedPetsModule continues to report NO equipped pets. Operations remain paused. (Loop ID: %s)", os.date("%X"), CurrentInstanceLoopId))
      end
    else 
      if IsEquippedPetsModuleReportingNoPets then
        print(string.format("%s - PetFarm INFO: EquippedPetsModule is NOW reporting equipped pets (%d found). Resuming normal operations. (Loop ID: %s)", os.date("%X"), #CurrentEquippedPetUniqueIds, CurrentInstanceLoopId))
        IsEquippedPetsModuleReportingNoPets = false 
      end

      -- print(os.date("%X") .. " - DEBUG: Equipped Pet Unique IDs from Module: [" .. table.concat(CurrentEquippedPetUniqueIds, ", ") .. "] (Loop ID: " .. CurrentInstanceLoopId .. ")")

      local AllPetsAilmentsData = Ad:get_current_ailments()
      local PlannerAilmentCategories = TaskPlanner:GetAilmentCategories() 

      if #AllPetsAilmentsData > 0 then
        print(string.format("%s - Raw Detected Pet Ailments Report (Loop ID: %s):", os.date("%X"), CurrentInstanceLoopId))
        for _, PetRawDataEntry in AllPetsAilmentsData do
          print(string.format("  Pet Unique ID: %s, Ailments: [%s]", PetRawDataEntry["unique"], table.concat(PetRawDataEntry["ailments"], ", ")))
        end
        print("---") 

        for _, PetRawData in AllPetsAilmentsData do
          local PetUniqueId = PetRawData["unique"]
          local PetModel = Ad:get_pet_model_by_unique_id(PetUniqueId)
          local ShouldProcessPet = true 

          if not PetModel then
            warn(string.format("PetFarm: Pet '%s' has ailments but its model was not found via EquippedPetsModule. Attempting to equip... (Loop ID: %s)", PetUniqueId, CurrentInstanceLoopId))
            Ad.__api.tool.equip(PetUniqueId, {["use_sound_delay"] = false, ["equip_as_last"] = false})
            task.wait(3) 

            PetModel = Ad:get_pet_model_by_unique_id(PetUniqueId) 

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

            for _, AilmentName in PetRawData["ailments"] do
              local FoundCategory = false
              for CategoryName, CategoryData in PlannerAilmentCategories do
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

              local Success, ErrorMessage = pcall(function()
                ProcessTaskPlan(PetDataForPlanner["unique"], PetModel, GeneratedPlan, AilmentActions, PetRawData["ailments"])
              end)
              if not Success then
                warn(string.format("Error processing task plan for pet '%s': %s", PetDataForPlanner["unique"], ErrorMessage))
              end
            else
              warn(string.format("TaskPlanner or PlanFormatter not loaded correctly. Cannot generate or print plan. (Loop ID: %s)", CurrentInstanceLoopId))
            end
          end
        end

      else
        if LoopCounter % 10 == 0 then 
          print(string.format("%s - No current pet ailments detected for any pet (and module is reporting pets). (Loop ID: %s)", os.date("%X"), CurrentInstanceLoopId))
        end
      end
    end 
  else
    if LoopCounter % 30 == 0 then 
      print(string.format("%s - PetFarm is INACTIVE (loop ID: %s, checked at %s)", os.date("%X"), CurrentInstanceLoopId, os.date("%X")))
    end
  end
end

if _G.PetFarmLoopInstanceId ~= CurrentInstanceLoopId then
  print(string.format("PetFarmOfficial.luau loop with ID: %s stopping as a new instance has started (new active ID: %s).", CurrentInstanceLoopId, tostring(_G.PetFarmLoopInstanceId)))
  return
end

print(string.format("PetFarmOfficial.luau loop with ID: %s stopping. If _G.PetFarmLoopInstanceId was manually cleared or script execution ended, this is expected.", CurrentInstanceLoopId))
