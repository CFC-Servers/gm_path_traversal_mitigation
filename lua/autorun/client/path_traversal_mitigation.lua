local error = error
local assert = assert
local string_sub = string.sub
local string_find = string.find
local string_lower = string.lower
local ProtectedCall = ProtectedCall
local vgui_GetControlTable = vgui.GetControlTable

local Remove

local function isBadPath( url )
    url = string_lower( url )
    if string_sub( url, 1, 8 ) ~= "asset://" then
        return false
    end

    if not string_find( url, "garrysmod/%w+:", 9 ) then
        return false
    end

    return true
end

local function OnBeginLoadingDocument( panel, url )
    if isBadPath( url ) then
        Remove( panel )

        error( "Invalid path loaded in HTML: '" .. url .. "'" )
    end

    if panel._PreviousOnBegin then
        return panel:_PreviousOnBegin( url )
    end
end

local function updatePanelCallback( panel )
    if panel.OnBeginLoadingDocument == OnBeginLoadingDocument then return end

    local current = panel.OnBeginLoadingDocument
    panel._PreviousOnBegin = current
    panel.OnBeginLoadingDocument = OnBeginLoadingDocument
end

-- Wraps the given method on the given panel to forcibly set the OnBeginLoadingDocument callback before continuing
-- (Prevents accidental or intentional overwriting of our callback)
local function wrapPanelMethod( panelName, methodName )
    local meta = vgui_GetControlTable( panelName )
    local func = meta[methodName]
    assert( func ~= nil, "Could not wrap method '" .. methodName .. "' on '" .. panelName .. "'" )

    meta[methodName] = function( panel, ... )
        updatePanelCallback( panel )
        return func( panel, ... )
    end
end

hook.Add( "Initialize", "PathTraversalMitigationSetup", function()
    local panelMeta = vgui_GetControlTable( "DPanel" )
    Remove = panelMeta.Remove
    ProtectedCall( function() wrapPanelMethod( "DPanel", "SetHTML" ) end )

    ProtectedCall( function() wrapPanelMethod( "DHTML", "SetURL" ) end )
    ProtectedCall( function() wrapPanelMethod( "DHTML", "SetHTML" ) end )
    ProtectedCall( function() wrapPanelMethod( "DHTML", "Call" ) end )
    ProtectedCall( function() wrapPanelMethod( "DHTML", "QueueJavascript" ) end )
end )
