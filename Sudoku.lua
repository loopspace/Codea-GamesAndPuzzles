if _M then
    local Game = cimport "Game"
    local _,Sentence,_ = unpack(cimport "Font")
    local Cell, Block = class(), class()
    local symmetry
    Sudoku = class(Game)

    function Sudoku:init(u)
        Game.init(self,u)
        self.ui = u
        self:setStandardGrid()
        self.helpful = true
        self.choices = false
        local phi = (math.sqrt(5) + 1)/2
        self.xtraBlocks = 0
        local m = self.options 
        self.theme = 0
        self.hcells = {}
        local it
        it = m:addItem({
        title = "Light Theme",
        action = function()
            self.theme = 1 - self.theme
            if self.theme == 1 then
    it.title = Sentence(m.font,"Dark Theme")
    it.title:setColour(m.textColour)

            else
    it.title = Sentence(m.font,"Light Theme")
    it.title:setColour(m.textColour)
            end
            return true
        end
        })
        m:addItem({
        title = "Set size",
        action = function()
        u:getNumberSpinner({
        action = function (n)
            self:setSize(n)
                self:reset()
            return true
        end,
        value = self.size
        })
            return true
        end
        })
        m:addItem({
        title = "Standard Grid",
        action = function()
            self:setStandardGrid()
            return true
        end
        })
        m:addItem({
        title = "New Block",
        action = function()
            self.newBlock = Block()
            table.insert(self.blocks,self.newBlock)
            self.newBlock.bgcolour = color():new("hsv",self.xtraBlocks * phi,.5,.5)
            self.xtraBlocks = self.xtraBlocks + 1
            if self.gridpt then
                    self.gridpt.gridtnum = nil
                    self.gridpt = nil
                    self.gridtpt = nil
                    self:saveState()
            end
            return true
        end,
        highlight = function()
            return self.newBlock
        end
        })
        m:addItem({
        title = "Delete Last Block",
        action = function()
            if self.xtraBlocks > 0 then
                self.newBlock = nil
                local b = table.remove(self.blocks)
                b:clearCells()
            end
            return true
        end,
        disable = function()
            return self.xtraBlocks == 0
        end
        })
        m:addItem({
        title = "Be helpful",
        action = function()
            self.helpful = not self.helpful
            return true
        end,
        highlight = function()
            return self.helpful
        end
        })
        m:addItem({
        title = "Show choices",
        action = function()
            self.choices = not self.choices
            return true
        end,
        highlight = function()
            return self.choices
        end
        })
        m:addItem({
        title = "Undo",
        action = function()
            self:doundo()
            return true
        end,
        disable = function()
            return #self.undo == 0
        end
        })
        m:addItem({
        title = "Redo",
        action = function()
            self:doredo()
            return true
        end,
        disable = function()
            return #self.redo == 0
        end
        })
        m:addItem({
        title = "Add checkpoint",
        action = function()
            self:addCheckpoint()
            return true
        end
        })
        m:addItem({
        title = "Last checkpoint",
        action = function()
            self:lastCheckpoint()
            return true
        end,
        disable = function()
            return #self.checkpoints == 0
        end
        })
        m:addItem({
        title = "Save game",
        action = function()
            self:saveGame()
            return true
        end
        })
        m:addItem({
        title = "Load game",
        action = function()
            self:loadGame()
            return true
        end
        })
        m:addItem({
        title = "Clear",
        action = function()
            self:clear()
            return true
        end
        })
        m:addItem({
        title = "Reset",
        action = function()
            self:reset()
            return true
        end
        })
        m:addItem({
        title = "Add Forced",
        action = function()
            self:addForced()
            return true
        end
        })
        m:addItem({
        title = "Solve",
        action = function()
            for k,u in ipairs(self.cells) do
                if not u.solution then
                    table.insert(self.hcells,u)
                end
            end
            local t = {}
            self:solve(t,false,0)
            if #t == 1 then
                self:solve(t,true,0)
            elseif #t == 0 then
                ui:addNotice({text = "No solutions found"})
            else
                ui:addNotice({text = "Multiple solutions found"})
            end
            return true
        end
        })
        
        m:addItem({
        title = "Classify",
        action = function()
            local score = {{},{}}
            local t = {}
            self:solve(t,false,10,score)

            local s = 0
            for k,v in ipairs(score[1]) do
                s = math.max(s,v)
            end

            local d = {"Easy", "Medium", "Hard", "Fiendish", "Super Fiendish"}
            ui:addNotice({text = "Difficulty level: ".. d[s]})
            return true
        end
        })
        
        local level = 1
        local sym = 1
        local gm = ui:addMenu()
        local sm = ui:addMenu()
        local lm = ui:addMenu()
        m:addSubMenu("Generate",gm)

        lm:addItem({
        title = "Easy",
        action = function()
            level = 1
            return true
        end,
        highlight = function()
            return level == 1
        end,
        })
        lm:addItem({
        title = "Medium",
        action = function()
            level = 2
            return true
        end,
        highlight = function()
            return level == 2
        end,
        })
        lm:addItem({
        title = "Hard",
        action = function()
            level = 3
            return true
        end,
        highlight = function()
            return level == 3
        end,
        })
        lm:addItem({
        title = "Fiendish",
        action = function()
            level = 4
            return true
        end,
        highlight = function()
            return level == 4
        end,
        })
        lm:addItem({
        title = "Super Fiendish",
        action = function()
            level = 5
            return true
        end,
        highlight = function()
            return level == 5
        end,
        })
        gm:addSubMenu("Level",lm, false)
        gm:addSubMenu("Symmetry",sm, false)
        sm:addItem({
        title = "Identity",
        action = function()
            sym = 1
            return true
        end,
        highlight = function()
            return sym == 1
        end,
        })
        sm:addItem({
        title = "Rotation 180",
        action = function()
            sym = 2
            return true
        end,
        highlight = function()
            return sym == 2
        end,
        })
        sm:addItem({
        title = "Rotation 90",
        action = function()
            sym = 3
            return true
        end,
        highlight = function()
            return sym == 3
        end,
        })
        sm:addItem({
        title = "Reflection /",
        action = function()
            sym = 4
            return true
        end,
        highlight = function()
            return sym == 4
        end,
        })
        sm:addItem({
        title = "Reflection -",
        action = function()
            sym = 5
            return true
        end,
        highlight = function()
            return sym == 5
        end,
        })
        sm:addItem({
        title = "Reflection \\",
        action = function()
            sym = 6
            return true
        end,
        highlight = function()
            return sym == 6
        end,
        })
        sm:addItem({
        title = "Reflection |",
        action = function()
            sym = 7
            return true
        end,
        highlight = function()
            return sym == 7
        end,
        })
        sm:addItem({
        title = "Reflections X",
        action = function()
            sym = 8
            return true
        end,
        highlight = function()
            return sym == 8
        end,
        })
        sm:addItem({
        title = "Reflections +",
        action = function()
            sym = 9
            return true
        end,
        highlight = function()
            return sym == 9
        end,
        })
        gm:addItem({
        title = "Generate",
        action = function()
            self:generate(sym,level)
            return true
        end
        })
    end
    
    function Sudoku:setSize(n)
        self.size = n
        self.cellSize = math.ceil(math.sqrt(n))
        self.charWidth = self.size*self.cellSize
    end
    
    function Sudoku:getIndex(i,j)
        if type(i) == "table" then
            i,j = i[1],i[2]
        elseif type(i) == "userdata" and getmetatable(i) == getmetatable(vec2()) then
            i,j = i.x,i.y
        end
        return (i-1)*self.size + j
    end
    
    function Sudoku:reset()
        self.coroutine = nil
        self.checkpoints = {}
        self.undo = {}
        self.redo = {}
        
        self.cells = {}
        self.blocks = {}
        self.hcells = {}
        self.xtraBlocks = 0
        
        for i=1,self.size do
            for j=1,self.size do
                table.insert(self.cells,Cell(i,j,self))
            end
        end
        
        self:setLines()
        self:saveState()
    end
    
    function Sudoku:clear()
        self.coroutine = nil
        self.checkpoints = {}
        self.undo = {}
        self.redo = {}
        
        self.hcells = {}
        
        for k,c in ipairs(self.cells) do
            c:clear()
        end
        
        self:saveState()
    end
    
    function Sudoku:setLines()
        local r,c,b
        for j=1,self.size do
            r = Block()
            for i=1,self.size do
                r:addCell(self.cells[self:getIndex(i,j)])
            end
            r.isLine = true
            table.insert(self.blocks,r)
        end
        for i=1,self.size do
            c = Block()
            for j=1,self.size do
                c:addCell(self.cells[self:getIndex(i,j)])
            end
            c.isLine = true
            table.insert(self.blocks,c)
        end
    end
        
    function Sudoku:setStandardGrid()
        self:setSize(9)
        self:reset()
        local b
        for x=1,3 do
            for y=1,3 do
                b = Block()
                for i=1,3 do
                    for j=1,3 do
                        b:addCell(self.cells[self:getIndex((x-1)*3+i,(y-1)*3+j)])
                    end
                end
                table.insert(self.blocks,b)
            end
        end
    end
    
    function Sudoku:addCheckpoint()
        table.insert(self.checkpoints,#self.undo)
    end
    
    function Sudoku:lastCheckpoint()
        local t = table.remove(self.checkpoints)
        while t < #self.undo do
            self:doundo()
        end
    end
    
    function Sudoku:getState()
        local g, s = {}, {}
        for k,c in ipairs(self.cells) do
            table.insert(s,c.solution)
            table.insert(g,c.numbers)
        end
        return g,s
    end
    
    function Sudoku:setState(g,s)
        if not s then
            g,s = g[1], g[2]
        end
        for k,v in ipairs(s) do
            self.cells[k].solution = v
        end
        for k,v in ipairs(g) do
            self.cells[k].numbers = v
        end
    end
    
    function Sudoku:saveState()
        local t = self.undo[#self.undo]
        local g,s = self:getState()
        if t then
            if deepequal(t, {g,s}) then
                return
            end
        end
        table.insert(self.undo,{g,s})
        self.redo = {}
    end

    function Sudoku:doundo()
        if #self.undo > 1 then
            local t = table.remove(self.undo)
            table.insert(self.redo,t)
        end
        t = self.undo[#self.undo]
        self:setState(t[1],t[2])
    end
    
    function Sudoku:doredo()
        if #self.redo > 0 then
            local t = table.remove(self.redo)
            table.insert(self.undo,t)
            self:setState(t[1],t[2])
        end
    end
    
    function Sudoku:saveGame()
        local g,s = self:getState()
        local bk = {}
        local cl = {}
        local tb
        local nb = 0
        for k,b in ipairs(self.blocks) do
            if not b.isLine then
                nb = nb + 1
                tb = {}
                if b.bgcolour then
                    cl[nb] = {b.bgcolour.r,b.bgcolour.g,b.bgcolour.b,b.bgcolour.a}
                end
                for l,c in ipairs(b.cells) do
                    table.insert(tb,c.index)
                end
                table.insert(bk,tb)
            end
        end
        local t = {self.size,bk,cl,g,s,self.checkpoints}
        local s = json.encode(t)
        saveProjectData("Sudoku",s)
    end
    
    function Sudoku:loadGame()
        local s = readProjectData("Sudoku")
        if not s then
            return
        end
        local t = json.decode(s)
        self:setSize(t[1])
        self:reset()
        local b
        local phi = (math.sqrt(5) + 1)/2
        for k,v in ipairs(t[2]) do
            b = Block()
            for l,u in ipairs(v) do
                b:addCell(self.cells[self:getIndex(u)])
            end
            table.insert(self.blocks,b)
            if t[3][k] then
                b.bgcolour = color(t[3][k][1],t[3][k][2],t[3][k][3],t[3][k][4])
                self.xtraBlocks = self.xtraBlocks + 1
            end

        end
        self:setState(t[4],t[5])
        self.checkpoints = t[6]
        self.last = self.checkpoints[#self.checkpoints]
    end
    
    function Sudoku:draw()
        pushMatrix()
        pushStyle()
        noStroke()
        lineCapMode(PROJECT)
        translate(WIDTH/2,HEIGHT/2)
        local s = math.min(WIDTH,HEIGHT)
        local chw = self.charWidth
        s = s - s%chw
        local w = s/chw
        self.width = w
        fontSize(w)
        self.centre = vec2(WIDTH,HEIGHT)/2
        translate(-w*chw/2,-w*chw/2)
        fill(self.theme*255)
        rect(-10,-10,s+20,s+20)
        for k,b in ipairs(self.blocks) do
            b:fill(self.theme)
        end
        if self.newBlock then
            self.newBlock:highlight()
        end
        for k,v in ipairs(self.hcells) do
            v:fill(color(168, 166, 48, 255))
        end
        if self.gridtpt then
            self.gridtpt:fill(color(233, 255, 0, 255))
        end
        for k,b in ipairs(self.blocks) do
            b:draw()
        end
        for k,c in ipairs(self.cells) do
            c:draw()
        end
        stroke(255*(1-self.theme))
        strokeWidth(1)
        for i=1,self.size+1 do
            line((i-1)*self.cellSize*w,0,(i-1)*self.cellSize*w,chw*w)
            line(0,(i-1)*self.cellSize*w,chw*w,(i-1)*self.cellSize*w)
        end
        
        if self.gridpt then
            pushMatrix()
            translate(w*chw/2,w*chw/2)
            self.gridpt:drawBig()
            popMatrix()
        end
        if self.coroutine then
            if not self.coroutine() then
                self.coroutine = nil
            end
            translate(w*chw/2,w*chw/2)
            local da
            noStroke()
            for k=1,10 do
                da = (math.floor((2*self.theme - 1)*ElapsedTime*10) + k)*math.pi/10
                fill(255-25*k)
                ellipse(50*math.cos(da),50*math.sin(da),5)
            end
        end
        popStyle()
        popMatrix()
        
    end

    function Sudoku:isTouchedBy(t)
        local tpt = vec2(t.x,t.y) - self.centre

        if tpt:leninf() < self.width*self.charWidth/2 then
            if self.gridpt then
                local n = (tpt/self.width/4*3/self.cellSize + vec2(self.cellSize/2,self.cellSize/2))//1
                if n.x >= 0 and n.x < self.cellSize and n.y >= 0 and n.y < self.cellSize then
                    self.gridpt.gridtnum = n
                    self.gridtnum = self.gridpt.gridtnum
                else
                    self.gridpt.gridtnum = nil
                    self.gridpt = nil
                    self.gridtpt = nil
                    self.ignoretouch = true
                    self:saveState()
                end
            else
                local v = (tpt/self.width/self.cellSize + vec2(self.size/2+1,self.size/2+1))//1
                self.gridtpt = self.cells[self:getIndex(v)]
            end
            return true
        elseif self.newBlock then
            self.newBlock = nil
            self.gridtpt = nil
            self.ignoretouch = true
            return true
        end
        return false
    end
    
    function Sudoku:processTouches(g)
        if self.ignoretouch then
            if g.type.ended then
                g:reset()
                self.ignoretouch = false
            end
            g:noted()
            return
        end
        local t = g.touchesArr[1].touch
        local tpt = vec2(t.x,t.y) - self.centre
        if self.gridpt then
            local n = (tpt/self.width/4*3/self.cellSize + vec2(self.cellSize/2,self.cellSize/2))//1
            if n.x >= 0 and n.x < self.cellSize and n.y >= 0 and n.y < self.cellSize then
                self.gridpt.gridtnum = n
                if (not g.type.short or (g.type.ended and not self.choices)) and self.gridtnum == self.gridpt.gridtnum then
                    self.gridpt:toggleSolution(math.floor(n.x + self.cellSize*n.y+1))
                    self.gridpt.gridtnum = nil
                    self.gridpt = nil
                    self.gridtpt = nil
                    self:saveState()
                    g:reset()
                end
            else
                self.gridpt.gridtnum = nil
            end
        else
            local v = (tpt/self.width/self.cellSize + vec2(self.size/2+1,self.size/2+1))//1
            self.gridtpt = self.cells[self:getIndex(v)]
        end
        if g.type.ended then
            if not self.gridpt then
                local v = (tpt/self.width/self.cellSize + vec2(self.size/2+1,self.size/2+1))//1
                if self.newBlock then
                    self.newBlock:toggleCell(self.cells[self:getIndex(v)])
                    self.gridtpt = nil
                else
                    self.gridpt = self.cells[self:getIndex(v)]
                    self.gridtpt = self.gridpt
                end
            else
                if self.choices then
                    local n = (tpt/self.width/4*3/self.cellSize + vec2(self.cellSize/2,self.cellSize/2))//1
                    if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2 then
                        n = n.x + self.cellSize*n.y+1
                        self.gridpt:toggleNumber(n)
                    end
                end
                self.gridpt.gridtnum = nil
            end
            g:reset()
        end
        g:noted()
    end

    function Sudoku:solve(t,b,lvl,score)
        local th,rt = coroutine.running()
        if not rt then
            if os.clock() - self.cstart > .1 then
                coroutine.yield(true)
                self.cstart = os.clock()
            end
        end
        
        local cells = {}
        score = score or {{},{}}
        local nscore

        local nc = 0
        for k,u in ipairs(self.cells) do
            if not u.solution then
                if u:getFree() == 0 then
                    -- no free numbers on this cell, no solution possible
                    return false
                end
                table.insert(cells,u)
                nc = nc + 1
            end
        end
        --[[
        for k,u in ipairs(self.blocks) do
            if not u:checkValid() then
                return false
            end
        end
--]]
        if nc == 0 then
            -- no free cells left, solution found
            local s = {}
            for k,u in ipairs(self.cells) do
                table.insert(s,u.solution)
            end
            table.insert(t,s)
            for k,v in ipairs(score[2]) do
                score[1][k] = v
            end
            return true
        end
        local state = {self:getState()}
        local actions = {}
        if lvl == 0 then
            -- Solution by any means 
            table.sort(cells, function(a,b)
                    if a:getFree() ~= b:getFree() then
                        return a:getFree() < b:getFree()
                    end
                    if a.numblocks ~= b.numblocks then
                        return a.numblocks > b.numblocks
                    end
                    return a.blockints > b.blockints
            end)
            local c = cells[1]
            local p = KnuthShuffle(c.size)
            for k=1,c.size do
                if c:isFree(p[k]) then
                    table.insert(actions, function() c:toggleSolution(p[k]) end)
                end
            end
        else
            -- Solution by human methods


            local r,m
            -- First stage, look for a forced cell
            for k,v in ipairs(cells) do
                r,m = v:isForced()
                if r then
                    table.insert(actions, function() v:toggleSolution(m) end)
                    local nf,nr = 0,0
                    for j,c in ipairs(cells) do
                        nr = nr + 1
                        if c:isForced() then
                            nf = nf + 1
                        end
                    end
                    if nf < math.min(10,nr/2) then
                        nscore = 2
                    else
                        nscore = 1
                    end
                    break
                end
            end

            if not r and lvl > 2 then
                -- Second stage, look for possibilities to eliminate
                -- Start with the intersection rule
                local numb = #self.blocks
                local int,cpa,cpb,na,nb
                for k=1,numb-1 do
                    for l=k+1,numb do
                        int,cpa,cpb = self.blocks[k]:intersection(self.blocks[l])
                        na = 0
                        for i,c in ipairs(cpa) do
                            if not c.solution then
                                na = na | c.numbers
                            else
                                na = na | 2^(c.solution - 1)
                            end
                        end
                        nb = 0
                        for i,c in ipairs(cpb) do
                            if not c.solution then
                                nb = nb | c.numbers
                            else
                                nb = nb | 2^(c.solution - 1)
                            end
                        end
                        if na ~= nb then
                            table.insert(actions, function()
                                    for i,c in ipairs(cpa) do
                                        c.numbers = c.numbers & nb
                                    end
                                    for i,c in ipairs(cpb) do
                                        c.numbers = c.numbers & na
                                    end
                                end
                                )
                            r = true
                            nscore = 3
                            -- lvl = lvl - 1
                            break
                        end

                    end
                    if r then
                        break
                    end
                end
                if not r and lvl > 3 then
                    local ck,na
                    for l,bk in ipairs(self.blocks) do
                        ck,na = bk:partition()
                        if ck then
                            table.insert(actions, function()
                                for j,c in ipairs(ck) do
                                    c.numbers = c.numbers & na
                                end
                            end)
                            nscore = 4
                            r = true
                            break
                        end
                    end
                end
            end
            
            if not r and lvl > 4 then

                table.sort(cells, function(a,b)
                    if a:getFree() ~= b:getFree() then
                        return a:getFree() < b:getFree()
                    end
                    if a.numblocks ~= b.numblocks then
                        return a.numblocks > b.numblocks
                    end
                    return a.blockints > b.blockints
                end)
                local c = cells[1]
                local p = KnuthShuffle(c.size)
                for k=1,c.size do
                    if c:isFree(p[k]) then
                        -- print("Guessing in " .. c.index[1] .. "," .. c.index[2] .. " with " .. p[k])
                        table.insert(actions, function() c:toggleSolution(p[k]) end)
                        table.insert(actions, function() c:remove(p[k]) end)
                        break
                    end
                end
                nscore = 5
                r = true
            end

            if not r then
                return false
            end
        end

        table.insert(score[2], nscore)
        for k,f in ipairs(actions) do
            f()

            if self:solve(t,b,lvl,score) then
                if not b then
                    self:setState(state)
                end
                return true
            end
            self:setState(state)
        end
        table.remove(score[2])


        return false
    end
    
    function Sudoku:addForced()
        local wasForced = true
        local ret,n
        while wasForced do
            wasForced = false
            for k,c in ipairs(self.cells) do
                ret,n = c:isForced()
                if ret then
                    c:toggleSolution(n)
                    wasForced = true
                end
            end
        end
    end
    
    symmetry = {}
    local unique = function(t)
        local s = {}
        local r = {}
        for k,v in ipairs(t) do
            if not r[v] then
                table.insert(s,v)
                r[v] = true
            end
        end
        return s
    end
    
    local split = function(k,n) return (k-1)%n - (n-1)/2, (k-1)//n - (n-1)/2 end
    local combine = function(i,j,n) return math.floor((j + (n-1)/2)*n + i + (n-1)/2 + 1) end
    local rot = function(i,j,n) return -j,i,n end
    local ref = function(i,j,n) return  j,i,n end
    
    symmetry[1] = function(k,n) return {k} end
    symmetry[2] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(rot(i,j,n))) }) end
    symmetry[3] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(i,j,n)), combine(rot(rot(i,j,n))), combine(rot(rot(rot(i,j,n)))) }) end
    symmetry[4] = function(k,n) local i,j = split(k,n) return unique({k, combine(ref(i,j,n)) }) end
    symmetry[5] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(ref(i,j,n))) }) end
    symmetry[6] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(rot(ref(i,j,n)))) }) end
    symmetry[7] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(rot(rot(ref(i,j,n))))) }) end
    symmetry[8] = function(k,n) local i,j = split(k,n) return unique({k, combine(ref(i,j,n)), combine(rot(rot(ref(i,j,n)))), combine(rot(rot(i,j,n))) }) end
    symmetry[9] = function(k,n) local i,j = split(k,n) return unique({k, combine(rot(ref(i,j,n))), combine(rot(rot(rot(ref(i,j,n))))), combine(rot(rot(i,j,n))) }) end
    
    function Sudoku:reduce(b,lvl)
        local cells = {}
        local nc = 0
        for k,u in ipairs(self.cells) do
            if u.solution then
                table.insert(cells,u)
                nc = nc + 1
            end
        end
        local p = KnuthShuffle(nc)
        local t,n,m,l
        local nf,nr,reset
        for k=1,nc do
            if cells[p[k]].solution then
                l = symmetry[b](p[k],self.size)
                m = {}
                for j,v in ipairs(l) do
                    table.insert(m,cells[v].solution)
                    cells[v]:toggleSolution(cells[v].solution)
                end
                
                t = {}
                nf = 0
                nr = 0
                for k,c in ipairs(self.cells) do
                    if not c.solution then
                        nr = nr + 1
                        if c:isForced() then
                            nf = nf + 1
                        end
                    end
                end
                self:solve(t,false,lvl)
                
                reset = false
                if #t ~= 1 then
                    reset = true
                end
                if lvl == 1 and nf < math.min(10,nr/2) then
                    -- Easy: either half or 10 forceable cells
                    reset = true
                end
                if reset then
                    for j,v in ipairs(l) do
                        cells[v]:toggleSolution(m[j])
                    end
                end
                
            end
        end
        local score = {{},{}}
        t = {}
        self:solve(t,false,lvl,score)
        local s = 0
        for k,v in ipairs(score[1]) do
            s = math.max(s,v)
        end
        -- print(s)
        d = {"Easy", "Medium", "Hard", "Fiendish", "Super Fiendish"}
        self.ui:addNotice({text = "Difficulty level: ".. d[s]})
        -- print(table.concat(score[1],", "))
    end
    
    function Sudoku:countIntersections()
        local c
        for k,v in ipairs(self.blocks) do
            v.numints = 0
            for l,u in ipairs(self.blocks) do
                c,_,_ = v:intersection(u)
                if #c > 0 then
                    v.numints = v.numints + 1
                end
            end
        end
        local m
        for k,v in ipairs(self.cells) do
            m = 0
            for l,u in ipairs(v.blocks) do
                m = math.max(m, u.numints)
            end
            v.blockints = m
        end
    end
    
    function Sudoku:generate(b,l)
        local s = {}
        
        self.hcells = {}
        self:countIntersections()
        self.coroutine = coroutine.wrap(function() 
            self:solve(s,true,0)
                self:reduce(b,l)
            end)
            self.cstart = os.clock()
    end
    
    function Cell:init(i,j,s)
        self.blocks = {}
        self.index = {i,j}
        self.numbers = 2^s.size - 1
        self.size = s.size
        self.solution = false
        self.puzzle = s
        self.numblocks = 0
        self.blockints = 0
    end
    
    function Cell:clear()
        self.numbers = 2^self.size - 1
        self.solution = false
    end
    
    function Cell:draw()
        local w = self.puzzle.width
        local s = self.puzzle.size
        local cs = self.puzzle.cellSize
        local i = self.index[1]
        local j = self.index[2]
        if self.solution then
            pushStyle()
            fill(255*(1-self.puzzle.theme))
            fontSize(3*fontSize())
            text(self.solution, (i-.5)*cs*w, (j-.5)*cs*w)
            popStyle()
        else
            if not self.puzzle.choices then
                return
            end
            for k=1,self.size do
                self:style(k)
                text(k,((i-1)*cs + (k-1)%cs + .5)*w, ((j-1)*cs + (k-1)//cs + .5)*w)
            end
        end
    end
    
    function Cell:drawBig()
        local w = self.puzzle.width
        local cs = self.puzzle.cellSize
        fill(40+175*self.puzzle.theme)
        rect(-2*cs*w,-2*cs*w,w*cs*4,w*cs*4)
        if self.gridtnum then
            fill(233, 255, 0, 255)
            rect(4*(self.gridtnum - vec2(cs/2,cs/2))*w,4*w,4*w)
        end
        fontSize(4*fontSize())
        for k=1,self.size do
            if self.solution == k then
                fill(220, 0, 255, 255)
            else
                if self:isFree(k) or not self.puzzle.choices then
                    fill(255*(1-self.puzzle.theme))
                else
                    fill(127, 127, 127, 255)
                end
            end
            text(k,(-1.5+(k-1)%cs + .5)*w*4, (-1.5 + (k-1)//cs + .5)*w*4)
        end
    end
    
    function Cell:fill(c)
        pushStyle()
        fill(c)
        noStroke()
        local w = self.puzzle.width*self.puzzle.cellSize
        local i = self.index[1]
        local j = self.index[2]
        rect((i-1)*w,(j-1)*w,w,w)
        popStyle()
    end
    
    function Cell:isForced()
        if self.solution then
            return false
        end
        if self:getFree() == 1 then
            local v = self.numbers
            for k=1,self.size do
                if v == 1 then
                    return true,k
                end
                v = v >> 1
            end
        end
        local n
        for k=1,self.size do
            if self.numbers & 2^(k-1) ~= 0 then
                for i,b in ipairs(self.blocks) do
                    n = 0
                    for j,c in ipairs(b.cells) do
                        if not c.solution and c.numbers & 2^(k-1) ~= 0 then
                            n = n + 1
                        end
                    end
                    if n == 1 then
                        return true,k
                    end
                end
            end
        end
        return false
    end
    
    function Cell:style(k)
        if not self:isFree(k) then
            -- user has removed this value
        fill(255*(1-self.puzzle.theme),63)
            return
        end
        --[[
        -- look for a block with a cell set to this value
        for i,b in ipairs(self.blocks) do
            for j,c in ipairs(b.cells) do
                if c.solution == k then
                    fill(0, 0, 0, 0)
                    return
                end
            end
        end
        --]]
        -- look for a block without this value
        if self.puzzle.helpful then
            local n
            if self:getFree() == 1 then
                fill(0, 252, 255, 255)
                return
            end
            for i,b in ipairs(self.blocks) do
                n = 0
                for j,c in ipairs(b.cells) do
                    if not c.solution and c.numbers & 2^(k-1) ~= 0 then
                        n = n + 1
                    end
                end
                if n == 0 then
                    fill(255,0,0,255)
                    return
                end
                if n == 1 then
                    fill(0, 255, 255, 255)
                    return
                end
            end
        end
        fill(255*(1-self.puzzle.theme))
    end
    
    function Cell:addBlock(b)
        for k,v in ipairs(self.blocks) do
            if v == b then
                return
            end
        end
        table.insert(self.blocks,b)
        b:addCell(self)
        self.numblocks = self.numblocks + 1 
    end
    
    function Cell:removeBlock(b)
        local l
        for k,v in ipairs(self.blocks) do
            if v == b then
                l = k
            end
        end
        if l then
            table.remove(self.blocks,l)
            b:removeCell(self)
            self.numblocks = self.numblocks - 1
        end
    end
    
    function Cell:contained(b)
        for k,v in ipairs(self.blocks) do
            if v == b then
                return true
            end
        end
        return false
    end
    
    function Cell:getFree()
        local v = self.numbers
        local n = 0
        while v > 0 do
            n =n + (v & 1)
            v = v >> 1
        end
        return n
    end
    
    function Cell:isFree(k)
        return not (self.numbers & 2^(k-1) == 0)
    end
    
    function Cell:getPosition()
        local w = self.puzzle.width*self.puzzle.cellSize
        local i = self.index[1]
        local j = self.index[2]
        return (i-1)*w, (j-1)*w, w
    end
    
    function Cell:getNeighbour(n)
        -- 1 is East
        -- 2 is North
        -- 3 is West
        -- 4 is South
        local i = self.index[1]
        local j = self.index[2]
        if n == 1 then
            i = i + 1
        elseif n == 2 then
            j = j + 1
        elseif n == 3 then
            i = i - 1
        else
            j = j - 1
        end
        return self.puzzle.cells[self.puzzle:getIndex(i,j)]
    end
    
    function Cell:drawBorder(n)
        -- 1 is East
        -- 2 is North
        -- 3 is West
        -- 4 is South
        stroke(255*(1-self.puzzle.theme))
        local i = self.index[1]
        local j = self.index[2]
        local w = self.puzzle.cellSize*self.puzzle.width
        if n == 1 then
            line(i*w,(j-1)*w,i*w,j*w)
        elseif n == 2 then
            line((i-1)*w,j*w,i*w,j*w)
        elseif n == 3 then
            line((i-1)*w,(j-1)*w,(i-1)*w,j*w)
        else
            line((i-1)*w,(j-1)*w,i*w,(j-1)*w)
        end
    end
    
    function Cell:toggleSolution(n)
        if n > self.puzzle.size or n < 1 then
            return
        end
        local s = self.solution
        self.solution = false
        if s then
            for k,b in ipairs(self.blocks) do
                b:add(s,self)
            end
        end
        if s ~= n then
            self.solution = n
            self.numbers = self.numbers | 2^(n-1)
            for k,b in ipairs(self.blocks) do
                b:remove(n,self)
            end
        end
    end
    
    function Cell:remove(n)
        if n > self.puzzle.size or n < 1 then
            return
        end
        self.numbers = self.numbers & (~ 2^(n-1))
    end
    
    function Cell:add(n)
        if n > self.puzzle.size or n < 1 then
            return
        end
        local a = true
        for k,v in ipairs(self.blocks) do
            a = a and not v:hasSolution(n)
        end
        if a then
            self.numbers = self.numbers | 2^(n-1)
        else
            self.numbers = self.numbers & (~ 2^(n-1))
        end
    end
    
    function Cell:toggleNumber(n)
        if n > self.puzzle.size or n < 1 then
            return
        end
        
        self.numbers = self.numbers ~ 2^(n-1)
    end
    
    function Block:init()
        self.cells = {}
        self.isLine = false
    end
    
    function Block:fill(t)
        pushStyle()
        
        if self.bgcolour then
            for k,c in ipairs(self.cells) do
                c:fill(self.bgcolour:xblend(75,color(t*255)))
            end
        end

        local fc
        if not self:checkValid() then
            for k,c in ipairs(self.cells) do
                c:fill(color(255, 0, 0, 255))
            end
        end
        popStyle()
    end
    
    function Block:draw()
        pushStyle()
        
        if not self.isLine then
            strokeWidth(4)
            local b
            for k,c in ipairs(self.cells) do
                for i=1,4 do
                    b = c:getNeighbour(i)
                    if b then
                        if not self:contains(b) then
                            c:drawBorder(i)
                        end
                    else
                        c:drawBorder(i)
                    end
                end
            end
        end
        popStyle()
    end
    
    function Block:checkValid()
        -- a block is invalid if it has fewer numbers than cells
        local n = 0
        local b = 0
        for i,c in ipairs(self.cells) do
            if c.solution then
                n = n | 2^(c.solution - 1)
            else
                n = n | c.numbers
            end
            b = b + 1
        end
        local c = 0
        while n > 0 do
            c = c + (n &1)
            n = n >> 1
        end
        if c < b then
            return false
        end
        return true
    end
    
    function Block:highlight()
        for k,v in ipairs(self.cells) do
            v:fill(color(0, 250, 255, 255))
        end
    end
    
    function Block:addCell(c)
        for k,v in ipairs(self.cells) do
            if v == c then
                return
            end
        end
        table.insert(self.cells,c)
        c:addBlock(self)
    end
    
    function Block:removeCell(c)
        local l
        for k,v in ipairs(self.cells) do
            if v == c then
                l = k
                break
            end
        end
        if l then
            table.remove(self.cells,l)
            c:removeBlock(self)
        end
    end
    
    function Block:clearCells()
        local cl = {}
        for k,v in ipairs(self.cells) do
            table.insert(cl,v)
        end
        self.cells = {}
        for k,c in ipairs(cl) do
            c:removeBlock(self)
        end
    end
    
    function Block:toggleCell(c)
        if self:contains(c) then
            self:removeCell(c)
        else
            self:addCell(c)
        end
    end
    
    function Block:contains(c)
        for k,v in ipairs(self.cells) do
            if v == c then
                return true
            end
        end
        return false
    end
    
    function Block:remove(n,c)
        for k,v in ipairs(self.cells) do
            if v ~= c then
                v:remove(n)
            end
        end
    end
    
    function Block:add(n,c)
        for k,v in ipairs(self.cells) do
            if v ~= c then
                v:add(n)
            end
        end
    end
    
    function Block:hasSolution(n)
        for k,c in ipairs(self.cells) do
            if c.solution == n then
                return true
            end
        end
        return false
    end
    
    function Block:intersection(b)
        -- get the intersection and the complements
        local cl,cp,bp = {},{},{}
        for k,c in ipairs(self.cells) do
            if c:contained(b) then
                table.insert(cl,c)
            else
                table.insert(cp,c)
            end
        end
        for k,c in ipairs(b.cells) do
            if not c:contained(self) then
                table.insert(bp,c)
            end
        end
        return cl,cp,bp
    end
    
    function Block:partition()
        local ca = self.cells[1]
        if not ca then
            return
        end
        local n = ca.size
        local ck,nk,na,nb,nc,nr
        for k=1,n do
            if not self:hasSolution(k) then
                ck,nk = {},{}
                na,nb = 0,0
                for l,c in ipairs(self.cells) do
                    if not c.solution then
                        if c.numbers & 2^(k-1) ~= 0 then
                            table.insert(ck,c)
                            na = na | c.numbers
                        else
                            table.insert(nk,c)
                            nb = nb | c.numbers
                        end
                    end
                end
                if na ~= (na & (~nb)) then
                    -- the sets of numbers overlap
                    na = na & (~nb)
                    nr = na
                    nc = 0
                    while na ~= 0 do
                        nc = nc + (na&1)
                        na = na >> 1
                    end
                    if nc == #ck then
                        -- we have a partition, return the cells and numbers
                        return ck, nr
                    end
                end
            end
        end
    end
    
    return Sudoku
end