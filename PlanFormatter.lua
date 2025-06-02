-- PlanFormatter.luau - Module for formatting and printing task plans

local PlanFormatter = {}

-- Formatting Constants (local to this module)
local BOX_INNER_WIDTH = 58
local NUM_W = 4
local ICON_W = 4
local TASK_W = 20
local TIME_W = 14
local INFO_W = 12

-- Local Helper Functions
local function centerText(text, width)
  text = tostring(text) -- Ensure text is a string
  local textLength = #text
  if textLength >= width then return text end
  local paddingNeeded = width - textLength
  local leftPadding = math.floor(paddingNeeded / 2)
  return string.rep(" ", leftPadding) .. text 
  -- Note: Centering for the very top title lines in original code also had a trailing space sometimes, handled by print(centerText() .. " ")
  -- For the main purpose here, this basic centering should be fine. The print call can add specific padding if needed.
end

local function formatCell(text, width, align)
  text = tostring(text)
  local len = #text
  if len >= width then
    return string.sub(text, 1, width)
  end
  local diff = width - len
  if align == "right" then
    return string.rep(" ", diff) .. text
  elseif align == "center" then
    local padLeft = math.floor(diff / 2)
    local padRight = math.ceil(diff / 2)
    return string.rep(" ", padLeft) .. text .. string.rep(" ", padRight)
  else -- Default to left alignment
    return text .. string.rep(" ", diff)
  end
end

local function getAilmentEmoji(ailmentName, ailmentConfig)
  local specificEmojiMap = {
    hungry = "🍼", thirsty = "💧",
    sleepy = "💤", dirty = "🧼", toilet = "🚽",
    pet_me = "👋", walk = "🚶",
    catch = "🎾", ride = "🎠"
  }
  if specificEmojiMap[ailmentName] then return specificEmojiMap[ailmentName] end

  if ailmentConfig then -- Ensure ailmentConfig is provided
    if ailmentConfig.feeding and ailmentConfig.feeding[ailmentName] then return "🍼"
    elseif ailmentConfig.playful and ailmentConfig.playful[ailmentName] then return "🎾"
    elseif ailmentConfig.static and ailmentConfig.static[ailmentName] then return "🛑"
    end
  end
  return "🔹" -- Default emoji
end

