if _M then
    local Game = cimport "Game"
    
    MakeANumber = class(Game)
    
    function MakeANumber:init(u)
        Game.init(self,u)
        self.alltiles = true
        self.exact = true
        self.tileset = 1
        self.oplevel = 1
        self.tilesets = {
            {25,50,100,200},
            {25,50,75,100},
            {12,37,62,87}
        }
        local m = self.options
        self.ui = u
        local lm = self.ui:addMenu()
        lm:isChildOf(m)
        m:addItem({
            title = "Tile Difficulty",
            action = function(x,y)
                lm.active = not lm.active
                lm.x = x
                lm.y = y
            end,
            highlight = function()
                return lm.active
            end,
            deselect = function()
                lm.active = false
            end,
        })
        for _,v in ipairs({
            {"Easy", 1},
            {"Medium", 2},
            {"Hard", 3}
        }) do
            lm:addItem({
                title = v[1],
                action = function()
                    self.tileset = v[2]
                    return true
                end,
                highlight = function()
                    return self.tileset == v[2]
                end
            })
        end
        local om = self.ui:addMenu()
        om:isChildOf(m)
        m:addItem({
            title = "Operation Difficulty",
            action = function(x,y)
                om.active = not om.active
                om.x = x
                om.y = y
            end,
            highlight = function()
                return om.active
            end,
            deselect = function()
                om.active = false
            end,
        })
        for _,v in ipairs({
            {"Easy", 1},
            {"Medium", 2},
            {"Hard", 3}
        }) do
            om:addItem({
                title = v[1],
                action = function()
                    self.oplevel = v[2]
                    return true
                end,
                highlight = function()
                    return self.oplevel == v[2]
                end
            })
        end
        m:addItem({
            title = "Exact target",
            action = function()
                self.exact = not self.exact
                return true
            end,
            highlight = function()
                return self.exact
            end
        })
        m:addItem({
            title = "Must use all tiles",
            action = function()
                self.alltiles = not self.alltiles
                return true
            end,
            highlight = function()
                return self.alltiles
            end
        })
    end
    
    function MakeANumber:activate()
        
    end
    
    function MakeANumber:getTarget()
        
    end
    
end
