-- Games and Puzzles

displayMode(FULLSCREEN_NO_BUTTONS)
-- displayMode(OVERLAY)
-- WIDTH,HEIGHT = 768,1024
function setup()
    cmodule "Games and Puzzles"
    cmodule.path("Library Base", "Library UI", "Library Graphics", "Library Utilities", "Library Maths", "Shaders")
    local Touches = cimport "Touch"
    local UI = cimport "UI"
    cimport "Menu"
    cimport "PictureBrowser"
    cimport "Keyboard"
    cimport "Utilities"
    cimport "VecExt"
    local Font = unpack(cimport "Font")
    local Anagram = cimport "Anagrams"
    local Hangman = cimport "Hangman"
    local SlidingPicture = cimport "SlidingPicture"
    local CoordinateGrid = cimport "CoordinateGrid"
    local Cubes = cimport "Cubes"
    local MentalMaths = cimport "MentalMaths"
    local Ladder = cimport "Ladders"
    touches = Touches()
    ui = UI(touches)
    local m = ui:systemmenu()
    m:addItem({
        title = "Show Touches",
        action = function() touches:showTouches(not touches.showtouch) return true end,
        highlight = function() return touches.showtouch end
    })
    local fontname = "HelveticaNeue"
    touchobjs = {}
    touches:pushHandlers(touchobjs)
    local img = image(1,1)
    setContext(img)
    pushMatrix()
    popMatrix()
    setContext()
    anagram = Anagram(
        Font({name = fontname,size = 256}),
        Font({name = fontname,size = 24}),
        ui
    )

    hangman = Hangman(
        Font({name = fontname, size = 64}),
        ui
        )
    
    spic = SlidingPicture(ui)
    grid = CoordinateGrid({ui = ui})
    cubes = Cubes(ui,touches)
    mmaths = MentalMaths(ui)
    ladder = Ladder(ui)
    local m = ui:addMenu({
        title = "Game",
        attach = true
    })
    local gm = ui:addMenu()
    gm:isChildOf(m)
    m:addItem({
        title = "Choose Game",
        action = function(x,y)
            gm.active = not gm.active
            gm.x = x
            gm.y = y
        end,
        highlight = function()
            return gm.active
        end,
        deselect = function()
            gm.active = false
        end,
    })
    m:addItem({
        title = "Game Options",
        action = function(x,y)
            GAME.options.active = not GAME.options.active
            GAME.options.x = x
            GAME.options.y = y
            end,
        highlight = function()
            return GAME.options.active
        end,
        deselect = function()
            GAME.options:deactivateDown()
        end,
    })
    for _,v in ipairs({
        {"Hangman", hangman},
        {"Anagrams", anagram},
        {"Picture Slider", spic},
        {"Coordinates", grid},
        {"Cube",cubes},
        {"Mental Maths",mmaths},
        {"Ladders",ladder}
    }) do
    gm:addItem({
        title = v[1],
        action = function()
                    switch(v[2])
                    return true
                end,
        highlight = function()
                    return GAME == v[2]
                end
    })
        v[2].options:isChildOf(m)
    end
    switch(cubes)
    orientationChanged = _orientationChanged

end

function draw()
    touches:draw()
    background(0,0,0)
    GAME:draw()
    ui:draw()
    touches:show()
    AtEndOfDraw()
end

function touched(touch)
    touches:addTouch(touch)
end

function switch(g)
    g = g or GAME
    if GAME then
        GAME:deactivate()
    end
    g:activate()
    GAME = g
    touchobjs[1] = g:touchReceiver() or touches:registerHandler(g)
end

function _orientationChanged(o)
    ui:orientationChanged(o)
end