--- Prints the finalized task plan to the console.
-- @param finalizedPlan The array of task objects to print.
-- @param petName The name of the pet or "Processed Plan".
-- @param ailmentConfig The AILMENT_CONFIG table, used by getAilmentEmoji and for time calculation.
function PlanFormatter.Print(finalizedPlan, petName, ailmentConfig)
  if not finalizedPlan then
    warn("PlanFormatter.Print: finalizedPlan is nil. Nothing to print.")
    return
  end
  if not ailmentConfig then
    warn("PlanFormatter.Print: ailmentConfig is nil. Cannot get emojis accurately.")
    -- We can still print, but emojis might be default and time calculation for header is removed
  end

  -- Defer total time calculation until after iterating for display
  local totalCalculatedTime = 0 

  -- Header structure elements
  local headerTopBorder = "╔" .. string.rep("═", BOX_INNER_WIDTH) .. "╗"
  local headerBottomBorder = "╚" .. string.rep("═", BOX_INNER_WIDTH) .. "╝"
  local titleSeparatorTop = "╠" .. string.rep("═", NUM_W) .. "╤" .. string.rep("═", ICON_W) .. "╤" .. string.rep("═", TASK_W) .. "╤" .. string.rep("═", TIME_W) .. "╤" .. string.rep("═", INFO_W) .. "╣"
  local titleSeparatorBottom = "╠" .. string.rep("═", NUM_W) .. "╪" .. string.rep("═", ICON_W) .. "╪" .. string.rep("═", TASK_W) .. "╪" .. string.rep("═", TIME_W) .. "╪" .. string.rep("═", INFO_W) .. "╣"
  local taskBlockSeparator = titleSeparatorBottom

  -- Pre-calculate max step number for formatting
  local MaxStepNumberValue = 0
  local tempStepCounter = 0
  for _, TaskData in ipairs(finalizedPlan) do
    if TaskData.type == "location" or TaskData.type == "remaining" or TaskData.type == "instant" or TaskData.type == "simultaneous" or TaskData.type == "static_hybrid" or TaskData.type == "combined_play" then
      tempStepCounter = tempStepCounter + 1
    end
  end
  MaxStepNumberValue = tempStepCounter
  local stepNumberFieldWidth = NUM_W - 2 
  if stepNumberFieldWidth < 1 then stepNumberFieldWidth = 1 end

  -- Store lines to print so header can be printed first with correct total time
  local linesToPrint = {}

  local RunningTotal = 0
  local CurrentDisplayStepNumber = 0

  for i, TaskData in ipairs(finalizedPlan) do
    local colNum, colIcon, colTask, colTime, colInfo

    local descriptionText = TaskData.description or TaskData.ailment or ""
    local TaskActualDuration = TaskData.time or 0
    local TaskDisplayTime = TaskData.adjustedTime or TaskActualDuration
    local SelfTimeContribution = 0

    if TaskData.type == "location" or TaskData.type == "remaining" or TaskData.type == "instant" or TaskData.type == "simultaneous" or TaskData.type == "static_hybrid" or TaskData.type == "combined_play" then
      CurrentDisplayStepNumber = CurrentDisplayStepNumber + 1
      colNum = formatCell(string.format("%"..stepNumberFieldWidth.."d. ", CurrentDisplayStepNumber), NUM_W, "left")

      local typeEmoji = (TaskData.type == "simultaneous" and "🔀" or 
        TaskData.type == "instant" and "⚡" or 
        TaskData.type == "location" and "📍" or
        TaskData.type == "static_hybrid" and "🏠" or
        TaskData.type == "combined_play" and "✨" or "🔧")
      colIcon = typeEmoji .. "  " 

      SelfTimeContribution = TaskDisplayTime 
      RunningTotal = RunningTotal + SelfTimeContribution -- This RunningTotal is the source of truth

      local taskDurationStr = string.format("%ds", TaskDisplayTime)
      local taskContribStr = string.format("%+ds", SelfTimeContribution)
      colTime = formatCell(string.format("[%s→%s]", taskDurationStr, taskContribStr), TIME_W, "left") .. "  "
      colInfo = formatCell(string.format("%ds total", RunningTotal), INFO_W, "left")

      if TaskData.count and TaskData.count > 1 then
        descriptionText = descriptionText .. " (x" .. TaskData.count .. ")"
      end
    else -- location_bonus or static_hybrid_bonus
      colNum = formatCell("", NUM_W, "left") 
      local ailmentEmoji = getAilmentEmoji(TaskData.ailment, ailmentConfig)
      colIcon = ailmentEmoji .. "  "

      local timeStr = string.format("%ds", TaskActualDuration)
      local contribStr = string.format("%+ds", 0)
      colTime = formatCell(string.format("[%s→%s]", timeStr, contribStr), TIME_W, "left") .. "  "

      local statusEmojiText = ""
      if TaskData.type == "location_bonus" then
        statusEmojiText = (TaskData.overflowAmount or 0) > 0 and "💨" or "并行"
      else 
        statusEmojiText = "并行"
      end
      colInfo = formatCell(statusEmojiText, INFO_W, "left") .. "  "
    end

    colTask = formatCell(descriptionText, TASK_W, "left")
    table.insert(linesToPrint, {type="data", content = "│" .. colNum .. "│" .. colIcon .. "│" .. colTask .. "│" .. colTime .. "│" .. colInfo .. "│"})

    if i < #finalizedPlan then
      local nextTask = finalizedPlan[i+1]
      if nextTask.type == "location" or 
        nextTask.type == "remaining" or 
        nextTask.type == "instant" or 
        nextTask.type == "simultaneous" or 
        nextTask.type == "static_hybrid" or
        nextTask.type == "combined_play" then
        table.insert(linesToPrint, {type="separator", content = taskBlockSeparator})
      end
    end
  end

  -- Now that RunningTotal has the final sum, use it for the header
  totalCalculatedTime = RunningTotal 

  -- Print header first
  warn(headerTopBorder)
  print(centerText("Task Plan for: " .. (petName or "Unknown"), BOX_INNER_WIDTH))
  print(centerText("Total estimated time: " .. totalCalculatedTime .. " seconds", BOX_INNER_WIDTH))
  warn(titleSeparatorTop)
  warn("│" .. formatCell("#", NUM_W, "left") ..
    "│" .. formatCell("Sym", ICON_W, "left") ..
    "│" .. formatCell("Task", TASK_W, "left") ..
    "│" .. formatCell("Time", TIME_W, "left") ..
    "│" .. formatCell("Info", INFO_W, "left") .. "│")
  warn(titleSeparatorBottom)

  -- Print stored lines
  for _, lineData in ipairs(linesToPrint) do
    if lineData.type == "data" then
      print(lineData.content)
    elseif lineData.type == "separator" then
      warn(lineData.content)
    end
  end

  warn(headerBottomBorder)
  print() 
end

return PlanFormatter 
