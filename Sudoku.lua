if _M then
    local Game = cimport "Game"
    local Cell, Block = class(), class()
    Sudoku = class(Game)

    function Sudoku:init(u)
        Game.init(self,u)
        self:reset()
        self.helpful = true
        local m = self.options 
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
        title = "Reset",
        action = function()
            self:reset()
            return true
        end
        })
    end
    
    function Sudoku:reset()
        self.checkpoints = {}
        self.undo = {}
        self.redo = {}
        
        self.cells = {}
        self.blocks = {}
        
        for i=1,9 do
            table.insert(self.cells,{})
            for j=1,9 do
                table.insert(self.cells[i],Cell(i,j,self))
            end
        end
        
        self:setStandardGrid()
        self:saveState()
    end
    
    function Sudoku:setStandardGrid()
        local r,c,b
        for j=1,9 do
            r = Block()
            for i=1,9 do
                r:addCell(self.cells[i][j])
            end
            r.isLine = true
            table.insert(self.blocks,r)
        end
        for i=1,9 do
            c = Block()
            for j=1,9 do
                c:addCell(self.cells[i][j])
            end
            c.isLine = true
            table.insert(self.blocks,c)
        end
        for x=1,3 do
            for y=1,3 do
                b = Block()
                for i=1,3 do
                    for j=1,3 do
                        b:addCell(self.cells[(x-1)*3+i][(y-1)*3+j])
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
        for i=1,9 do
            table.insert(g,{})
            table.insert(s,{})
            for j=1,9 do
                table.insert(g[i],{})
                s[i][j] = self.cells[i][j].solution
                for k=1,9 do
                    g[i][j][k] = self.cells[i][j].numbers[k]
                end
            end
        end
        return g,s
    end
    
    function Sudoku:setState(g,s)
        for i=1,9 do
            for j=1,9 do
                self.cells[i][j].solution = s[i][j]
                for k=1,9 do
                    self.cells[i][j].numbers[k] = g[i][j][k]
                end
            end
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
        local t = {g,s,self.checkpoints}
        local s = json.encode(t)
        saveProjectData("Sudoku",s)
    end
    
    function Sudoku:loadGame()
        local s = readProjectData("Sudoku")
        if not s then
            return
        end
        local t = json.decode(s)
        self:setState(t[1],t[2])
        self.checkpoints = t[3]
        self.last = self.checkpoints[#self.checkpoints]
    end
    
    function Sudoku:draw()
        pushMatrix()
        pushStyle()
        translate(WIDTH/2,HEIGHT/2)
        local s = math.min(WIDTH,HEIGHT)
        s = s - s%27
        local w = s/27
        self.width = w
        self.centre = vec2(WIDTH,HEIGHT)/2
        translate(-w*13.5,-w*13.5)
        for k,b in ipairs(self.blocks) do
            b:draw()
        end
        if self.gridtpt then
            self.gridtpt:fill(color(233, 255, 0, 255))
        end
        for k,r in ipairs(self.cells) do
            for l,c in ipairs(r) do
                c:draw()
            end
        end
        stroke(255, 255, 255, 255)
        strokeWidth(1)
        for i=1,10 do
            line((i-1)*3*w,0,(i-1)*3*w,27*w)
            line(0,(i-1)*3*w,27*w,(i-1)*3*w)
        end
        
        if self.gridpt then
            translate(w*13.5,w*13.5)
            self.gridpt:drawBig()
        end
        popStyle()
        popMatrix()
    end
        
    function Sudoku:stuff()
        self:drawInvalid()
        if self.gridtpt then
            fill(233, 255, 0, 255)
            rect(3*self.gridtpt*w,3*w,3*w)
        end
        local c,n,d
        for i=1,9 do
            for j=1,9 do
                if self.solution[i][j] then
                    pushStyle()
                    fill(252, 252, 252, 255)
                    fontSize(3*fontSize())
                    text(self.solution[i][j],((i-1)*3 + 1.5)*w, ((j-1)*3 + 1.5)*w)
                    popStyle()
                else
                    for k=1,9 do
                        self:styleCell(i,j,k)
                        text(k,((i-1)*3 + (k-1)%3 + .5)*w, ((j-1)*3 + (k-1)//3 + .5)*w)
                    end
                end
            end
        end
        stroke(255, 255, 255, 255)
        for i=1,10 do
            if i%3 == 1 then
                strokeWidth(4)
            else
                strokeWidth(1)
            end
            line((i-1)*3*w,0,(i-1)*3*w,27*w)
            line(0,(i-1)*3*w,27*w,(i-1)*3*w)
        end
        if self.gridpt then
            translate(w*13.5,w*13.5)
            fill(40,40,50, 255)
            rect(-6*w,-6*w,w*12,w*12)
            if self.gridtnum then
                fill(233, 255, 0, 255)
                rect(4*(self.gridtnum - vec2(1.5,1.5))*w,4*w,4*w)
            end
            fontSize(4*fontSize())
            for k=1,9 do
                if self.solution[self.gridpt.x+1][self.gridpt.y+1] == k then
                    fill(220, 0, 255, 255)
                else
                    if self.puzzle[self.gridpt.x+1][self.gridpt.y+1][k] then
                        fill(254, 254, 254, 255)
                    else
                        fill(127, 127, 127, 255)
                    end
                end
                text(k,(-1.5+(k-1)%3 + .5)*w*4, (-1.5 + (k-1)//3 + .5)*w*4)
            end
        end
        popStyle()
        popMatrix()
    end

    function Sudoku:isTouchedBy(t)
        local tpt = vec2(t.x,t.y) - self.centre

        if tpt:leninf() < self.width*27/2 then
            if self.gridpt then
                local n = (tpt/self.width/4 + vec2(1.5,1.5))//1
                if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2 then
                    self.gridpt.gridtnum = n
                else
                    self.gridpt.gridtnum = nil
                    self.gridpt = nil
                    self.gridtpt = nil
                    self.ignoretouch = true
                    self:saveState()
                end
            else
                local v = (tpt/self.width/3 + vec2(5.5,5.5))//1
                self.gridtpt = self.cells[v.x][v.y]
            end
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
            local n = (tpt/self.width/4 + vec2(1.5,1.5))//1
            if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2 then
                self.gridpt.gridtnum = n
                if g.type.long and g.type.tap then
                    n = math.floor(n.x + 3*n.y+1)
                    self.gridpt:toggleSolution(n)
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
            local v = (tpt/self.width/3 + vec2(5.5,5.5))//1
            self.gridtpt = self.cells[v.x][v.y]
        end
        if g.type.ended then
            if not self.gridpt then
                local v = (tpt/self.width/3 + vec2(5.5,5.5))//1
                self.gridpt = self.cells[v.x][v.y]
                self.gridtpt = self.gridpt
            else
                local n = (tpt/self.width/4 + vec2(1.5,1.5))//1
                if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2 then
                    n = n.x + 3*n.y+1
                    self.gridpt:toggleNumber(n)
                end
                self.gridpt.gridtnum = nil
            end
            g:reset()
        end
        g:noted()
    end
    
    function Sudoku:styleCell(i,j,k)
        if not self.puzzle[i][j][k] then
            -- user has removed this value
            fill(0, 0, 0, 255)
            return
        end
        for l=1,9 do
            -- check row and column for a cell with value k
            if self.solution[i][l] == k or self.solution[l][j] == k then
                fill(65, 65, 65, 255)
                return
            end
        end
        -- check block for a cell with value k
        local si = i - (i-1)%3
        local sj = j - (j-1)%3
        for x=si,si+2 do
            for y=sj,sj+2 do
                if self.solution[x][y] == k then
                    fill(63, 63, 63, 255)
                    return
                end
            end
        end
        -- check row and column to see if k is only possible in this cell
        local rc,cc = 0,0
        for l=1,9 do
            if l ~= j and not self.solution[i][l] then
                if self.puzzle[i][l][k] then
                    cc = cc + 1
                end
            end
            if l ~= i and not self.solution[l][j] then
                if self.puzzle[l][j][k] then
                    rc = rc + 1
                end
            end
        end
        if rc == 0 or cc == 0 then
            fill(0, 255, 243, 255)
            return
        end
        cc = 0
        for x=si,si+2 do
            for y=sj,sj+2 do
                if (x ~= i or y ~= j) and not self.solution[x][y] then
                    if self.puzzle[x][y][k] then
                        cc = cc + 1
                    end
                end
            end
        end
        if cc == 0 then
            fill(0, 255, 243, 255)
            return
        end
        fill(255, 255, 255, 255)
    end
    
    function Sudoku:remove(i,j,k)
        local m = {}
        for l=1,9 do
            if l ~= j then
                if self.puzzle[i][l][k] then
                    table.insert(m,{i,l,k})
                end
                self.puzzle[i][l][k] = false
            end
            if l ~= i then
                if self.puzzle[l][j][k] then
                    table.insert(m,{l,j,k})
                end
                self.puzzle[l][j][k] = false
            end
        end
        local si = i - (i-1)%3
        local sj = j - (j-1)%3
        for x=si,si+2 do
            for y=sj,sj+2 do
                if x ~= i or y ~= j then
                    if self.puzzle[x][y][k] then
                        table.insert(m,{x,y,k})
                    end
                    self.puzzle[x][y][k] = false
                end
            end
        end
        return m
    end
    
    function Sudoku:checkBlocks(i,j,k)
        -- check all blocks containing (i,j) for letter k
        local m = {}
        for l=1,9 do
            if l ~= j then
                if self.puzzle[i][l][k] then
                    table.insert(m,{i,l,k})
                end
                self.puzzle[i][l][k] = self:check(i,l,k)
            end
            if l ~= i then
                if self.puzzle[l][j][k] then
                    table.insert(m,{l,j,k})
                end
                self.puzzle[l][j][k] = self:check(l,j,k)
            end
        end
        local si = i - (i-1)%3
        local sj = j - (j-1)%3
        for x=si,si+2 do
            for y=sj,sj+2 do
                if x ~= i or y ~= j then
                    if self.puzzle[x][y][k] then
                        table.insert(m,{x,y,k})
                    end
                    self.puzzle[x][y][k] = self:check(x,y,k)
                end
            end
        end
        return m
    end
    
    function Sudoku:findForced()
        -- in each row, column, block look to see if a number appears only once
        -- keep track of those that get changed
        local sqs = {}
        local c,n,m,chg
        local rpt = false
        for i=1,9 do
            -- for each row
            for k=1,9 do
                -- for each number
                c = 0
                for j=1,9 do
                    -- look along the row for that number
                    if self.puzzle[i][j][k] then
                        c = c + 1
                        n = j
                    end
                end
                if c == 1 then
                    -- k only appears once, so in that cell it must be k
                    chg = false
                    for l = 1,9 do
                        if l ~= k and self.puzzle[i][n][l] then
                            chg = true
                        end
                        self.puzzle[i][n][l] = false
                    end
                    self.puzzle[i][n][k] = true
                    if chg then
                        table.insert(sqs,{i,n,k})
                    end
                end
            end
        end
        for j=1,9 do
            -- for each column
            for k=1,9 do
                -- for each number
                c = 0
                for i=1,9 do
                    -- look along the column for that number
                    if self.puzzle[i][j][k] then
                        c = c + 1
                        n = i
                    end
                end
                if c == 1 then
                    -- k only appears once, so in that cell it must be k
                    chg = false
                    for l = 1,9 do
                        if k ~= l and self.puzzle[n][j][l] then
                            chg = true
                        end
                        self.puzzle[n][j][l] = false
                    end
                    self.puzzle[n][j][k] = true
                    if chg then
                        table.insert(sqs,{n,j,k})
                    end
                end
            end
        end
        for x=1,3 do
            for y=1,3 do
                -- for each block
                for k=1,9 do
                    -- for each number
                    c = 0
                    for i=1,3 do
                        for j=1,3 do
                            if self.puzzle[3*(x-1)+i][3*(y-1)+j][k] then
                                c = c + 1
                                m = 3*(x-1)+i
                                n = 3*(y-1)+j
                            end
                        end
                    end

                    if c == 1 then
                        -- k only appears once, so in that cell it must be k
                        chg = false
                        for l = 1,9 do
                            if k ~= l and self.puzzle[m][n][l] then
                                chg = true
                            end
                            self.puzzle[m][n][l] = false
                        end
                        self.puzzle[m][n][k] = true
                        if chg then
                            table.insert(sqs,{m,n,k})
                        end
                    end
                end
            end
        end
        for k,v in ipairs(sqs) do
            self:check(v[1],v[2],v[3])
            rpt = true
        end
        if rpt then
-- self:findForced()
        end
    end
    
    function Sudoku:checkAll()
        local sqs = {}
        local c,n
        for i=1,9 do
            for j=1,9 do
                c = 0
                for k=1,9 do
                    if self.puzzle[i][j][k] then
                        c = c + 1
                        n = k
                    end
                end
                if c == 1 then
                    table.insert(sqs,{i,j,n})
                end
            end
        end
        for k,v in ipairs(sqs) do
            self:check(v[1],v[2],v[3])
        end
    end
    
    function Sudoku:check(x,y,z)
        -- check blocks containing (x,y) to see if z is already taken
        -- if taken, return false
        -- if available, return true
        for i=1,9 do
            if self.solution[i][y] == z then
                -- z is in that column
                return false
            end
        end
        for j=1,9 do
            if self.solution[x][j] == z then
                -- z is in that row
                return false
            end
        end
        
        local si = x - (x-1)%3
        local sj = y - (y-1)%3
        for i=si,si+2 do
            for y=sj,sj+2 do
                if self.solution[i][j] == z then
                    -- z is in that block
                    return false
                end
            end
        end
        return true
    end
    
    function Sudoku:drawInvalid()
        -- a cell is invalid if it belongs to a block that is invalid
        -- a block is invalid if there is a number it cannot contain
        -- a cell is also invalid if it cannot be filled

        local c,v
        local w = self.width
        -- check for cells with no options
        for i=1,9 do
            for j=1,9 do
                if not self.solution[i][j] then
                    c = 0
                    for k=1,9 do
                        if self.puzzle[i][j][k] then
                            c = c + 1
                        end
                    end
                    if c == 0 then
                        fill(255, 0, 2, 255)
                        rect(3*(i-1)*w,3*(j-1)*w,3*w,3*w)
                    end
                end
            end
        end

        for i=1,9 do
            v = false
            for k=1,9 do
                c = 0
                for j=1,9 do
                    -- look along the column for that number
                    if self.solution[i][j] == k or (not self.solution[i][j] and self.puzzle[i][j][k]) then
                        c = c + 1
                    end
                end
                if c == 0 then
                    v = true
                end
            end
            if v then
                fill(255, 0, 2, 255)
                rect(3*(i-1)*w,0,3*w,27*w)
            end
        end
        for j=1,9 do
            v = false
            for k=1,9 do
                c = 0
                for i=1,9 do
                    -- look along the row for that number
                    if self.solution[i][j] == k or (not self.solution[i][j] and self.puzzle[i][j][k]) then
                        c = c + 1
                    end
                end
                if c == 0 then
                    v = true
                end
            end
            if v then
                fill(255, 0, 2, 255)
                rect(0,3*(j-1)*w,27*w,3*w)
            end
        end
        for x=1,3 do
            for y=1,3 do
                -- for each block
                v = false
                for k=1,9 do
                    -- for each number
                    c = 0
                    for i=1,3 do
                        for j=1,3 do
                            if self.solution[3*(x-1)+i][3*(y-1)+j] == k or (not self.solution[3*(x-1)+i][3*(y-1)+j] and self.puzzle[3*(x-1)+i][3*(y-1)+j][k]) then
                                c = c + 1
                            end
                        end
                    end

                    if c == 0 then
                        v = true
                    end
                end
                if v then
                    fill(255, 0, 2, 255)
                    rect(9*(x-1)*w,9*(y-1)*w,9*w,9*w)
                end
            end
        end
    end
    
    function Cell:init(i,j,s)
        self.blocks = {}
        self.index = {i,j}
        self.numbers = {}
        for j=1,9 do
            table.insert(self.numbers,true)
        end
        self.solution = false
        self.puzzle = s
    end
    
    function Cell:draw()
        local w = self.puzzle.width
        local i = self.index[1]
        local j = self.index[2]
        if self.solution then
            pushStyle()
            fill(255, 255, 255, 255)
            fontSize(3*fontSize())
            text(self.solution, ((i-1)*3 + 1.5)*w, ((j-1)*3 + 1.5)*w)
            popStyle()
        else
            for k=1,9 do
                self:style(k)
                text(k,((i-1)*3 + (k-1)%3 + .5)*w, ((j-1)*3 + (k-1)//3 + .5)*w)
            end
        end
    end
    
    function Cell:drawBig()
        local w = self.puzzle.width
        fill(40,40,50, 255)
        rect(-6*w,-6*w,w*12,w*12)
        if self.gridtnum then
            fill(233, 255, 0, 255)
            rect(4*(self.gridtnum - vec2(1.5,1.5))*w,4*w,4*w)
        end
        fontSize(4*fontSize())
        for k=1,9 do
            if self.solution == k then
                fill(220, 0, 255, 255)
            else
                if self.numbers[k] then
                    fill(254, 254, 254, 255)
                else
                    fill(127, 127, 127, 255)
                end
            end
            text(k,(-1.5+(k-1)%3 + .5)*w*4, (-1.5 + (k-1)//3 + .5)*w*4)
        end
    end
    
    function Cell:fill(c)
        pushStyle()
        fill(c)
        noStroke()
        local w = self.puzzle.width*3
        local i = self.index[1]
        local j = self.index[2]
        rect((i-1)*w,(j-1)*w,w,w)
        popStyle()
    end
    
    function Cell:style(k)
        if not self.numbers[k] then
            -- user has removed this value
            fill(0, 0, 0, 255)
            return
        end
        -- look for a block with a cell set to this value
        for i,b in ipairs(self.blocks) do
            for j,c in ipairs(b.cells) do
                if c.solution == k then
                    fill(65,65,65,255)
                    return
                end
            end
        end
        -- look for a block without this value
        local n
        for i,b in ipairs(self.blocks) do
            n = 0
            for j,c in ipairs(b.cells) do
                if c.numbers[k] then
                    n = n + 1
                end
            end
            if n == 1 then
                fill(0, 255, 255, 255)
                return
            end
        end
        fill(255,255,255,255)
    end
    
    function Cell:addBlock(b)
        for k,v in ipairs(self.blocks) do
            if v == b then
                return
            end
        end
        table.insert(self.blocks,b)
        b:addCell(self)
    end
    
    function Cell:contained(b)
        for k,v in ipairs(self.blocks) do
            if v == b then
                return true
            end
        end
        return false
    end
    
    function Cell:getPosition()
        local w = self.puzzle.width*3
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
        if self.puzzle.cells[i] and self.puzzle.cells[i][j] then
            return self.puzzle.cells[i][j]
        else
            return false
        end
    end
    
    function Cell:drawBorder(n)
        -- 1 is East
        -- 2 is North
        -- 3 is West
        -- 4 is South
        local i = self.index[1]
        local j = self.index[2]
        local w = 3*self.puzzle.width
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
        local s = self.solution
        self.solution = false
        if s then
            for k,b in ipairs(self.blocks) do
                b:add(n,self)
            end
        end
        if s ~= n then
            self.solution = n
            self.numbers[n] = true
            for k,b in ipairs(self.blocks) do
                b:remove(n,self)
            end
        end
    end
    
    function Cell:remove(n)
        self.numbers[n] = false
    end
    
    function Cell:add(n)
        local a = true
        for k,v in ipairs(self.blocks) do
            a = a and not v:hasSolution(n)
        end
        self.numbers[n] = a
    end
    
    function Cell:toggleNumber(n)
        self.numbers[n] = not self.numbers[n]
    end
    
    function Block:init(w)
        self.cells = {}
        self.isLine = false
    end
    
    function Block:draw()
        pushStyle()
        local fc
        if not self:checkValid() then
            for k,c in ipairs(self.cells) do
                c:fill(color(255, 0, 0, 255))
            end
        end

        if not self.isLine then
            stroke(255)
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
        local n = {}
        local b = 0
        for i,c in ipairs(self.cells) do
            if c.solution then
                n[c.solution] = true
            else
                for j,m in ipairs(c.numbers) do
                    n[j] = n[j] or m
                end
            end
            b = b + 1
        end
        local c = 0
        for k,v in ipairs(n) do
            if v then
                c = c + 1
            end
        end
        if c < b then
            return false
        end
        return true
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
    
    return Sudoku
end