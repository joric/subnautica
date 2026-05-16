local UEHelpers = require("UEHelpers")

local helpText = [[SubMods 0.0.1 by Joric
Alt+O to Toggle Stats
Alt+H to Toggle Help]]

useStats = true

local VISIBLE = 4
local HIDDEN = 2

local statsWidget = FindObject("UserWidget", "StatsWidget")
local textBlock = FindObject("TextBlock", "StatsTextBlock")

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local function setText(text)
    if textBlock and textBlock:IsValid() then
        textBlock:SetText(FText(text))
    end
end

local function getVisibility()
    if statsWidget and statsWidget:IsValid() then
        return statsWidget:GetVisibility() ~= HIDDEN
    end
end

local function setVisibility(visible)
    if statsWidget and statsWidget:IsValid() then
        statsWidget:SetVisibility(visible and VISIBLE or HIDDEN)
    end
end

local function showWidget() setVisibility(true) end
local function hideWidget() if not useStats then setVisibility(false) end end -- do not hide stats
local function toggleWidget() setVisibility(not getVisibility()) end

local function setAlignment(slot, alignment)
    local b = 0

    local alignments = {
        center = {anchor = {0.5, 0.5}, align = {0.5, 0.5}, pos = {0, 0}},
        top = {anchor = {0.5, 0}, align = {0.5, 0}, pos = {0, b}},
        bottom = {anchor = {0.5, 1}, align = {0.5, 1}, pos = {0, -b}},
        topleft = {anchor = {0, 0}, align = {0, 0}, pos = {b, b}},
        topright = {anchor = {1, 0}, align = {1, 0}, pos = {-b, b}},
        bottomleft = {anchor = {0, 1}, align = {0, 1}, pos = {b, -b}},
        bottomright = {anchor = {1, 1}, align = {1, 1}, pos = {-b, -b}}
    }
    local a = alignments[alignment] or alignments.center
    slot:SetAnchors({Minimum = {X = a.anchor[1], Y = a.anchor[2]}, Maximum = {X = a.anchor[1], Y = a.anchor[2]}})
    slot:SetAlignment({X = a.align[1], Y = a.align[2]})
    slot:SetPosition({X = a.pos[1], Y = a.pos[2]})
end

local function createTextWidget()
    useStats = false
    if statsWidget and statsWidget:IsValid() then
        return
    end

    local gi = UEHelpers.GetGameInstance()
    widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("StatsWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("StatsSimpleTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("StatsCanvas"))
    widget.WidgetTree.RootWidget = canvas

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("StatsBG"))
    bg:SetBrushColor(FLinearColor(0,0,0,0.25))
    bg:SetPadding({Left = 15, Top = 10, Right = 15, Bottom = 10})

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetAutoSize(true)
    setAlignment(slot, alignment or "topleft")

    local text = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), bg, FName("StatsTextBlock"))
    text.Font.Size = 24
    text:SetColorAndOpacity(FSlateColor(1,1,1,1))
    text:SetShadowOffset({X = 1, Y = 1})
    text:SetShadowColorAndOpacity(FLinearColor(0,0,0,0.5))
    text:SetText(FText('Hello World!'))
    text:SetVisibility(VISIBLE)
    textBlock = text
    bg:SetContent(text)

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(VISIBLE)

    widget:AddToViewport(99)

    statsWidget = widget

    print("stats created", statsWidget:GetFullName(), textBlock:GetFullName())
end

local function toggleHelp()
    useStats = false
    setText(helpText)
    toggleWidget()
end

function distance(p1, p2)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local dz = p2.Z - p1.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getStats()
    local total = 0
    local found = 0

    local minDist = 1000000

    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() then return end

    local ploc = pc.PlayerCameraManager:GetCameraLocation()

    local entries = {"BP_Blackbox_Clickable_01a_C"};

    for _, entry in ipairs(entries) do

        for _, actor in ipairs(FindAllOf(entry) or {}) do
            if actor:IsValid() then
                total = total + 1

                -- print(actor:InteractionDistance(), actor:GetFullName()); -- to do, always returns 0

                if actor.bFound==true or actor.StartClosed==true then
                    found = found + 1
                else
                    -- not found, check coordinates
                    local loc = actor:K2_GetActorLocation()
                    local dist = distance(ploc, loc)
                    if dist<minDist then
                        minDist = dist
                    end
                end

            end
        end
    end

    if total==found then
        minDist = 0
    end

    local res = string.format("Press Alt+O to hide\nBlackboxes: %d of %d\nClosest: %.1f m", found, total, minDist/100)

    return(res)
end

local function toggleStats()
    setText(getStats())
    toggleWidget()
    useStats = true
end

local function updateWidget()
    if statsWidget and statsWidget:IsValid() then
        if not statsWidget:IsInViewport() then statsWidget:AddToViewport(99) end
    end
    if not getVisibility() then return end
    if not useStats then return end
    setText(getStats())
end

RegisterKeyBind(Key.O, {ModifierKey.ALT}, toggleStats ) -- Onscreen Objectives, thus "O"
RegisterKeyBind(Key.H, {ModifierKey.ALT}, toggleHelp)

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    createTextWidget()
    setText(helpText)
end)

LoopAsync(1000, updateWidget) -- update stats, and also re-add widget to viewport if removed between reloads
