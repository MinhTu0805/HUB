-- ═══ Solver.lua ═══ Constraint engine: logic, brute force, DP, Monte-Carlo
-- Shared state lives in the table SV (passed in by Loader.lua).
local SV = ...
local BEIGE_KEYS, CFG, ClearAll, GREEN_KEYS, GameRunning, GetNumber = SV.BEIGE_KEYS, SV.CFG, SV.ClearAll, SV.GREEN_KEYS, SV.GameRunning, SV.GetNumber
local HasFlag, IsCorner, IsEdge, MinesVal, RGBKey, RebuildFlagNames = SV.HasFlag, SV.IsCorner, SV.IsEdge, SV.MinesVal, SV.RGBKey, SV.RebuildFlagNames
local RefreshBounds, Render, TileGridPos = SV.RefreshBounds, SV.Render, SV.TileGridPos

-- ─── CONSTRAINT ENGINE ──────────────────────────────────
-- All solver logic is captured inside Solve() as upvalue-locals
-- to keep the hot path allocation-free.

function SV.Solve()
    if not GameRunning.Value then ClearAll(); return end
    RebuildFlagNames()

    -- A missing / zero counter means there is NO usable global mine count
    -- (using it would make the solver think "0 mines left" and mark everything safe).
    local hasMines  = MinesVal ~= nil and SV.GridW ~= nil and MinesVal.Value > 0
    local mineTotal = hasMines and MinesVal.Value or 0
    SV.TotalMines = mineTotal

    -- Classify tiles + rolling hash (Zobrist-style)
    local greenTiles= {}
    local beigeSet  = {}
    local flagged   = {}
    local NEG_INF   = -math.huge
    local sig = (SV.TileCount * 2246822519 + mineTotal * 3266489917) % 4294967291

    for t in next, SV.Adjacency do
        local k = RGBKey(t.Color)
        if BEIGE_KEYS[k] then
            beigeSet[t] = true
            sig = (sig + (k + GetNumber(t) * 97 + 11) * 31 + 7) % 4294967291
        elseif GREEN_KEYS[k] then
            greenTiles[#greenTiles+1] = t
            local fl = HasFlag(t)
            flagged[t] = fl
            sig = (sig + (k + (fl and 6151 or 0)) * 31 + 7) % 4294967291
        else
            sig = (sig + k * 31 + 7) % 4294967291
        end
    end
    if sig == SV.LastSig then return end
    if SV.BoundsDirty then RefreshBounds() end

    -- ── State vector: 0=unknown, 1=safe, 2=mine ──────────
    local weak, sampledSet = {}, {}   -- weak = safe by budget/sampling, not by pure local proof
    local state = {}
    for _, t in ipairs(greenTiles) do state[t] = 0 end
    if CFG.TrustFlags then
        for _, t in ipairs(greenTiles) do
            if flagged[t] then state[t] = 2 end
        end
    end

    -- ── Constraint list/index ─────────────────────────────
    local cons    = {}
    local consOf  = {}   -- tile → {constraint, ...}
    local contra  = false

    local function BuildConstraints()
        cons, consOf, contra = {}, {}, false
        for b in next, beigeSet do
            local n = GetNumber(b)
            if n > 0 then
                local c = { Set={}, List={}, Rem=n }
                for _, nb in ipairs(SV.Adjacency[b]) do
                    local s = state[nb]
                    if s == 0 then
                        c.Set[nb] = true
                        c.List[#c.List+1] = nb
                        local lst = consOf[nb]
                        if not lst then lst = {}; consOf[nb] = lst end
                        lst[#lst+1] = c
                    elseif s == 2 then
                        c.Rem -= 1
                    end
                end
                if #c.List > 0 then
                    cons[#cons+1] = c
                elseif c.Rem ~= 0 then
                    contra = true
                end
            end
        end
    end

    -- Unit propagation pass
    local function Propagate()
        local changed = false
        for _, c in ipairs(cons) do
            local target = (c.Rem == 0) and 1 or (c.Rem >= #c.List and 2 or 0)
            if target ~= 0 then
                for _, t in ipairs(c.List) do
                    if state[t] == 0 then state[t] = target; changed = true end
                end
            end
        end
        return changed
    end

    -- Subset-difference constraint derivation (eliminates subsumed constraints)
    local function SubsetClosure()
        local resolved = false
        for _ = 1, 32 do
            local n, seen, newOnes, added = #cons, {}, {}, false
            -- Hash existing constraints for dedup
            for i = 1, n do
                local ids = {}
                for _, t in ipairs(cons[i].List) do ids[#ids+1] = SV.TileIndex[t] end
                table.sort(ids)
                local h = 0
                for _, id in ipairs(ids) do h = (h * 131 + id) % 4294967291 end
                seen[h] = true
            end
            for i = 1, n do
                local a = cons[i]
                -- Collect constraints that share variables with a and are larger
                local cand = {}
                for _, t in ipairs(a.List) do
                    for _, b in ipairs(consOf[t] or {}) do
                        if b ~= a and #b.List > #a.List then cand[b] = true end
                    end
                end
                for b in next, cand do
                    -- Check a ⊆ b
                    local sub = true
                    for _, t in ipairs(a.List) do
                        if not b.Set[t] then sub = false; break end
                    end
                    if sub then
                        local rem  = b.Rem - a.Rem
                        local diff = {}
                        for _, t in ipairs(b.List) do
                            if not a.Set[t] then diff[#diff+1] = t end
                        end
                        if #diff > 0 then
                            if rem == 0 or rem == #diff then
                                local s = (rem == 0) and 1 or 2
                                for _, t in ipairs(diff) do
                                    if state[t] == 0 then state[t] = s; resolved = true end
                                end
                            else
                                local ids = {}
                                for _, t in ipairs(diff) do ids[#ids+1] = SV.TileIndex[t] end
                                table.sort(ids)
                                local h = 0
                                for _, id in ipairs(ids) do h = (h*131+id)%4294967291 end
                                if not seen[h] then
                                    seen[h] = true
                                    local nc = { Set={}, List=diff, Rem=rem }
                                    for _, t in ipairs(diff) do
                                        nc.Set[t] = true
                                        local lst = consOf[t]
                                        if not lst then lst={}; consOf[t]=lst end
                                        lst[#lst+1] = nc
                                    end
                                    newOnes[#newOnes+1] = nc
                                    added = true
                                end
                            end
                        end
                    end
                end
            end
            for _, nc in ipairs(newOnes) do cons[#cons+1] = nc end
            if resolved or not added then break end
        end
        return resolved
    end

    -- ── Gaussian elimination over integers (GF-style) ────────
    -- Finds forced assignments that pairwise subset-difference misses,
    -- specifically combinations of 3+ constraints that jointly force a cell.
    -- Works by reducing the augmented [A|b] system to row echelon form
    -- using exact integer arithmetic, then reading back unit rows.
    local function GaussianElim()
        if #cons == 0 then return false end

        -- Collect all unknown tiles referenced by any constraint
        local tileList, tilePos = {}, {}
        for _, c in ipairs(cons) do
            for _, t in ipairs(c.List) do
                if not tilePos[t] then
                    tileList[#tileList+1] = t
                    tilePos[t] = #tileList
                end
            end
        end
        local nv = #tileList
        local nc = #cons
        if nv == 0 then return false end

        -- Build augmented matrix rows as {coeff[], rhs}
        -- Each row: coefficients are 0 or 1, rhs is the constraint remainder
        local mat = {}
        for ri, c in ipairs(cons) do
            local row = table.create(nv + 1, 0)
            for _, t in ipairs(c.List) do
                row[tilePos[t]] = 1
            end
            row[nv + 1] = c.Rem
            mat[ri] = row
        end

        -- Forward elimination (partial pivoting by leading 1)
        local pivot = {}   -- col → pivot row index
        local pr = 1
        for col = 1, nv do
            -- Find a row at or below pr with a 1 in this column
            local found = nil
            for r = pr, nc do
                if mat[r][col] == 1 then found = r; break end
            end
            if found then
                mat[pr], mat[found] = mat[found], mat[pr]
                pivot[col] = pr
                -- Eliminate this column from all other rows
                for r = 1, nc do
                    if r ~= pr and mat[r][col] == 1 then
                        -- row[r] = row[r] XOR row[pr]  (subtract mod 2 = XOR for {0,1})
                        local rowR = mat[r]
                        local rowP = mat[pr]
                        for c2 = col, nv + 1 do
                            rowR[c2] = rowR[c2] - rowP[c2]
                            -- Clamp back to {0,1} by parity (handles over-subtract)
                            if rowR[c2] < 0 then rowR[c2] += 2 end
                        end
                    end
                end
                pr += 1
            end
        end

        -- Read back unit rows: a row with exactly one non-zero variable column
        -- forces that variable to the rhs value
        local resolved = false
        for r = 1, nc do
            local row = mat[r]
            local rhs = row[nv + 1]
            -- Check consistency: a row of all zeros with non-zero rhs is contradiction
            local nonzero, lastCol = 0, 0
            for col = 1, nv do
                if row[col] ~= 0 then nonzero += 1; lastCol = col end
            end
            if nonzero == 1 then
                local t = tileList[lastCol]
                -- rhs should be 0 (safe) or 1 (mine) for a unit row
                if rhs == 0 and state[t] == 0 then
                    state[t] = 1; resolved = true
                elseif rhs == 1 and state[t] == 0 then
                    state[t] = 2; resolved = true
                end
            end
        end
        return resolved
    end

    -- Full deduction loop
    local function Deduct()
        for _ = 1, 64 do
            BuildConstraints()
            if contra then return false end
            for _, c in ipairs(cons) do
                if c.Rem < 0 or c.Rem > #c.List then return false end
            end
            local ch = Propagate()
            if SubsetClosure() then ch = true end
            -- Gaussian pass after subset closure: catches what pairwise diff misses
            if GaussianElim() then ch = true end
            if not ch then break end
        end
        return true
    end

    -- ── Budget / remaining mines ──────────────────────────
    local function ComputeBudget()
        if not hasMines then return math.huge end
        local found = 0
        for _, t in ipairs(greenTiles) do
            if state[t] == 2 then
                if not (CFG.MinesValueIsRemaining and CFG.TrustFlags and flagged[t]) then
                    found += 1
                end
            end
        end
        return math.max(0, math.floor(
            CFG.MinesValueIsRemaining and mineTotal - found or mineTotal - found + 0.5
        ))
    end

    -- ─── BACKTRACKING SEARCH ENGINE ──────────────────────
    -- Builds a compact integer-indexed local problem for fast BT.
    local function MakeSearch(tiles)
        local n    = #tiles
        local tIdx = {}
        for i = 1, n do tIdx[tiles[i]] = i end

        -- Gather constraints touching these tiles
        local cSet, cList = {}, {}
        for i = 1, n do
            for _, c in ipairs(consOf[tiles[i]] or {}) do
                if not cSet[c] then cSet[c]=true; cList[#cList+1]=c end
            end
        end
        local nc   = #cList
        local vCon = table.create(n)   -- var → {ci, ...}
        local cVar = table.create(nc)  -- ci  → {vi, ...}
        local cRem = table.create(nc)
        for i = 1, n do vCon[i] = {} end
        for ci = 1, nc do
            local c = cList[ci]
            cRem[ci] = c.Rem
            local vars = {}
            for _, t in ipairs(c.List) do
                local vi = tIdx[t]
                if vi then
                    vars[#vars+1] = vi
                    local vc = vCon[vi]; vc[#vc+1] = ci
                end
            end
            cVar[ci] = vars
        end

        -- Runtime state (reused across calls via closure)
        local placed  = table.create(nc, 0)
        local left    = table.create(nc, 0)
        for ci = 1, nc do left[ci] = #cVar[ci] end
        local asgn    = table.create(n, -1)
        local trail   = {}
        local mines   = {}
        local count   = 0

        local propQ   = {}

        local function assign(v, val)
            asgn[v] = val; trail[#trail+1] = v; count += 1
            if val == 1 then mines[#mines+1] = v end
            for _, ci in ipairs(vCon[v]) do
                left[ci] -= 1
                if val == 1 then placed[ci] += 1 end
                propQ[#propQ+1] = ci
            end
        end

        local function prop()
            while #propQ > 0 do
                local ci = propQ[#propQ]; propQ[#propQ] = nil
                local need = cRem[ci] - placed[ci]
                local lft  = left[ci]
                if need < 0 or need > lft then
                    -- Clear queue
                    for i = 1, #propQ do propQ[i] = nil end
                    return false
                end
                if lft > 0 then
                    local forced = (need == 0) and 0 or (need == lft and 1 or -1)
                    if forced >= 0 then
                        for _, vi in ipairs(cVar[ci]) do
                            if asgn[vi] == -1 then assign(vi, forced) end
                        end
                    end
                end
            end
            return true
        end

        local function undo(mark)
            while #trail > mark do
                local v = trail[#trail]; trail[#trail] = nil
                local val = asgn[v]; asgn[v] = -1; count -= 1
                if val == 1 then mines[#mines] = nil end
                for _, ci in ipairs(vCon[v]) do
                    left[ci] += 1
                    if val == 1 then placed[ci] -= 1 end
                end
            end
        end

        return {
            N=n, NC=nc, VCon=vCon, CVar=cVar, CRem=cRem,
            Placed=placed, Left=left, Asgn=asgn,
            Trail=trail, Mines=mines,
            Count=function() return count end,
            Assign=assign, Prop=prop, Undo=undo,
        }
    end

    -- ── Exact enumeration (small partitions) ──────────────
    local nodesBudget = { n = 0 }
    local deadline    = os.clock() + CFG.MaxSolveTime
    local maxBudget   = math.huge  -- hoisted so bt() closure captures it before Enumerate is defined

    local function Enumerate(tiles)
        local s       = MakeSearch(tiles)
        local n, nc   = s.N, s.NC
        local cVar    = s.CVar;   local cRem  = s.CRem
        local placed  = s.Placed; local left  = s.Left
        local asgn    = s.Asgn;   local trail = s.Trail
        local mines   = s.Mines
        local assign  = s.Assign; local prop  = s.Prop; local undo = s.Undo
        local vCon    = s.VCon
        local cbm     = {}
        local freq    = table.create(n)
        local total   = 0
        local aborted = false
        local localN  = 0

        -- MRV + degree heuristic
        local function pickVar()
            local bestV, bestSlack, bestDeg = -1, math.huge, -1
            for ci = 1, nc do
                if left[ci] > 0 then
                    local slack = left[ci] - (cRem[ci] - placed[ci])
                    if slack < bestSlack then
                        bestSlack = slack; bestV = -1; bestDeg = -1
                        for _, v in ipairs(cVar[ci]) do
                            if asgn[v] == -1 then
                                local d = #vCon[v]
                                if d > bestDeg then bestDeg = d; bestV = v end
                            end
                        end
                    end
                end
            end
            return bestV
        end

        local function bt()
            if aborted then return end
            localN  += 1
            nodesBudget.n += 1
            if localN % 512 == 0 and
               (nodesBudget.n >= CFG.MaxNodes or os.clock() > deadline) then
                aborted = true; return
            end
            if s.Count() == n then
                total += 1
                local m = #mines
                cbm[m]  = (cbm[m] or 0) + 1
                for _, v in ipairs(mines) do
                    local f = freq[v]
                    if not f then f = {}; freq[v] = f end
                    f[m] = (f[m] or 0) + 1
                end
                if total >= CFG.MaxSolutions then aborted = true end
                return
            end
            local v = pickVar()
            if v < 0 then return end
            local mark = #trail
            assign(v, 0); if prop() then bt() end; undo(mark)
            if aborted then return end
            if #mines + 1 <= maxBudget then
                assign(v, 1); if prop() then bt() end; undo(mark)
            end
        end

        bt()
        return cbm, freq, total, aborted
    end

    -- ── Monte Carlo sampling (large partitions) ───────────
    local function SamplePart(tiles)
        local s       = MakeSearch(tiles)
        local n       = s.N
        local vCon    = s.VCon
        local cRem    = s.CRem
        local placed  = s.Placed; local left = s.Left
        local asgn    = s.Asgn;   local mines = s.Mines
        local assign  = s.Assign; local prop  = s.Prop; local undo = s.Undo

        local order = table.create(n)
        for i = 1, n do order[i] = i end

        -- Global density estimate
        local density
        if hasMines and SV.TotalTiles then
            local unrevealed = math.max(1, SV.TotalTiles - SV.TileCount + #greenTiles)
            density = math.clamp(mineTotal / unrevealed, 0.02, 0.98)
        elseif hasMines then
            density = math.clamp(mineTotal / math.max(1, #greenTiles), 0.02, 0.98)
        else
            density = 0.21
        end

        local cbmS  = {}
        local freqS = table.create(n)
        local valid = 0

        for _ = 1, CFG.MonteCarloSamples do
            if _ % 32 == 0 and os.clock() > deadline then break end
            -- Fisher-Yates shuffle
            for i = n, 2, -1 do
                local j = math.random(i)
                order[i], order[j] = order[j], order[i]
            end
            local ok = true
            for pos = 1, n do
                local v = order[pos]
                if asgn[v] == -1 then
                    local canMine, canSafe, pn, pd = true, true, 0, 0
                    for _, ci in ipairs(vCon[v]) do
                        local need = cRem[ci] - placed[ci]
                        if need <= 0           then canMine = false end
                        if need > left[ci] - 1 then canSafe = false end
                        pn += need; pd += left[ci]
                    end
                    if canMine and canSafe then
                        local val = (math.random() < (pd > 0 and pn/pd or density)) and 1 or 0
                        assign(v, val)
                        if not prop() then ok = false; break end
                    elseif canMine then
                        assign(v, 1)
                        if not prop() then ok = false; break end
                    elseif canSafe then
                        assign(v, 0)
                        if not prop() then ok = false; break end
                    else
                        ok = false; break
                    end
                end
            end
            if ok and s.Count() == n then
                valid += 1
                local m = #mines
                cbmS[m] = (cbmS[m] or 0) + 1
                for _, v in ipairs(mines) do
                    local f = freqS[v]
                    if not f then f = {}; freqS[v] = f end
                    f[m] = (f[m] or 0) + 1
                end
            end
            undo(0)
        end
        return cbmS, freqS, valid
    end

    -- ─── WRONG-FLAG DETECTION ────────────────────────────
    -- Pure-logic pass that ignores every flag. A flag sitting on a tile that
    -- logic proves SAFE is wrong: it must not be trusted (it would poison the
    -- deductions and send the walker onto real mines) and can be removed.
    --
    -- The same flag-free pass also produces `pure`: the set of tiles that are PROVEN
    -- (local logic + exact enumeration of each frontier group, no sampling, no mine
    -- counter, no flags). Only `pure` tiles are ever walked on, auto-flagged or shown
    -- as definite Safe / Mine. Everything else is a prediction and is shown as a %.
    local wrongFlag, pure = {}, {}

    -- Exhaustive proof per connected frontier group: a tile that is safe (or a mine)
    -- in EVERY valid arrangement is certain, even when no pairwise rule sees it.
    local function ExactProof()
        local seen, found = {}, false
        for _, seed in ipairs(greenTiles) do
            if state[seed] == 0 and consOf[seed] and not seen[seed] then
                local comp, q, qh = {}, { seed }, 1
                seen[seed] = true
                while qh <= #q do
                    local cur = q[qh]; qh += 1
                    comp[#comp + 1] = cur
                    for _, c in ipairs(consOf[cur] or {}) do
                        for _, u in ipairs(c.List) do
                            if state[u] == 0 and not seen[u] then seen[u] = true; q[#q + 1] = u end
                        end
                    end
                end
                if #comp <= 30 then
                    local _, freq, total, aborted = Enumerate(comp)
                    if not aborted and total > 0 then
                        for v, t in ipairs(comp) do
                            local cnt, f = 0, freq[v]
                            if f then for _, c in next, f do cnt += c end end
                            if cnt == 0 then state[t] = 1; found = true
                            elseif cnt == total then state[t] = 2; found = true end
                        end
                    end
                end
            end
        end
        return found
    end

    do
        local saved = {}
        for _, t in ipairs(greenTiles) do saved[t] = state[t]; state[t] = 0 end
        local okp = Deduct()
        for _ = 1, 4 do
            if not okp or not ExactProof() then break end
            okp = Deduct()
        end
        if okp then
            for _, t in ipairs(greenTiles) do
                local st = state[t]
                if st == 1 or st == 2 then pure[t] = st end
                if flagged[t] and st == 1 then wrongFlag[t] = true end
            end
        end
        for _, t in ipairs(greenTiles) do
            state[t] = pure[t] or (wrongFlag[t] and 0) or saved[t]
        end
    end

    -- ─── GLOBAL DEDUCTION PASS ───────────────────────────
    local ok = Deduct()
    if not ok and CFG.TrustFlags then
        for _, t in ipairs(greenTiles) do state[t] = 0 end
        Deduct()
    end

    -- Global mine-budget trivial cases
    do
        local b = ComputeBudget()
        if b ~= math.huge then
            local unknowns = {}
            for _, t in ipairs(greenTiles) do
                if state[t] == 0 then unknowns[#unknowns+1] = t end
            end
            if #unknowns > 0 then
                if b == 0 then
                    for _, t in ipairs(unknowns) do state[t] = 1; weak[t] = true end; Deduct()
                elseif b == #unknowns then
                    for _, t in ipairs(unknowns) do state[t] = 2 end; Deduct()
                end
            end
        end
    end
    if not GameRunning.Value then ClearAll(); return end

    -- ─── CASCADE PROBABILITY LOOP ────────────────────────
    local prob      = {}
    local freeProb  = 0.5
    local estProb   = {}   -- density ESTIMATES (partitions the solver could not enumerate) – shown as ~NN%, never trusted
    local frontier  = {}
    local freeTiles = {}
    local failedParts = {}

    for cascade = 1, CFG.MaxCascade do
        if os.clock() > deadline then break end

        local budget  = ComputeBudget()
        local nUnknown= 0
        for _, t in ipairs(greenTiles) do
            if state[t] == 0 then nUnknown += 1 end
        end
        if budget ~= math.huge then
            budget = math.min(budget, nUnknown)
            maxBudget = budget
        end

        prob, frontier, freeTiles = {}, {}, {}
        for _, t in ipairs(greenTiles) do
            if state[t] == 0 then
                if consOf[t] then frontier[#frontier+1] = t
                else           freeTiles[#freeTiles+1] = t end
            end
        end

        -- BFS-connected components of the frontier
        local parts, visited = {}, {}
        for _, seed in ipairs(frontier) do
            if not visited[seed] then
                local component = {}
                local q, qh = {seed}, 1
                visited[seed] = true
                while qh <= #q do
                    local cur = q[qh]; qh += 1
                    component[#component+1] = cur
                    for _, c in ipairs(consOf[cur] or {}) do
                        for _, u in ipairs(c.List) do
                            if not visited[u] then
                                visited[u] = true; q[#q+1] = u
                            end
                        end
                    end
                end
                -- Canonical ordering: stable grid sort with TileIndex tiebreak
                table.sort(component, function(a, b)
                    local ax, az = TileGridPos(a)
                    local bx, bz = TileGridPos(b)
                    if ax and bx then
                        if ax ~= bx then return ax < bx end
                        if az ~= bz then return az < bz end
                    end
                    return (SV.TileIndex[a] or 0) < (SV.TileIndex[b] or 0)
                end)
                parts[#parts+1] = component
            end
        end

        -- Solve each component (exact or sampled)
        local partData = {}
        failedParts    = {}
        for _, tiles in ipairs(parts) do
            local done = false
            if #tiles <= CFG.MaxBruteForce then
                local cbm, freq, total, aborted = Enumerate(tiles)
                if not aborted and total > 0 then
                    partData[#partData+1] = { Tiles=tiles, Cbm=cbm, Freq=freq, Tot=total }
                    done = true
                end
            end
            if not done then
                local cbmS, freqS, valid = SamplePart(tiles)
                for _, st in ipairs(tiles) do sampledSet[st] = true end
                if valid > 0 then
                    partData[#partData+1] = { Tiles=tiles, Cbm=cbmS, Freq=freqS, Tot=valid }
                else
                    failedParts[#failedParts+1] = tiles
                end
            end
        end

        if not GameRunning.Value then ClearAll(); return end

        -- ── Segment min/max budget bounds ─────────────────────
        -- After solving each partition we know the minimum and maximum number
        -- of mines that can appear in it across all valid configurations.
        -- Summing these across all frontier partitions gives tight global
        -- bounds on how many mines must fall among the free (non-frontier)
        -- tiles — catching forced states the per-constraint passes miss.
        if hasMines and budget ~= math.huge and #partData > 0 then
            local frontierMin, frontierMax = 0, 0
            for _, pdt in ipairs(partData) do
                local lo, hi = math.huge, 0
                for k in next, pdt.Cbm do
                    if k < lo then lo = k end
                    if k > hi then hi = k end
                end
                if lo < math.huge then
                    frontierMin += lo
                    frontierMax += hi
                end
            end
            local freeMin = budget - frontierMax   -- mines that MUST be in free tiles
            local freeMax = budget - frontierMin   -- mines that CAN be in free tiles
            local nFree   = #freeTiles
            if nFree > 0 then
                if freeMax <= 0 then
                    -- No mines can be in free tiles → all free tiles are safe
                    for _, t in ipairs(freeTiles) do
                        if state[t] == 0 then state[t] = 1; weak[t] = true end
                    end
                    Deduct()
                elseif freeMin >= nFree then
                    -- All free tiles must be mines
                    for _, t in ipairs(freeTiles) do
                        if state[t] == 0 then state[t] = 2 end
                    end
                    Deduct()
                end
            end
            -- Also constrain frontier partitions: if frontier must hold all
            -- remaining budget, any partition whose min == max is fully forced.
            for _, pdt in ipairs(partData) do
                local lo, hi = math.huge, 0
                for k in next, pdt.Cbm do
                    if k < lo then lo = k end
                    if k > hi then hi = k end
                end
                if lo == hi and lo < math.huge then
                    -- This partition has exactly one valid mine count.
                    -- Any tile whose mine-count frequency equals total solutions
                    -- at that count is forced.
                    local tot = pdt.Tot
                    for v, fk in next, pdt.Freq do
                        local cnt = fk[lo] or 0
                        local t   = pdt.Tiles[v]
                        if state[t] == 0 then
                            if cnt == tot then
                                state[t] = 2   -- mine in every solution
                            elseif cnt == 0 then
                                state[t] = 1   -- safe in every solution
                            end
                        end
                    end
                end
            end
        end

        -- ── Endgame full-board enumeration ────────────────────
        -- When the total number of unknown tiles is small enough, enumerate
        -- the entire board as one unit rather than per-partition.  This is
        -- strictly more accurate than combining independent partition results
        -- because it correctly accounts for the global mine-count constraint
        -- coupling every partition together.
        local allUnknown = {}
        for _, t in ipairs(greenTiles) do
            if state[t] == 0 then allUnknown[#allUnknown+1] = t end
        end
        local endgameThreshold = CFG.MaxBruteForce   -- reuse same BT limit
        if #allUnknown > 0 and #allUnknown <= endgameThreshold
           and #allUnknown <= 60 then   -- hard cap: 60 tiles ≈ 2^60 worst case
            local cbmG, freqG, totalG, abortedG = Enumerate(allUnknown)
            if not abortedG and totalG > 0 then
                -- Replace all per-partition probability data with global result
                partData = {{ Tiles = allUnknown, Cbm = cbmG, Freq = freqG, Tot = totalG }}
                freeTiles = {}   -- all tiles are now in the global partition
            end
        end

        -- ── Global mine-count DP for inter-part weighting ──
        local NEG = -math.huge
        local p = #partData
        local weighted = false
        freeProb = 0.5

        local function LogAdd(a, b)
            if a == NEG then return b end
            if b == NEG then return a end
            if a < b then a, b = b, a end
            return a + math.log(1 + math.exp(b - a))
        end

        local function LogComb(n, k)
            if k < 0 or k > n then return NEG end
            k = math.min(k, n - k)
            local s = 0
            for i = 1, k do s += math.log(n-k+i) - math.log(i) end
            return s
        end

        if hasMines and p > 0 then
            local pre = { [0] = { [0] = 0 } }
            for i = 1, p do
                local row = {}
                for m, w in next, pre[i-1] do
                    for k, c in next, partData[i].Cbm do
                        local nm = m + k
                        if nm <= budget then
                            row[nm] = LogAdd(row[nm] or NEG, w + math.log(c))
                        end
                    end
                end
                -- Prune beam to avoid exponential blowup
                local mx = NEG
                for _, w in next, row do if w > mx then mx = w end end
                if mx > NEG then
                    local cut = mx - 40
                    for m, w in next, row do if w < cut then row[m] = nil end end
                end
                pre[i] = row
            end

            local suf = { [p+1] = { [0] = 0 } }
            for i = p, 1, -1 do
                local row = {}
                for m, w in next, suf[i+1] do
                    for k, c in next, partData[i].Cbm do
                        local nm = m + k
                        if nm <= budget then
                            row[nm] = LogAdd(row[nm] or NEG, w + math.log(c))
                        end
                    end
                end
                local mx = NEG
                for _, w in next, row do if w > mx then mx = w end end
                if mx > NEG then
                    local cut = mx - 40
                    for m, w in next, row do if w < cut then row[m] = nil end end
                end
                suf[i] = row
            end

            local f   = #freeTiles
            local lcCache = {}
            local function LC(k)
                local v = lcCache[k]
                if v == nil then v = LogComb(f, k); lcCache[k] = v end
                return v
            end

            local wTotal = NEG
            for m, wgt in next, pre[p] do
                wTotal = LogAdd(wTotal, wgt + LC(budget - m))
            end

            if wTotal > NEG then
                local ops = 0
                for i = 1, p do
                    local a, b = 0, 0
                    for _ in next, pre[i-1] do a += 1 end
                    for _ in next, suf[i+1] do b += 1 end
                    ops += a * b
                end
                if ops <= CFG.MaxDPOps then
                    weighted = true
                    for i, pdt in ipairs(partData) do
                        -- Combine prefix[i-1] × suffix[i+1]
                        local others = {}
                        for m1, w1 in next, pre[i-1] do
                            for m2, w2 in next, suf[i+1] do
                                local x = m1 + m2
                                others[x] = LogAdd(others[x] or NEG, w1 + w2)
                            end
                        end
                        local wo = {}
                        for k in next, pdt.Cbm do
                            local acc = NEG
                            for x, wgt in next, others do
                                acc = LogAdd(acc, wgt + LC(budget - k - x))
                            end
                            wo[k] = acc
                        end
                        for v, fk in next, pdt.Freq do
                            local num = NEG
                            for k, c in next, fk do
                                num = LogAdd(num, math.log(c) + (wo[k] or NEG))
                            end
                            prob[pdt.Tiles[v]] = math.clamp(math.exp(num - wTotal), 0, 1)
                        end
                        for _, t in ipairs(pdt.Tiles) do
                            if prob[t] == nil then prob[t] = 0 end
                        end
                    end
                    if f > 0 then
                        local num = NEG
                        for m, wgt in next, pre[p] do
                            local fm = budget - m
                            if fm > 0 then
                                num = LogAdd(num, wgt + LC(fm) + math.log(fm))
                            end
                        end
                        freeProb = math.clamp(math.exp(num - wTotal) / f, 0, 1)
                    else
                        freeProb = 1
                    end
                end
            end
        end

        -- Fallback: per-part raw frequencies
        if not weighted then
            for _, pdt in ipairs(partData) do
                for v, fk in next, pdt.Freq do
                    local s = 0
                    for _, c in next, fk do s += c end
                    prob[pdt.Tiles[v]] = s / pdt.Tot
                end
                for _, t in ipairs(pdt.Tiles) do
                    if prob[t] == nil then prob[t] = 0 end
                end
            end
            if #freeTiles > 0 then
                if hasMines then
                    -- mines still unaccounted for, spread over the tiles that no number touches.
                    -- (the old formula subtracted ALL solved tiles and divided by 0 → fake 50%/100%)
                    local expectedFrontier = 0
                    for _, pdt in ipairs(partData) do
                        for _, fk in next, pdt.Freq do
                            local sm = 0
                            for _, c in next, fk do sm += c end
                            expectedFrontier += sm / pdt.Tot
                        end
                    end
                    local dens = math.clamp(budget / math.max(1, nUnknown), 0, 1)
                    for _, tiles in ipairs(failedParts) do expectedFrontier += #tiles * dens end
                    freeProb = math.clamp((budget - expectedFrontier) / #freeTiles, 0, 1)
                else
                    freeProb = 0.25
                end
            end
        end

        -- Promote probabilistic certainties to deduced states
        local resolved = false
        for t, pv in next, prob do
            if pv <= 1e-7 then
                state[t] = 1; resolved = true
                if sampledSet[t] then weak[t] = true end
            elseif pv >= 1 - 1e-7 then
                state[t] = 2; resolved = true
            end
        end
        if not resolved or cascade == CFG.MaxCascade then break end
        Deduct()
    end

    -- ─── BEST MOVE SELECTION ─────────────────────────────
    BuildConstraints()
    frontier, freeTiles = {}, {}
    for _, t in ipairs(greenTiles) do
        if state[t] == 0 then
            if consOf[t] then frontier[#frontier+1] = t
            else           freeTiles[#freeTiles+1] = t end
        end
    end

    -- Information score: prefers tiles with more unknown constrained neighbours
    local function InfoScore(t)
        local gx, gz = TileGridPos(t)
        local s = 0
        for _, nb in ipairs(SV.Adjacency[t]) do
            if state[nb] == 0 then
                s += 1
                if consOf[nb] then s += 2 end
            end
        end
        if gx and IsEdge(gx, gz) then
            s -= 1
            if IsCorner(gx, gz) then s -= 1 end
        end
        return s
    end

    -- Candidates are gathered first and judged afterwards, so the result no longer
    -- depends on table iteration order (the cause of "50% vs 50%" flip-flopping).
    local cands = {}
    local function Consider(t, pv)
        if t then cands[#cands + 1] = { t = t, p = pv } end
    end
    for t, pv in next, prob do
        if state[t] == 0 then Consider(t, pv) end
    end

    local function Centroid(tiles)
        local cx, cy, cz, n = 0, 0, 0, #tiles
        for _, t in ipairs(tiles) do
            local p = t.Position; cx += p.X; cy += p.Y; cz += p.Z
        end
        return Vector3.new(cx/n, cy/n, cz/n)
    end
    local function Nearest(tiles, c)
        local best, bd = tiles[1], math.huge
        for _, t in ipairs(tiles) do
            local d = (t.Position - c).Magnitude
            if d < bd then bd = d; best = t end
        end
        return best
    end

    -- Partitions too big to enumerate/sample: use the real remaining-mine density
    -- (not a made-up 0.5) and flag the numbers as estimates.
    if #failedParts > 0 then
        local nUnk = 0
        for _, t in ipairs(greenTiles) do if state[t] == 0 then nUnk += 1 end end
        local rem  = hasMines and ComputeBudget() or math.huge
        local dens = (hasMines and rem ~= math.huge) and math.clamp(rem / math.max(1, nUnk), 0, 1) or 0.25
        for _, tiles in ipairs(failedParts) do
            for _, t in ipairs(tiles) do
                if state[t] == 0 then estProb[t] = dens end
            end
            Consider(Nearest(tiles, Centroid(tiles)), dens)
        end
    end

    -- Best free tile (no number touches it): most informative, then lowest index
    if #freeTiles > 0 then
        local bf, bi = nil, -math.huge
        for _, t in ipairs(freeTiles) do
            local inf = InfoScore(t)
            if inf > bi or (inf == bi and (SV.TileIndex[t] or 0) < (SV.TileIndex[bf] or 0)) then bf, bi = t, inf end
        end
        if bf then Consider(bf, freeProb) end
    end

    -- Lowest risk wins. Sampled numbers carry ~1% noise, so anything within TIE of the
    -- minimum is a tie; ties go to the most informative tile, then to the previous
    -- best (hysteresis), then to the lowest tile index (stable).
    local bestTile, bestProb, bestInfo = nil, math.huge, -math.huge
    local mn = math.huge
    for _, c in ipairs(cands) do if c.p < mn then mn = c.p end end
    local TIE = (next(sampledSet) ~= nil) and 0.012 or 0.002
    for _, c in ipairs(cands) do
        if c.p <= mn + TIE then
            local inf = InfoScore(c.t)
            if c.t == SV.PrevBest then inf += 1.5 end
            if bestTile == nil or inf > bestInfo
               or (inf == bestInfo and (SV.TileIndex[c.t] or 0) < (SV.TileIndex[bestTile] or 0)) then
                bestTile, bestProb, bestInfo = c.t, c.p, inf
            end
        end
    end
    SV.PrevBest = bestTile
    for t, v in next, estProb do
        if prob[t] == nil then prob[t] = v end
    end

    if not GameRunning.Value then ClearAll(); return end

    SV.LastRender = {
        green = greenTiles, state = state, beige = beigeSet,
        prob = prob, best = bestTile, bestProb = bestProb,
        weak = weak, flagged = flagged, wrong = wrongFlag, pure = pure, est = estProb,
    }
    Render(SV.LastRender)
    SV.LastSig = sig
end
