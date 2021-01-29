(local map {})
(local tiles {})

; find better way to handle tiles
(local tileTypes 
  {:lava {:action :death :width 8 :height 8 :offX 0}
   :ground {:action :ground :width 8 :height 8 :offX 0}
   :bounce {:action :bounce :width 4 :height 6 :offX 6}})
(local tileFunctions 
  {389 (. tileTypes :lava) 
   181 (. tileTypes :ground) 
   211 (. tileTypes :bounce)
   210 (. tileTypes :bounce)})

(fn getTile [tileId] (. tileFunctions tileId))

(fn map.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) 341))))

(fn map.setTile [x y tile]
  (tset (. tiles x) y tile)
  (let [type (getTile tile)
        {: width : height : offX : action} type
        realX (+ offX (* 8 (- x 1)))
        realY (* 8 (- y 1))
        existing (world:queryPoint (+ realX 4) (+ realY 4))]
    (each [index tile (pairs existing)] (world:remove tile))
    (when action 
      (world:add {action true} realX realY width height))))

(fn map.draw []
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (love.graphics.draw tileSheet (. tileAtlas (. (. tiles x) y)) (* (- x 1) 8) (* (- y 1) 8)))))

map
