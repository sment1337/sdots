--[[
Conky Graph Script (No Cairo - uses Conky's built-in graph)
Save as: ~/.conky/graph.lua

This script generates Conky text markup for graphs.
For exec commands, use the _exec versions of functions.
]]

-- Store historical data
graph_data = graph_data or {}

function conky_graph(var_name, max_val)
    max_val = tonumber(max_val) or 100
    local width = 200
    local height = 30
    
    -- Initialize data table for this variable
    if not graph_data[var_name] then
        graph_data[var_name] = {}
    end
    
    -- Get current value
    local current = tonumber(conky_parse("${" .. var_name .. "}")) or 0
    
    -- Add to history (keep last 50 points)
    table.insert(graph_data[var_name], current)
    if #graph_data[var_name] > 50 then
        table.remove(graph_data[var_name], 1)
    end
    
    -- Build the graph using Conky's cpugraph/memgraph style
    local result = string.format("${voffset -5}%s: %d%%\n", var_name:upper(), current)
    result = result .. string.format("${cpugraph %s %d,%d 00ff00 00ff00 -t}\n", var_name, height, width)
    
    return result
end

-- Bar graph for regular Conky variables
function conky_bargraph(var_name, max_val, width, label, unit)
    max_val = tonumber(max_val) or 100
    width = tonumber(width) or 20
    label = label or var_name:upper()
    unit = unit or "%"
    
    -- Handle empty string literals
    if label == '""' or label == "''" or label == "" then
        label = nil
    end
    if unit == '""' or unit == "''" then
        unit = ""
    end
    
    local current = tonumber(conky_parse("${" .. var_name .. "}")) or 0
    local filled = math.floor((current / max_val) * width)
    local empty = width - filled
    
    local bar = string.rep("█", filled) .. string.rep("░", empty)
    
    -- Add unit if provided
    local value_str = string.format("%.1f", current)
    if unit ~= "" then
        value_str = value_str .. unit
    end
    
    -- Format result with or without label
    local result
    if label then
        result = string.format("%s: [%s] %s", label, bar, value_str)
    else
        result = string.format("[%s] %s", bar, value_str)
    end
    
    return result
end

-- Sparkline for regular Conky variables
function conky_sparkline(var_name, max_val, label, unit, width)
    max_val = tonumber(max_val) or 100
    label = label or var_name:upper()
    unit = unit or "%"
    
    -- Get conky width if not specified
    if not width or width == "" or width == '""' or width == "''" then
        width = tonumber(conky_parse("${conky_width}")) or 200
        -- Account for label and value display (rough estimate)
        if label and label ~= "" then
            width = width - #label - 15
        else
            width = width - 10
        end
        -- Convert width to number of data points (each character is roughly 5 pixels)
        width = math.floor(width / 5)
    else
        width = tonumber(width)
    end
    width = math.max(10, math.min(width or 40, 100)) -- Clamp between 10 and 100
    
    local blocks = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
    
    -- Handle empty string literals
    if label == '""' or label == "''" or label == "" then
        label = nil
    end
    if unit == '""' or unit == "''" then
        unit = ""
    end
    
    -- Initialize data table
    if not graph_data[var_name] then
        graph_data[var_name] = {}
    end
    
    -- Get current value
    local current = tonumber(conky_parse("${" .. var_name .. "}")) or 0
    
    -- Add to history (keep last width points for sparkline)
    table.insert(graph_data[var_name], current)
    if #graph_data[var_name] > width then
        table.remove(graph_data[var_name], 1)
    end
    
    -- Build sparkline
    local sparkline = ""
    for _, val in ipairs(graph_data[var_name]) do
        local idx = math.ceil((val / max_val) * #blocks)
        idx = math.max(1, math.min(idx, #blocks))
        sparkline = sparkline .. blocks[idx]
    end
    
    -- Add unit if provided
    local value_str = string.format("%.1f", current)
    if unit ~= "" then
        value_str = value_str .. unit
    end
    
    -- Format result with or without label
    local result
    if label then
        result = string.format("%s: %s %s", label, sparkline, value_str)
    else
        result = string.format("%s %s", sparkline, value_str)
    end
    
    return result
end

-- Bar graph for exec commands
function conky_bargraph_exec(command, max_val, width, label, unit, ...)
    -- Check if io.popen is available
    if not io or not io.popen then
        return "ERROR: io.popen not available"
    end
    
    max_val = tonumber(max_val) or 100
    width = tonumber(width) or 20
    label = label or "VALUE"
    unit = unit or ""
    
    -- Handle empty string literals
    if label == '""' or label == "''" or label == "" then
        label = nil
    end
    if unit == '""' or unit == "''" then
        unit = ""
    end
    
    -- Concatenate all arguments as the command (handles spaces in lua_parse)
    local args = {...}
    if #args > 0 then
        command = command .. " " .. table.concat(args, " ")
    end
    
    -- Replace placeholder quotes if user used them
    command = command:gsub("QUOTE", '"')
    command = command:gsub("APOS", "'")
    
    -- Execute command and get value
    local success, handle = pcall(io.popen, command)
    if not success or not handle then
        return (label or "ERROR") .. ": [CMD FAILED]"
    end
    
    local result_str = handle:read("*a")
    handle:close()
    
    -- Trim whitespace
    result_str = result_str:match("^%s*(.-)%s*$") or result_str
    
    local current = tonumber(result_str) or 0
    local filled = math.floor((current / max_val) * width)
    local empty = width - filled
    
    local bar = string.rep("█", filled) .. string.rep("░", empty)
    
    -- Add unit if provided
    local value_str = string.format("%.1f", current)
    if unit ~= "" then
        value_str = value_str .. unit
    end
    
    -- Format result with or without label
    local result
    if label then
        result = string.format("%s: [%s] %s", label, bar, value_str)
    else
        result = string.format("[%s] %s", bar, value_str)
    end
    
    return result
end

-- Sparkline for exec commands
function conky_sparkline_exec(command, max_val, label, unit, width, ...)
    -- Check if io.popen is available
    if not io or not io.popen then
        return "ERROR: io.popen not available"
    end
    
    max_val = tonumber(max_val) or 100
    label = label or "VALUE"
    unit = unit or ""
    
    -- Get conky width if not specified
    if not width or width == "" or width == '""' or width == "''" then
        width = tonumber(conky_parse("${conky_width}")) or 200
        -- Account for label and value display (rough estimate)
        if label and label ~= "" and label ~= '""' and label ~= "''" then
            width = width - #label - 15
        else
            width = width - 10
        end
        -- Convert width to number of data points (each character is roughly 5 pixels)
        width = math.floor(width / 5)
    else
        width = tonumber(width)
    end
    width = math.max(10, math.min(width or 40, 100)) -- Clamp between 10 and 100
    
    local blocks = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
    
    -- Handle empty string literals
    if label == '""' or label == "''" or label == "" then
        label = nil
    end
    if unit == '""' or unit == "''" then
        unit = ""
    end
    
    -- Concatenate all arguments as the command (handles spaces in lua_parse)
    local args = {...}
    if #args > 0 then
        command = command .. " " .. table.concat(args, " ")
    end
    
    -- Replace placeholder quotes if user used them
    command = command:gsub("QUOTE", '"')
    command = command:gsub("APOS", "'")
    
    -- Use command as key
    local key = "exec_" .. (label or "noname")
    
    -- Initialize data table
    if not graph_data[key] then
        graph_data[key] = {}
    end
    
    -- Execute command and get value
    local success, handle = pcall(io.popen, command)
    if not success or not handle then
        return (label or "ERROR") .. ": [CMD FAILED]"
    end
    
    local result_str = handle:read("*a")
    handle:close()
    
    -- Trim whitespace
    result_str = result_str:match("^%s*(.-)%s*$") or result_str
    
    local current = tonumber(result_str) or 0
    
    -- Add to history (keep last width points for sparkline)
    table.insert(graph_data[key], current)
    if #graph_data[key] > width then
        table.remove(graph_data[key], 1)
    end
    
    -- Build sparkline
    local sparkline = ""
    for _, val in ipairs(graph_data[key]) do
        local idx = math.ceil((val / max_val) * #blocks)
        idx = math.max(1, math.min(idx, #blocks))
        sparkline = sparkline .. blocks[idx]
    end
    
    -- Add unit if provided
    local value_str = string.format("%.1f", current)
    if unit ~= "" then
        value_str = value_str .. unit
    end
    
    -- Format result with or without label
    local result
    if label then
        result = string.format("%s: %s %s", label, sparkline, value_str)
    else
        result = string.format("%s %s", sparkline, value_str)
    end
    
    return result
end
