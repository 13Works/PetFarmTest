--!strict

-- TaskPlanner.luau - Optimized Pet Care Task Planning Module

return {
  -- Module state / properties
  ["AILMENT_CONFIG"] = nil;
  ["LOCATION_CAPABILITIES"] = nil;
  ["TestScenarioConfig"] = nil;
  ["RandomPetCounter"] = 0;

  ["SetTestScenario"] = function(self, Config)
    self.TestScenarioConfig = Config
  end;

  ["ClearTestScenario"] = function(self)
    self.TestScenarioConfig = nil
  end;

  ["GetAilmentCategories"] = function(self) 
    if self.AILMENT_CONFIG then return self.AILMENT_CONFIG end

    self.AILMENT_CONFIG = {
      location = {
        sick = {job_type = "location", time = 2},
        salon = {job_type = "location", time = 20},
        school = {job_type = "location", time = 20},
        pizza_party = {job_type = "location", time = 20},
      },
      feeding = {
        hungry = {job_type = "consume", time = 5},
        thirsty = {job_type = "consume", time = 5},
      },
      playful = {
        walk = {job_type = "play", time = 15},
        pet_me = {job_type = "play", time = 5},
        ride = {job_type = "play", time = 15},
        play = {job_type = "play", time = 8},
      },
      static = {
        sleepy = {job_type = "sit", time = 10},
        dirty = {job_type = "sit", time = 10},
        toilet = {job_type = "sit", time = 10},
      },
      hybrid = {
        bored = {location_method = {job_type = "location", time = 20}, static_method = {job_type = "sit", time = 20}},
        camping = {location_method = {job_type = "location", time = 20}, static_method = {job_type = "sit", time = 20}},
        beach_party = {location_method = {job_type = "location", time = 20}, static_method = {job_type = "sit", time = 20}}
      },
      meta_tasks = { 
        choice_resolver = {job_type = "CHOICE_HANDLER", time = 0} 
      }
    }
    return self.AILMENT_CONFIG
  end;

  ["GetLocationCapabilities"] = function(self) 
    if self.LOCATION_CAPABILITIES then return self.LOCATION_CAPABILITIES end

    self.LOCATION_CAPABILITIES = {
      salon = {"sleepy", "hungry", "thirsty", "pet_me", "play", "walk", "ride"},
      hospital = {"sleepy", "thirsty", "hungry", "pet_me", "play", "walk", "ride"},
      school = {"sleepy", "hungry", "thirsty", "pet_me", "play", "walk", "ride"},
      camping = {"sleepy", "hungry", "thirsty", "pet_me", "play", "walk", "ride"},
      bored = {"hungry", "thirsty", "pet_me", "play", "walk", "ride"},
      beach_party = {"hungry", "thirsty", "pet_me", "play", "walk", "ride"},
      pizza_party = {"hungry", "thirsty", "pet_me", "play", "walk", "ride"},
    }
    return self.LOCATION_CAPABILITIES
  end;

  ["OptimizeHybridAilments"] = function(self, PetData)
    local Configuration = self:GetAilmentCategories()
    local Capabilities = self:GetLocationCapabilities()
    local Result = {
      unique = PetData.unique,
      ailments = {
        location = {}, 
        feeding = {}, 
        playful = {}, 
        static = {}, 
        meta_tasks = {}, 
        unknown = {}
      },
      staticHybridParallelInfo = {} 
    }

    local AllCurrentAilmentsList = {}
    for Category, Ailments in pairs(PetData.ailments) do
      if type(Ailments) == "table" then
        for _, AilmentName in ipairs(Ailments) do
          table.insert(AllCurrentAilmentsList, AilmentName)
        end
      end
    end

    for Category, Ailments in pairs(PetData.ailments) do
      if Category ~= "hybrid" then
        for _, Ailment in ipairs(Ailments) do
          table.insert(Result.ailments[Category], Ailment)
        end
      end
    end

    for _, HybridName in ipairs(PetData.ailments.hybrid or {}) do
      local HybridConfiguration = Configuration.hybrid[HybridName]
      if not HybridConfiguration then
        warn("OptimizeHybridAilments: No configuration found for hybrid ailment: " .. HybridName)
        table.insert(Result.ailments.unknown, HybridName) 
      else 
        local TimeLocationMethod = HybridConfiguration.location_method.time
        local ParallelAtLocationCount = 0
        local SupportedAtLocation = Capabilities[HybridName] or {}
        if #SupportedAtLocation > 0 then
          for _, SupportedAilment in ipairs(SupportedAtLocation) do
            if table.find(AllCurrentAilmentsList, SupportedAilment) then
              ParallelAtLocationCount = ParallelAtLocationCount + 1
            end
          end
        end

        local StaticMethodViability = self:__GetHybridStaticMethodViabilityAndParallelTasks(HybridName, AllCurrentAilmentsList)
        local TimeStaticMethod = HybridConfiguration.static_method.time
        local ParallelAtStaticCount = 0

        if StaticMethodViability.isViable then
          ParallelAtStaticCount = #StaticMethodViability.parallelAilments
        end

        local ChooseStatic = false
        local EffectiveTimeStatic = TimeStaticMethod
        local EffectiveTimeLocation = TimeLocationMethod

        if StaticMethodViability.isViable then
          if ParallelAtStaticCount > ParallelAtLocationCount then
            ChooseStatic = true
          elseif ParallelAtStaticCount == ParallelAtLocationCount then
            if TimeStaticMethod <= TimeLocationMethod then
              ChooseStatic = true
            end
          else 
            EffectiveTimeStatic = TimeStaticMethod - (ParallelAtStaticCount * 5)
            EffectiveTimeLocation = TimeLocationMethod - (ParallelAtLocationCount * 5)
            if EffectiveTimeStatic < EffectiveTimeLocation then
              ChooseStatic = true
            end
          end

          if not ChooseStatic then 
            if ParallelAtStaticCount > 0 and ParallelAtLocationCount == 0 and TimeStaticMethod <= TimeLocationMethod then
              ChooseStatic = true
            elseif TimeStaticMethod < TimeLocationMethod and ParallelAtLocationCount == 0 and ParallelAtStaticCount == 0 then 
              ChooseStatic = true
            elseif TimeStaticMethod < TimeLocationMethod and ParallelAtLocationCount == 0 then 
              ChooseStatic = true
            end
          end
        end

        if ChooseStatic then
          table.insert(Result.ailments.static, HybridName)
          if StaticMethodViability.isViable and #StaticMethodViability.parallelAilments > 0 then
            Result.staticHybridParallelInfo[HybridName] = StaticMethodViability.parallelAilments 
          end
        else
          table.insert(Result.ailments.location, HybridName)
        end
      end
    end

    return Result
  end;

  ["GenerateTaskPlan"] = function(self, PetData, ShouldFinalize)
    local OptimizedData = self:OptimizeHybridAilments(PetData)
    local Configuration = self:GetAilmentCategories()

    if OptimizedData.ailments.meta_tasks then
      local MetaTasksToKeep = {}
      for _, AilmentName in ipairs(OptimizedData.ailments.meta_tasks) do
        local AilmentDetails = Configuration.meta_tasks and Configuration.meta_tasks[AilmentName]
        if AilmentDetails and AilmentDetails.job_type == "CHOICE_HANDLER" then
          local ResolvedAilment = self:__ResolveChoiceHandler(AilmentName, Configuration)
          if ResolvedAilment then
            if not OptimizedData.ailments[ResolvedAilment.category] then
              OptimizedData.ailments[ResolvedAilment.category] = {}
            end
            table.insert(OptimizedData.ailments[ResolvedAilment.category], ResolvedAilment.name)
          else
            warn("GenerateTaskPlan: Could not resolve choice for " .. AilmentName .. ". It will be skipped.")
            table.insert(MetaTasksToKeep, AilmentName) 
          end
        else
          table.insert(MetaTasksToKeep, AilmentName) 
        end
      end
      OptimizedData.ailments.meta_tasks = MetaTasksToKeep 
    end

    local Capabilities = self:GetLocationCapabilities()
    local Plan, Remaining = {}, {}

    for _, Ailments in pairs(OptimizedData.ailments) do
      for _, Ailment in ipairs(Ailments) do table.insert(Remaining, Ailment) end
    end

    for i = #Remaining, 1, -1 do
      if Remaining[i] == "sick" then
        table.insert(Plan, {type = "instant", ailment = "sick", description = "sick"})
        table.remove(Remaining, i)
      end
    end

    local LocationTasks = {}
    for i = #Remaining, 1, -1 do
      local Ailment = Remaining[i]
      local IsLocationTask = false

      if Configuration.location[Ailment] then 
        IsLocationTask = true
      elseif Configuration.hybrid[Ailment] then 
        if OptimizedData.ailments.location then
          for _, CategorizedLocationAilment in ipairs(OptimizedData.ailments.location) do
            if CategorizedLocationAilment == Ailment then
              IsLocationTask = true
              break
            end
          end
        end
      end

      if IsLocationTask then
        table.insert(LocationTasks, Ailment)
        table.remove(Remaining, i)
      end
    end

    local FutureCapabilitiesMap = {}
    for i = 1, #LocationTasks do
      local FutureCapabilities = {}
      local LocationTaskName = LocationTasks[i] -- Added for clarity
      for j = i + 1, #LocationTasks do
        local FutureLocationTaskName = LocationTasks[j] -- Added for clarity
        for _, Capability in ipairs(Capabilities[FutureLocationTaskName] or {}) do
          FutureCapabilities[Capability] = true
        end
      end
      FutureCapabilitiesMap[i] = FutureCapabilities
    end

    for LocationIndex = 1, #LocationTasks do
      local LocationAilment = LocationTasks[LocationIndex]
      table.insert(Plan, {type = "location", ailment = LocationAilment, description = "Go to " .. LocationAilment})

      local LocationTime = (Configuration.location[LocationAilment] and Configuration.location[LocationAilment].time) or 
        (Configuration.hybrid[LocationAilment] and Configuration.hybrid[LocationAilment].location_method.time) or 20

      local Supported = Capabilities[LocationAilment] or {}
      local SupportedLookup = {}
      for _, Support in ipairs(Supported) do SupportedLookup[Support] = true end

      local PackedThisLocation = {}
      local CurrentRemainingTimeAtLocation = LocationTime
      local CurrentTotalPackedTime = 0
      local FutureCapabilities = FutureCapabilitiesMap[LocationIndex] or {}

      local AvailableCandidates = {}
      for i = #Remaining, 1, -1 do 
        local AilmentName = Remaining[i]
        if SupportedLookup[AilmentName] then
          local Cfg = Configuration
          local Time = (Cfg.feeding[AilmentName] and Cfg.feeding[AilmentName].time) or 
            (Cfg.static[AilmentName] and Cfg.static[AilmentName].time) or 
            (Cfg.playful[AilmentName] and Cfg.playful[AilmentName].time) or 
            (Cfg.hybrid[AilmentName] and Cfg.hybrid[AilmentName].static_method and Cfg.hybrid[AilmentName].static_method.time) or 0
          local Priority = (Cfg.feeding[AilmentName] and 3) or 
            (Cfg.static[AilmentName] and (AilmentName == "sleepy" and 2 or 1)) or 
            (AilmentName == "pet_me" and 1.5) or  
            (AilmentName == "walk" and 1.2) or   
            (AilmentName == "play" and 1.0) or  
            (AilmentName == "ride" and 1.0) or 1 
          table.insert(AvailableCandidates, {name = AilmentName, time = Time, priority = Priority, index_in_remaining = i})
        end
      end

      table.sort(AvailableCandidates, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.name < b.name 
      end)

      local CandidateProcessingIndex = 1
      while CandidateProcessingIndex <= #AvailableCandidates do
        local TaskToConsider = AvailableCandidates[CandidateProcessingIndex]
        local PackedSuccessfully = false

        if TaskToConsider.time <= CurrentRemainingTimeAtLocation then
          table.insert(PackedThisLocation, {ailment = TaskToConsider.name, time = TaskToConsider.time, priority = TaskToConsider.priority, index = TaskToConsider.index_in_remaining, overflowAmount = 0})
          CurrentTotalPackedTime = CurrentTotalPackedTime + TaskToConsider.time
          CurrentRemainingTimeAtLocation = CurrentRemainingTimeAtLocation - TaskToConsider.time
          table.remove(AvailableCandidates, CandidateProcessingIndex) 
          PackedSuccessfully = true
        elseif CurrentRemainingTimeAtLocation > 0 and
          TaskToConsider.time <= CurrentRemainingTimeAtLocation + 8 and 
          (LocationIndex == #LocationTasks or not FutureCapabilities[TaskToConsider.name]) then
          local Overflow = TaskToConsider.time - CurrentRemainingTimeAtLocation
          table.insert(PackedThisLocation, {ailment = TaskToConsider.name, time = TaskToConsider.time, priority = TaskToConsider.priority, index = TaskToConsider.index_in_remaining, overflowAmount = Overflow})
          CurrentTotalPackedTime = CurrentTotalPackedTime + TaskToConsider.time
          CurrentRemainingTimeAtLocation = 0 
          table.remove(AvailableCandidates, CandidateProcessingIndex) 
          PackedSuccessfully = true
        end

        if not PackedSuccessfully then
          CandidateProcessingIndex = CandidateProcessingIndex + 1 
        end
      end 

      table.sort(PackedThisLocation, function(a,b) return a.index > b.index end) 

      for _, PackedTaskData in ipairs(PackedThisLocation) do
        table.insert(Plan, {
          type = "location_bonus",
          ailment = PackedTaskData.ailment,
          description = PackedTaskData.ailment,
          time = PackedTaskData.time,
          overflowAmount = PackedTaskData.overflowAmount
        })
        table.remove(Remaining, PackedTaskData.index) 
      end

      local MainLocationTaskEntryIndex = -1
      for k = #Plan, 1, -1 do
        if Plan[k].type == "location" and Plan[k].ailment == LocationAilment then
          MainLocationTaskEntryIndex = k
          break
        end
      end
      if MainLocationTaskEntryIndex ~= -1 then
        Plan[MainLocationTaskEntryIndex].adjustedTime = math.max(LocationTime, CurrentTotalPackedTime)
      end
    end

    if ShouldFinalize then
      return self:__CompletePlan(Plan, Remaining, OptimizedData.staticHybridParallelInfo, Configuration)
    else
      return Plan, Remaining
    end
  end;

  ["GenerateRandomPetData"] = function(self, NumberOfTasks)
    if not NumberOfTasks or NumberOfTasks <= 0 then
      warn("TaskPlanner.GenerateRandomPetData: NumberOfTasks must be a positive integer.")
      return nil
    end

    self.RandomPetCounter = self.RandomPetCounter + 1
    local PetName = "RandomPet_" .. self.RandomPetCounter

    local PetData = {
      unique = PetName,
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

    local Config = self:GetAilmentCategories()
    local AllPossibleAilments = {}

    for CategoryName, AilmentsInCategory in pairs(Config) do
      if type(AilmentsInCategory) == "table" then
        for AilmentName, _ in pairs(AilmentsInCategory) do
          table.insert(AllPossibleAilments, {name = AilmentName, category = CategoryName})
        end
      end
    end

    if #AllPossibleAilments == 0 then
      warn("TaskPlanner.GenerateRandomPetData: No ailments found in AILMENT_CONFIG.")
      return PetData 
    end

    for _ = 1, NumberOfTasks do
      local RandomIndex = math.random(1, #AllPossibleAilments)
      local ChosenAilment = AllPossibleAilments[RandomIndex]

      if PetData.ailments[ChosenAilment.category] then
        table.insert(PetData.ailments[ChosenAilment.category], ChosenAilment.name)
      else
        warn("TaskPlanner.GenerateRandomPetData: Unknown category '" .. ChosenAilment.category .. "' for ailment '" .. ChosenAilment.name .. "'. Adding to unknown.")
        table.insert(PetData.ailments.unknown, ChosenAilment.name)
      end
    end

    return PetData
  end;

  --[[ PRIVATE HELPER METHODS ]]
  ["__GetCurrentLocationContext"] = function(self)
    if self.TestScenarioConfig and self.TestScenarioConfig.current_location_context ~= nil then
      return self.TestScenarioConfig.current_location_context
    end
    return "HybridGlitchSpot_Bored" 
  end;

  ["__GetDetectedFurnitureAtCurrentSpot"] = function(self, LocationContext)
    if self.TestScenarioConfig and self.TestScenarioConfig.detected_furniture ~= nil then
      if type(self.TestScenarioConfig.detected_furniture) == "function" then
        return self.TestScenarioConfig.detected_furniture(LocationContext)
      else
        return self.TestScenarioConfig.detected_furniture
      end
    end
    if LocationContext == "PlayerActualHouse" then
      return {"pet_bowl", "pet_bed", "chair"} 
    elseif string.find(LocationContext, "HybridGlitchSpot") then
      return {"chair"} 
    else
      return {} 
    end
  end;

  ["__GetPlayerMoneyState"] = function(self)
    if self.TestScenarioConfig and self.TestScenarioConfig.player_money_state ~= nil then
      local moneyState = self.TestScenarioConfig.player_money_state
      return {
        canAffordSmartLocker = moneyState.can_afford_smart_locker,
        canAffordSmartBowl = moneyState.can_afford_smart_bowl,
        canAffordSmartBed = moneyState.can_afford_smart_bed,
        canAffordSmartShower = moneyState.can_afford_smart_shower,
        canAffordSmartToilet = moneyState.can_afford_smart_toilet
      }
    end
    return { 
      canAffordSmartLocker = true, 
      canAffordSmartBowl = true, 
      canAffordSmartBed = true, 
      canAffordSmartShower = true,
      canAffordSmartToilet = true,
    }
  end;

  ["__GetPlayerSmartFurnitureMode"] = function(self)
    if self.TestScenarioConfig and self.TestScenarioConfig.player_smart_furniture_mode ~= nil then
      return self.TestScenarioConfig.player_smart_furniture_mode
    end
    return true 
  end;

  ["__GetHybridStaticMethodViabilityAndParallelTasks"] = function(self, HybridTaskName, CurrentPetAilments)
    local LocationContext = self:__GetCurrentLocationContext() 
    local DetectedFurniture = self:__GetDetectedFurnitureAtCurrentSpot(LocationContext)
    local SmartModeEnabled = self:__GetPlayerSmartFurnitureMode()
    local MoneyState = self:__GetPlayerMoneyState()

    local Result = {
      isViable = false,
      lockingMechanism = "none", 
      parallelAilments = {}
    }

    local HasChair = false
    local DetectedSmartFurnitureMap = {} 

    for _, Item in ipairs(DetectedFurniture) do
      if Item == "chair" then
        HasChair = true
      elseif string.sub(Item, 1, 6) == "smart_" then 
        DetectedSmartFurnitureMap[Item] = true
      end
    end

    local HasAnyDetectedSmartFurniture = false
    for _ in pairs(DetectedSmartFurnitureMap) do
      HasAnyDetectedSmartFurniture = true
      break
    end

    local AILMENT_TO_SMART_FURNITURE_MAP = {
      sleepy = "smart_pet_bed",
      hungry = "smart_pet_bowl",
      thirsty = "smart_pet_bowl",
      dirty = "smart_shower",
      toilet = "smart_toilet",
    }
    local SMART_FURNITURE_TO_AFFORDABILITY_KEY = {
      smart_pet_bed = "canAffordSmartBed",
      smart_pet_bowl = "canAffordSmartBowl",
      smart_shower = "canAffordSmartShower",
      smart_toilet = "canAffordSmartToilet",
    }

    if SmartModeEnabled then
      if HasAnyDetectedSmartFurniture then
        Result.isViable = true
        Result.lockingMechanism = "smart_item_detected"
        for Ailment, SmartItemName in pairs(AILMENT_TO_SMART_FURNITURE_MAP) do
          if DetectedSmartFurnitureMap[SmartItemName] and table.find(CurrentPetAilments, Ailment) then
            table.insert(Result.parallelAilments, Ailment)
          end
        end
      elseif MoneyState.canAffordSmartLocker then 
        Result.isViable = true
        Result.lockingMechanism = "smart_item_virtual"
        for Ailment, SmartItemName in pairs(AILMENT_TO_SMART_FURNITURE_MAP) do
          local AffordabilityKey = SMART_FURNITURE_TO_AFFORDABILITY_KEY[SmartItemName]
          if MoneyState[AffordabilityKey] and table.find(CurrentPetAilments, Ailment) then
            table.insert(Result.parallelAilments, Ailment)
          end
        end
      elseif HasChair then 
        Result.isViable = true
        Result.lockingMechanism = "chair"
        if table.find(CurrentPetAilments, "pet_me") then
          table.insert(Result.parallelAilments, "pet_me")
        end
      end
    else 
      if HasChair then
        Result.isViable = true
        Result.lockingMechanism = "chair"
        if table.find(CurrentPetAilments, "pet_me") then
          table.insert(Result.parallelAilments, "pet_me")
        end
      end
    end

    if Result.isViable and (Result.lockingMechanism == "smart_item_detected" or Result.lockingMechanism == "smart_item_virtual" or Result.lockingMechanism == "chair") then
      if table.find(CurrentPetAilments, "pet_me") and not table.find(Result.parallelAilments, "pet_me") then
        table.insert(Result.parallelAilments, "pet_me")
      end
    end

    return Result
  end;

  ["__ResolveChoiceHandler"] = function(self, OriginalChoiceAilmentName, FullAilmentConfig)
    local AllValidOptions = {}
    local CATEGORIES_TO_CONSIDER = {"feeding", "playful", "static", "location", "hybrid"}

    for _, CategoryName in ipairs(CATEGORIES_TO_CONSIDER) do
      if FullAilmentConfig[CategoryName] then
        for AilmentName, AilmentDetails in pairs(FullAilmentConfig[CategoryName]) do
          local TimeForComparison
          local ActualDetailsToReturn = AilmentDetails
          local ActualCategoryToReturn = CategoryName

          if CategoryName == "hybrid" then
            if AilmentDetails.location_method and AilmentDetails.static_method then
              TimeForComparison = math.min(AilmentDetails.location_method.time, AilmentDetails.static_method.time)
            else
              TimeForComparison = nil 
            end
          elseif AilmentDetails.time ~= nil then 
            TimeForComparison = AilmentDetails.time
          else
            TimeForComparison = nil 
          end

          if AilmentDetails.job_type == "CHOICE_HANDLER" then
            TimeForComparison = nil 
          end

          if TimeForComparison ~= nil then
            table.insert(AllValidOptions, {
              name = AilmentName, 
              details = ActualDetailsToReturn, 
              category = ActualCategoryToReturn, 
              time_for_choice_comparison = TimeForComparison
            })
          end
        end
      end
    end

    if #AllValidOptions == 0 then
      warn("TaskPlanner.__ResolveChoiceHandler: No valid ailment options available to choose from for " .. OriginalChoiceAilmentName)
      return nil
    end

    local ChosenOptionsForComparison = {}
    local AvailableIndices = {}
    for i = 1, #AllValidOptions do table.insert(AvailableIndices, i) end

    local NumToSelect = math.min(3, #AllValidOptions)

    for _ = 1, NumToSelect do
      if #AvailableIndices == 0 then break end
      local RandomIndexInAvailable = math.random(1, #AvailableIndices)
      local ActualIndex = table.remove(AvailableIndices, RandomIndexInAvailable)
      table.insert(ChosenOptionsForComparison, AllValidOptions[ActualIndex])
    end

    if #ChosenOptionsForComparison == 0 then 
      warn("TaskPlanner.__ResolveChoiceHandler: Failed to select any options for comparison for " .. OriginalChoiceAilmentName)
      return nil
    end

    local MostEfficientOption = ChosenOptionsForComparison[1]
    for i = 2, #ChosenOptionsForComparison do
      if ChosenOptionsForComparison[i].time_for_choice_comparison < MostEfficientOption.time_for_choice_comparison then
        MostEfficientOption = ChosenOptionsForComparison[i]
      end
    end

    return MostEfficientOption 
  end;

  ["__CompletePlan"] = function(self, Plan, RemainingAilmentNames, StaticParallelInfo, AilmentConfig) 
    warn("--- __CompletePlan Debug ---")
    if StaticParallelInfo then
      for Hybrid, Parallels in pairs(StaticParallelInfo) do
        warn("StaticParallelInfo for hybrid: " .. Hybrid .. " -> " .. table.concat(Parallels, ", "))
      end
    else
      warn("StaticParallelInfo is nil")
    end
    warn("Initial RemainingAilmentNames: " .. table.concat(RemainingAilmentNames, ", ")) 

    local ProcessedTasks = {} 
    local HandledAilments = {} -- Stores counts of ailments handled by walk/play or static hybrid packing

    -- Helper to count occurrences in an array
    local function CountOccurrences(List, Item) 
      local Count = 0
      for _, Val in ipairs(List) do
        if Val == Item then Count = Count + 1 end
      end
      return Count
    end

    -- Helper to get task details for sorting parallels
    local GetTaskDetailsForSort = function(AilmentName) 
      local Time = 0; local Priority = 0
      if AilmentConfig.static and AilmentConfig.static[AilmentName] then Priority = 1; Time = AilmentConfig.static[AilmentName].time
      elseif AilmentConfig.feeding and AilmentConfig.feeding[AilmentName] then Priority = 2; Time = AilmentConfig.feeding[AilmentName].time
      elseif AilmentConfig.playful and AilmentConfig.playful[AilmentName] then Priority = 3; Time = AilmentConfig.playful[AilmentName].time
      else 
        for _, CD in pairs(AilmentConfig) do 
          if type(CD) == "table" and CD[AilmentName] and CD[AilmentName].time then 
            Time = CD[AilmentName].time; Priority = 4; break 
          end 
        end 
      end 
      return { name = AilmentName, time = Time or 0, priority = Priority }
    end

    -- STAGE 1: Handle Walk + Play combination
    local CurrentRemainingAfterWalkPlay = {}
    local WalkCount = 0
    local PlayCount = 0
    for _, Name in ipairs(RemainingAilmentNames) do
      if Name == "walk" then WalkCount = WalkCount + 1
      elseif Name == "play" then PlayCount = PlayCount + 1
      end
    end

    local PairsToForm = math.min(WalkCount, PlayCount)
    if PairsToForm > 0 then
      table.insert(ProcessedTasks, {
        type = "combined_play",
        ailment = "walk_and_play",
        description = "walk + play",
        time = 17 * PairsToForm,
        count = PairsToForm
      })
      local WalksAccountedFor = PairsToForm
      local PlaysAccountedFor = PairsToForm
      for _, Name in ipairs(RemainingAilmentNames) do
        if Name == "walk" and WalksAccountedFor > 0 then
          WalksAccountedFor = WalksAccountedFor - 1
          HandledAilments[Name] = (HandledAilments[Name] or 0) + 1 
        elseif Name == "play" and PlaysAccountedFor > 0 then
          PlaysAccountedFor = PlaysAccountedFor - 1
          HandledAilments[Name] = (HandledAilments[Name] or 0) + 1 
        else
          table.insert(CurrentRemainingAfterWalkPlay, Name) 
        end
      end
    else
      for _, Name in ipairs(RemainingAilmentNames) do table.insert(CurrentRemainingAfterWalkPlay, Name) end 
    end
    warn("Remaining after walk+play: " .. table.concat(CurrentRemainingAfterWalkPlay, ", ")) 

    -- STAGE 2: Handle Static Hybrids and their parallel tasks
    for _, AilmentName in ipairs(CurrentRemainingAfterWalkPlay) do
      local IsStaticHybridWithInfo = StaticParallelInfo and StaticParallelInfo[AilmentName]

      if IsStaticHybridWithInfo then
        local TotalInstancesOfHybridInCurrentList = CountOccurrences(CurrentRemainingAfterWalkPlay, AilmentName)
        local AlreadyHandledAsMainHybrid = HandledAilments[AilmentName] or 0
        
        -- Check if this specific instance of AilmentName (if duplicated) can be processed as a main static hybrid
        if AlreadyHandledAsMainHybrid < TotalInstancesOfHybridInCurrentList then
          local HybridStaticDetails = AilmentConfig.hybrid[AilmentName] and AilmentConfig.hybrid[AilmentName].static_method
          if not HybridStaticDetails then 
            warn("__CompletePlan: Missing static_method details for hybrid: " .. AilmentName)
          else
            table.insert(ProcessedTasks, {type = "static_hybrid", ailment = AilmentName, description = AilmentName, time = HybridStaticDetails.time })
            HandledAilments[AilmentName] = (HandledAilments[AilmentName] or 0) + 1 

            local MainHybridCapacity = HybridStaticDetails.time
            local CurrentCapacityUsed = 0
            local PotentialParallels = StaticParallelInfo[AilmentName] or {}
            local SortedParallelCandidates = {}

            if #PotentialParallels > 0 then
              for _, PName in ipairs(PotentialParallels) do 
                table.insert(SortedParallelCandidates, GetTaskDetailsForSort(PName)) 
              end

              table.sort(SortedParallelCandidates, function(a,b) 
                if a.priority ~= b.priority then return a.priority < b.priority end
                if a.time ~= b.time then return a.time < b.time end
                return a.name < b.name 
              end)

              for _, PCandidate in ipairs(SortedParallelCandidates) do
                local AvailableInstancesOfParallel = CountOccurrences(CurrentRemainingAfterWalkPlay, PCandidate.name)
                local HandledInstancesOfParallel = HandledAilments[PCandidate.name] or 0

                if HandledInstancesOfParallel < AvailableInstancesOfParallel and CurrentCapacityUsed + PCandidate.time <= MainHybridCapacity then
                  local Details = nil
                  for _,CD_1 in pairs(AilmentConfig) do 
                    if type(CD_1)=="table" and CD_1[PCandidate.name] then 
                      Details=CD_1[PCandidate.name]; break 
                    end 
                  end

                  if not Details then 
                    warn("Missing config for parallel: "..PCandidate.name) 
                  else
                    table.insert(ProcessedTasks, {type="static_hybrid_bonus", ailment=PCandidate.name, description=PCandidate.name, time=PCandidate.time, is_parallel_to_static_hybrid=true})
                    HandledAilments[PCandidate.name] = (HandledAilments[PCandidate.name] or 0) + 1
                    CurrentCapacityUsed = CurrentCapacityUsed + PCandidate.time
                  end
                end
              end
            end
          end
        end
      end
    end

    -- STAGE 3: Determine and process "true" remaining tasks
    local AilmentNamesForFinalPass = {}
    local TempHandledCounts = table.clone(HandledAilments) -- Use a mutable copy for this stage

    for _, AilmentName in ipairs(CurrentRemainingAfterWalkPlay) do
      if (TempHandledCounts[AilmentName] or 0) > 0 then
        TempHandledCounts[AilmentName] = TempHandledCounts[AilmentName] - 1 -- Account for this instance
      else
        table.insert(AilmentNamesForFinalPass, AilmentName) -- This instance was not handled, add to final list
      end
    end
    warn("Remaining for final pass (true remainings): " .. table.concat(AilmentNamesForFinalPass, ", ")) 

    local UniqueAilmentsForFinalProcessing = {}
    local SeenForFinal = {}
    local AilmentCountsFinal = {}

    for _, AilmentName in ipairs(AilmentNamesForFinalPass) do
      AilmentCountsFinal[AilmentName] = (AilmentCountsFinal[AilmentName] or 0) + 1
      if not SeenForFinal[AilmentName] then
        table.insert(UniqueAilmentsForFinalProcessing, AilmentName)
        SeenForFinal[AilmentName] = true
      end
    end

    for _, AilmentName in ipairs(UniqueAilmentsForFinalProcessing) do
      local OriginalTime = 0; local TaskInfo = nil
      for _,CD_2 in pairs(AilmentConfig) do 
        if type(CD_2)=="table" and CD_2[AilmentName] then 
          TaskInfo=CD_2[AilmentName]; break 
        end 
      end
      if TaskInfo then
        if TaskInfo.static_method and TaskInfo.static_method.time then OriginalTime = TaskInfo.static_method.time
        elseif TaskInfo.location_method and TaskInfo.location_method.time then OriginalTime = TaskInfo.location_method.time 
        elseif TaskInfo.time then OriginalTime = TaskInfo.time end
      end
      local Count = AilmentCountsFinal[AilmentName] or 1
      table.insert(ProcessedTasks, {type="remaining", ailment=AilmentName, description=AilmentName, time = OriginalTime * Count, count = Count})
    end

    table.sort(ProcessedTasks, function(a, b)
      local GetPriority = function(Task) 
        local PRIORITY_MAP = ({ dirty=5, sleepy=4, hungry=3, thirsty=3, pet_me=1.5, walk=1, ride=1, toilet=0.5, play=1.4 })
        if Task.type == "static_hybrid" then return 100 end
        if Task.type == "static_hybrid_bonus" then return 99 end
        if Task.type == "combined_play" then return 2.0 end
        return PRIORITY_MAP[Task.ailment] or 0 
      end
      local GetTime = function(Task) if Task.time then return Task.time else return 0 end end 

      local PA, PB = GetPriority(a), GetPriority(b)
      if PA ~= PB then return PA > PB end
      local TA, TB = GetTime(a), GetTime(b)
      if TA ~= TB then return TA < TB end
      return a.ailment < b.ailment
    end)

    local FinalPlan = {} 
    for _, Task in ipairs(Plan) do table.insert(FinalPlan, Task) end 
    for _, Task in ipairs(ProcessedTasks) do table.insert(FinalPlan, Task) end

    local FinalPlanWithWait = {}
    for i, TaskData in ipairs(FinalPlan) do
      local CurrentTask = table.clone(TaskData)
      if i > 1 then
        local PreviousTask = FinalPlan[i-1]
        local IsFirstBonusForParentLocation = false
        if CurrentTask.type == "location_bonus" and PreviousTask.type == "location" then
          -- Check if the bonus ailment is directly related to the parent location name,
          -- This check might need refinement if descriptions change.
          -- For now, assuming bonus description IS the ailment name.
          -- And parent location description starts with "Go to " followed by ailment name.
          local ParentAilmentName = PreviousTask.ailment -- e.g. "bored"
          if CurrentTask.ailment and string.find(PreviousTask.description, ParentAilmentName) then
             -- This is a slightly loose check. A more robust way might be needed
             -- if descriptions get more complex.
             -- The original check was: string.match(currentTask.description, pattern)
             -- where pattern was PreviousTask.ailment:gsub(...). This seems better.
            local Pattern = PreviousTask.ailment:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") 
            if string.match(CurrentTask.description, Pattern) then 
                 IsFirstBonusForParentLocation = true
            end
          end
        end
        if not IsFirstBonusForParentLocation then
          CurrentTask.wait_for_ailment_completion = PreviousTask.ailment
        end
      end
      table.insert(FinalPlanWithWait, CurrentTask)
    end
    return FinalPlanWithWait
  end;
}
