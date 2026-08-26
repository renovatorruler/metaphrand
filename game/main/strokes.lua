-- Letterform data. ENGINE GLUE ONLY (CLAUDE.md exception).
--
-- Each letter is an ordered list of strokes, and each stroke is a polyline in a
-- 0..1 x 0..1 box with y measured downward from the top. Order and direction are
-- both meaningful now: the child activates a stroke by following it from its
-- first point to its last, so these polylines ARE the stroke order the show
-- teaches. They were previously authored for shape comparison only, where
-- direction did not matter, and have been reordered to the standard Russian
-- print prescriptions.
local M = {}

M.letters = {
  -- spine down, then each arm from its outer end in to the spine and out again
  ["К"] = { { {0.30,0.05},{0.30,0.95} },
            { {0.72,0.05},{0.31,0.50} },
            { {0.31,0.50},{0.74,0.95} } },

  -- one closed loop, anticlockwise from the top
  ["О"] = { { {0.50,0.05},{0.20,0.28},{0.15,0.50},{0.20,0.72},{0.50,0.95},
              {0.80,0.72},{0.85,0.50},{0.80,0.28},{0.50,0.05} } },

  -- bar left to right, then the stem down
  ["Т"] = { { {0.10,0.08},{0.90,0.08} },
            { {0.50,0.08},{0.50,0.95} } },

  ["С"] = { { {0.85,0.18},{0.50,0.05},{0.18,0.28},{0.13,0.50},{0.18,0.72},{0.50,0.95},{0.85,0.82} } },

  -- both slants downward from the apex, then the crossbar left to right
  ["А"] = { { {0.50,0.05},{0.15,0.95} },
            { {0.50,0.05},{0.85,0.95} },
            { {0.28,0.66},{0.72,0.66} } },

  -- left stem down, in to the valley, out to the right shoulder, right stem down
  ["М"] = { { {0.10,0.05},{0.10,0.95} },
            { {0.10,0.05},{0.50,0.58} },
            { {0.50,0.58},{0.90,0.05} },
            { {0.90,0.05},{0.90,0.95} } },

  -- left slant down from the apex, top bar left to right, right stem down
  ["Л"] = { { {0.40,0.05},{0.20,0.95} },
            { {0.40,0.05},{0.78,0.05} },
            { {0.78,0.05},{0.78,0.95} } },

  -- stem down, top bar left to right, then the bowl
  ["Б"] = { { {0.25,0.05},{0.25,0.95} },
            { {0.25,0.05},{0.78,0.05} },
            { {0.25,0.48},{0.62,0.48},{0.80,0.62},{0.80,0.78},{0.62,0.95},{0.25,0.95} } },
}

function M.stroke_count(letter)
  local L = M.letters[letter]
  return L and #L or 0
end

return M
