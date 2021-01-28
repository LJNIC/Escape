(local map {})
(local tiles {})
(local tileTypes {:lava 389 :background 341 :ground 181})
(local tileFunctions {389 :death 181 :ground})

(fn getTile [tileName] (. tileTypes tileName))
(fn getTileAction [tileId] (. tileFunctions tileId))

(fn map.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) (getTile :background)))))

(fn map.setTile [x y tile]
  (tset (. tiles x) y tile)
  (let [realX (* 8 (- x 1))
        realY (* 8 (- y 1))
        existing (world:queryPoint (+ realX 4) (+ realY 4))
        action (getTileAction tile)]
    (each [index tile (pairs existing)] (world:remove tile))
    (when action 
      (world:add {(getTileAction tile) true} realX realY 8 8))))

(fn map.draw []
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (love.graphics.draw tileSheet (. tileAtlas (. (. tiles x) y)) (* (- x 1) 8) (* (- y 1) 8)))))

map
