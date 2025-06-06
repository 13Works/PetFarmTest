--/PetFarmOfficial.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Ad = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/Ad.lua"), true))()
local TaskPlanner = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/TaskPlanner.lua"), true))()
local PlanFormatter = loadstring(game:HttpGet(("https://raw.githubusercontent.com/13Works/PetFarmTest/refs/heads/main/PlanFormatter.lua"), true))()

local AilmentActions = {
  ["bored"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        local Success = Ad:go_home()
        if not Success then
          warn("Error going home in 'bored' ailment action.")
          return
        end
        local TargetCFrame = workspace["StaticMap"]["Park"]["BoredAilmentTarget"]["CFrame"]
        Ad:handle_smart_or_teleport_ailment(TargetCFrame, "park", PetModel, "bored") 
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "bored") then 
          print(string.format("AilmentActions.bored: Ailment '%s' not present for pet '%s' before action.", "bored", Ad:get_pet_unique_id_string(PetModel)))
          return
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "bored", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.bored: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.bored: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "bored") then return end 
        task.spawn(CoreActionLambda)
      end
    end)

    if not OuterPcallSuccess then 
      warn(string.format("Error setting up or invoking 'bored' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;
  ["beach_party"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        local Success = Ad:go_home()
        if not Success then
          warn("Error going home in 'beach_party' ailment action.")
          return
        end
        local AilmentTargetCFrame = workspace["StaticMap"]["Beach"]["BeachPartyAilmentTarget"]["CFrame"]
        Ad:handle_smart_or_teleport_ailment(AilmentTargetCFrame, "beach", PetModel, "beach_party")
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "beach_party") then 
          print(string.format("AilmentActions.beach_party: Ailment '%s' not present for pet '%s' before action.", "beach_party", Ad:get_pet_unique_id_string(PetModel)))
          return
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "beach_party", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.beach_party: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.beach_party: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "beach_party") then return end
        task.spawn(CoreActionLambda)
      end
    end)

    if not OuterPcallSuccess then 
      warn(string.format("Error setting up or invoking 'beach_party' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;
  ["camping"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        local Success = Ad:go_home()
        if not Success then
          warn("Error going home in 'camping' ailment action.")
          return
        end
        local AilmentTargetCFrame = workspace["StaticMap"]["Campsite"]["CampsiteOrigin"]["CFrame"]
        Ad:handle_smart_or_teleport_ailment(AilmentTargetCFrame, "campsite", PetModel, "camping")
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "camping") then 
          print(string.format("AilmentActions.camping: Ailment '%s' not present for pet '%s' before action.", "camping", Ad:get_pet_unique_id_string(PetModel)))
          return 
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "camping", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.camping: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.camping: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "camping") then return end
        task.spawn(CoreActionLambda)
      end
    end)

    if not OuterPcallSuccess then 
      warn(string.format("Error setting up or invoking 'camping' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["hungry"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          Ad:purchase_and_consume_item(PetModel, "teachers_apple")
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "hungry") then 
            print(string.format("AilmentActions.hungry.Standard: Ailment '%s' not present for pet '%s' before action.", "hungry", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "hungry", 25, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.hungry.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "hungry") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'hungry.Standard' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end; 
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local Bowl = Ad.SmartFurnitureMap["hungry"]
          if Bowl then
            Ad:place_and_use_sitable_at_cframe(Bowl, TargetCFrame, PetModel)
          else
            warn("PetFarmOfficial.AilmentActions.hungry.Smart: Smart food bowl not available. Consider falling back to Standard or checking configuration.")
          end
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "hungry") then 
            print(string.format("AilmentActions.hungry.Smart: Ailment '%s' not present for pet '%s' before action.", "hungry", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "hungry", 25, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Smart: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.hungry.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "hungry") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.hungry.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)

      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'hungry.Smart' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["thirsty"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          Ad:purchase_and_consume_item(PetModel, "water")
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "thirsty") then 
            print(string.format("AilmentActions.thirsty.Standard: Ailment '%s' not present for pet '%s' before action.", "thirsty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "thirsty", 25, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.thirsty.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "thirsty") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'thirsty.Standard' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local Bowl = Ad.SmartFurnitureMap["thirsty"]
          if Bowl then
            Ad:place_and_use_sitable_at_cframe(Bowl, TargetCFrame, PetModel)
          else
            warn("PetFarmOfficial.AilmentActions.thirsty.Smart: Smart water bowl not available. Consider falling back to Standard or checking configuration.")
          end
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "thirsty") then 
            print(string.format("AilmentActions.thirsty.Smart: Ailment '%s' not present for pet '%s' before action.", "thirsty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "thirsty", 25, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Smart: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.thirsty.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "thirsty") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.thirsty.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'thirsty.Smart' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["sick"] = {
    ["Smart"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          Ad:teleport_to_ailment_location("Hospital")
          task.wait(1)
          Ad.__api.housing.activate_interior_furniture("f-14", "UseBlock", "Yes", LocalPlayer.Character)
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "sick") then
            print(string.format("AilmentActions.sick.Smart: Ailment '%s' not present for pet '%s' before action.", "sick", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "sick", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.sick.Smart: %s", ResultMessage))
            Ad._SickSmartFailed = true
          else
            print(string.format("PetFarmOfficial.AilmentActions.sick.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "sick") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.sick.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
        Ad:go_home()
      end)
      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'sick.Smart' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          Ad:purchase_and_consume_item(PetModel, "healing_apple")
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "sick") then
            print(string.format("AilmentActions.sick.Standard: Ailment '%s' not present for pet '%s' before action.", "sick", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "sick", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.sick.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.sick.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "sick") then return end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.sick.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("Error setting up or invoking 'sick.Standard' ailment action: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["salon"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        Ad:teleport_to_ailment_location("Salon")
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "salon") then 
          print(string.format("AilmentActions.salon: Ailment '%s' not present for pet '%s' before action.", "salon", Ad:get_pet_unique_id_string(PetModel)))
          return
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "salon", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.salon: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.salon: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "salon") then return end
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.salon: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
      Ad:go_home()
    end)

    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'salon' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["school"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        Ad:teleport_to_ailment_location("School")
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "school") then 
          print(string.format("AilmentActions.school: Ailment '%s' not present for pet '%s' before action.", "school", Ad:get_pet_unique_id_string(PetModel)))
          return
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "school", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.school: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.school: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "school") then return end
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.school: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
      Ad:go_home()
    end)

    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'school' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["pizza_party"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        Ad:teleport_to_ailment_location("PizzaShop") 
      end

      if WaitForCompletion then
        if not Ad:verify_ailment_exists(PetModel, "pizza_party") then 
          print(string.format("AilmentActions.pizza_party: Ailment '%s' not present for pet '%s' before action.", "pizza_party", Ad:get_pet_unique_id_string(PetModel)))
          return
        end
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "pizza_party", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.pizza_party: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.pizza_party: %s", ResultMessage))
        end
      else
        if not Ad:verify_ailment_exists(PetModel, "pizza_party") then return end
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.pizza_party: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
      Ad:go_home()
    end)

    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'pizza_party' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["sleepy"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local Success = Ad:go_home()
          if not Success then
            warn("Error going home in 'sleepy' ailment action.")
            return
          end
          local FurnitureItem = Ad:retrieve_smart_furniture("sleepy", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.sleepy.Standard: No suitable smart or generic owned crib/bed found.")
            return
          end

          warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "sleepy") then 
            print(string.format("AilmentActions.sleepy.Standard: Ailment '%s' not present for pet '%s' before action.", "sleepy", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "sleepy", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "sleepy") then 
            print(string.format("AilmentActions.sleepy.Standard: Ailment '%s' not present for pet '%s' before action.", "sleepy", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local FurnitureItem = Ad:retrieve_smart_furniture("sleepy", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.sleepy.Smart: No suitable smart or generic owned crib/bed found.")
            return
          end

          if Ad:is_sitable_owned(FurnitureItem) then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:place_and_use_sitable_at_cframe(FurnitureItem, TargetCFrame, PetModel)
          else
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: FurnitureItem is not owned. Attempting to use FurnitureItem '%s' (Model: %s) at Character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
          end
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "sleepy") then 
            print(string.format("AilmentActions.sleepy.Smart: Ailment '%s' not present for pet '%s' before action.", "sleepy", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "sleepy", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "sleepy") then 
            print(string.format("AilmentActions.sleepy.Smart: Ailment '%s' not present for pet '%s' before action.", "sleepy", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.sleepy.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["dirty"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local Success = Ad:go_home()
          if not Success then
            warn("Error going home in 'dirty' ailment action.")
            return
          end
          local FurnitureItem = Ad:retrieve_smart_furniture("dirty", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.dirty.Standard: No suitable smart or generic owned shower/bath found.")
            return
          end

          warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "dirty") then 
            print(string.format("AilmentActions.dirty.Standard: Ailment '%s' not present for pet '%s' before action.", "dirty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "dirty", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "dirty") then 
            print(string.format("AilmentActions.dirty.Standard: Ailment '%s' not present for pet '%s' before action.", "dirty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.dirty.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local FurnitureItem = Ad:retrieve_smart_furniture("dirty", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.dirty.Smart: No suitable smart or generic owned shower/bath found.")
            return
          end

          if Ad:is_sitable_owned(FurnitureItem) then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:place_and_use_sitable_at_cframe(FurnitureItem, TargetCFrame, PetModel)
          else
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: FurnitureItem is not owned. Attempting to use FurnitureItem '%s' (Model: %s) at Character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
          end
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "dirty") then 
            print(string.format("AilmentActions.dirty.Smart: Ailment '%s' not present for pet '%s' before action.", "dirty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "dirty", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "dirty") then 
            print(string.format("AilmentActions.dirty.Smart: Ailment '%s' not present for pet '%s' before action.", "dirty", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.dirty.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["play"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        local ToyUnique = Ad:get_default_throw_toy_unique()
        if not ToyUnique then return end
        -- Throw the toy every 4 seconds until the task is complete
        while Ad:verify_ailment_exists(PetModel, "play") do
          local Success, Result = pcall(function()
            Ad.__api.pet_object.create_pet_object(
              "__Enum_PetObjectCreatorType_1", 
              {
                ["reaction_name"] = "ThrowToyReaction", 
                ["unique_id"] = ToyUnique
              }
            )
          end)
          if not Success then
            warn("AilmentActions.play: Failed to throw toy:", Result)
          end
          for _ = 1, 40 do -- Wait up to 4 seconds, but break early if task is done
            if not Ad:verify_ailment_exists(PetModel, "play") then break end
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
      end
      if WaitForCompletion then
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "play", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.play: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.play: %s", ResultMessage))
        end
      else
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.play: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
    end)
    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'play' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["toilet"] = {
    ["Standard"] = function(PetModel, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local Success = Ad:go_home()
          if not Success then
            warn("Error going home in 'toilet' ailment action.")
            return
          end
          local FurnitureItem = Ad:retrieve_smart_furniture("toilet", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.toilet.Standard: No suitable smart or generic owned toilet/litter box found.")
            return
          end

          warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Attempting to use FurnitureItem '%s' (Model: %s) at character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
          Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "toilet") then 
            print(string.format("AilmentActions.toilet.Standard: Ailment '%s' not present for pet '%s' before action.", "toilet", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "toilet", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "toilet") then 
            print(string.format("AilmentActions.toilet.Standard: Ailment '%s' not present for pet '%s' before action.", "toilet", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.toilet.Standard: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
    ["Smart"] = function(PetModel, TargetCFrame, WaitForCompletion)
      local OuterPcallSuccess, ErrorMessage = pcall(function()
        local CoreActionLambda = function()
          local FurnitureItem = Ad:retrieve_smart_furniture("toilet", true, true)
          print("DEBUG: FurnitureItem:", FurnitureItem)
          print("DEBUG: FurnitureItem.model:", FurnitureItem["model"], (typeof(FurnitureItem["model"]) == "Instance" and FurnitureItem["model"]["Name"]) or "N/A")
          print("DEBUG: FurnitureItem.vacant_seat:", FurnitureItem["vacant_seat"])
          print("DEBUG: FurnitureItem.name:", FurnitureItem["name"])

          if not FurnitureItem then
            warn("PetFarmOfficial.AilmentActions.toilet.Smart: No suitable smart or generic owned toilet/litter box found.")
            return
          end

          if Ad:is_sitable_owned(FurnitureItem) then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Attempting to place and use FurnitureItem '%s' (Model: %s) at TargetCFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:place_and_use_sitable_at_cframe(FurnitureItem, TargetCFrame, PetModel)
          else
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: FurnitureItem is not owned. Attempting to use FurnitureItem '%s' (Model: %s) at Character CFrame.", FurnitureItem["name"], FurnitureItem["model"] and FurnitureItem["model"]["Name"] or "N/A"))
            Ad:use_sitable_at_character_cframe(FurnitureItem, PetModel)
          end
        end

        if WaitForCompletion then
          if not Ad:verify_ailment_exists(PetModel, "toilet") then 
            print(string.format("AilmentActions.toilet.Smart: Ailment '%s' not present for pet '%s' before action.", "toilet", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "toilet", 30, nil, CoreActionLambda)
          if not DidAilmentClear then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: %s", ResultMessage))
          else
            print(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: %s", ResultMessage))
          end
        else
          if not Ad:verify_ailment_exists(PetModel, "toilet") then 
            print(string.format("AilmentActions.toilet.Smart: Ailment '%s' not present for pet '%s' before action.", "toilet", Ad:get_pet_unique_id_string(PetModel)))
            return
          end
          local ActionSuccess, ActionError = pcall(CoreActionLambda)
          if not ActionSuccess then
            warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Error during non-awaited execution: %s", tostring(ActionError)))
          end
        end
      end)
      if not OuterPcallSuccess then
        warn(string.format("PetFarmOfficial.AilmentActions.toilet.Smart: Error: %s", ErrorMessage or "Unknown error"))
      end
    end;
  };

  ["ride"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
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
        -- Set humanoid state to jumping until the ride task is over
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
          warn("AilmentActions.ride: Humanoid not found in character.")
          return
        end
        while Ad:verify_ailment_exists(PetModel, "ride") do
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
      end
      if WaitForCompletion then
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "ride", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.ride: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.ride: %s", ResultMessage))
        end
      else
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.ride: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
    end)
    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'ride' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;

  ["walk"] = function(PetModel, WaitForCompletion)
    local OuterPcallSuccess, ErrorMessage = pcall(function()
      local CoreActionLambda = function()
        -- Hold the pet
        local HoldSuccess, HoldError = pcall(function()
          Ad.__api.adopt.hold_baby(PetModel)
        end)
        if not HoldSuccess then
          warn("AilmentActions.walk: Failed to hold pet:", HoldError)
          return
        end
        -- Wait for the walk ailment to clear
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
          warn("AilmentActions.walk: Humanoid not found in character.")
          return
        end
        while Ad:verify_ailment_exists(PetModel, "walk") do
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
      end
      if WaitForCompletion then
        local DidAilmentClear, ResultMessage = Ad:execute_action_with_timeout(PetModel, "walk", 40, nil, CoreActionLambda)
        if not DidAilmentClear then
          warn(string.format("PetFarmOfficial.AilmentActions.walk: %s", ResultMessage))
        else
          print(string.format("PetFarmOfficial.AilmentActions.walk: %s", ResultMessage))
        end
      else
        local ActionSuccess, ActionError = pcall(CoreActionLambda)
        if not ActionSuccess then
          warn(string.format("PetFarmOfficial.AilmentActions.walk: Error during non-awaited execution: %s", tostring(ActionError)))
        end
      end
    end)
    if not OuterPcallSuccess then
      warn(string.format("Error setting up or invoking 'walk' ailment action: %s", ErrorMessage or "Unknown error"))
    end
  end;
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
local function ProcessTaskPlan(PetUniqueId, PetModel, GeneratedPlan, AllAilmentActions, OriginalAilmentsFlatList)
  print(string.format("--- Starting Task Plan Execution for Pet: %s (%s) ---", PetModel["Name"], PetUniqueId))
  -- print("    DEBUG: AllAilmentActions keys available at start of ProcessTaskPlan:")

  local ActionKeys = {}

  for Key, _ in AllAilmentActions do 
    table.insert(ActionKeys, Key) 
  end 

  if GeneratedPlan and #GeneratedPlan > 0 then
    print(string.format("  Initial ailments for this plan: [%s]", table.concat(OriginalAilmentsFlatList or {}, ", ")))
  else
    print(string.format("ProcessTaskPlan: No tasks in the generated plan for %s. Initial ailments: [%s]", PetUniqueId, table.concat(OriginalAilmentsFlatList or {}, ", ")))
  end

  if GeneratedPlan and #GeneratedPlan > 0 then
    for TaskIndex, TaskData in GeneratedPlan do
      print(string.format("  [%d/%d] Attempting Task: Type='%s', Ailment/Desc='%s', Time='%s'", 
        TaskIndex, #GeneratedPlan, TaskData["type"], TaskData["ailment"] or TaskData["description"] or "N/A", tostring(TaskData["time"] or TaskData["adjustedTime"] or 0)))

      local ActionToExecute = nil
      local ActionRequiresTargetCFrame = false
      local AilmentNameForAction = TaskData["ailment"] 

      -- Special handling for 'sick' ailment
      if AilmentNameForAction == "sick" and typeof(AllAilmentActions["sick"]) == "table" then
        if Ad._SickSmartFailed then
          ActionToExecute = AllAilmentActions["sick"].Standard
        else
          ActionToExecute = AllAilmentActions["sick"].Smart
        end
      else
        if TaskData["type"] == "location_bonus" then
          if AilmentNameForAction and type(AllAilmentActions[AilmentNameForAction]) == "table" then
            ActionToExecute = AllAilmentActions[AilmentNameForAction].Smart
            ActionRequiresTargetCFrame = true
          end
        elseif TaskData["type"] == "location" or TaskData["type"] == "instant" or TaskData["type"] == "remaining" then
          if AilmentNameForAction and type(AllAilmentActions[AilmentNameForAction]) == "table" then
            ActionToExecute = AllAilmentActions[AilmentNameForAction].Standard
          elseif AilmentNameForAction then
            ActionToExecute = AllAilmentActions[AilmentNameForAction]
          end
        else
          -- fallback for other types
          if AilmentNameForAction then
            ActionToExecute = AllAilmentActions[AilmentNameForAction]
          end
        end
      end

      if next(Ad.SmartFurnitureMap) == nil then
        Ad:initialize_smart_furniture()
        print("    DEBUG: SmartFurnitureMap contents:")
        for Key, Value in Ad.SmartFurnitureMap do
          print(string.format("      %s: %s", Key, Value["name"]))
        end
      end

      if ActionToExecute ~= nil then 
        local TargetCFrame = nil
        if ActionRequiresTargetCFrame then
          if PetModel and PetModel.PrimaryPart then
            TargetCFrame = PetModel.PrimaryPart.CFrame * CFrame.new(0,0,-3) 
            print(string.format("    Using placeholder TargetCFrame for '%s' action near pet.", AilmentNameForAction))
          else
            warn(string.format("    ProcessTaskPlan: Cannot determine TargetCFrame for action '%s': PetModel or PrimaryPart missing. Skipping this task.", tostring(AilmentNameForAction)))
            ActionRequiresTargetCFrame = false 
          end
        end

        print(string.format("    Executing action for: %s", tostring(AilmentNameForAction or TaskData["type"])))
        local Success, ErrorMessage
        if ActionRequiresTargetCFrame and TargetCFrame then 
          if type(ActionToExecute) == "table" and ActionToExecute["Smart"] then
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
          if type(ActionToExecute) == "table" and ActionToExecute["Standard"] then
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
    for _, AilmentName in OriginalAilmentsFlatList do
      if Ad:verify_ailment_exists(PetModel, AilmentName) then
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
      print("PetFarm is ACTIVE (loop ID: " .. CurrentInstanceLoopId .. ", checked at " .. os.date("%X") .. ")")
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

              ProcessTaskPlan(PetDataForPlanner["unique"], PetModel, GeneratedPlan, AilmentActions, PetRawData["ailments"])
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
