(local util (require :util))

(local map {})
(local tiles {})

; TODO find better way to handle tiles
(local tileTypes 
  {:death {:action :death :width 8 :height 8 :offX 0 :offY 0}
   :laser {:action :death :width 4 :height 8 :offX 2 :offY 0}
   :ground {:action :ground :width 8 :height 8 :offX 0 :offY 0}
   :bounce {:action :bounce :width 4 :height 8 :offX 4 :offY 0 :direction util.sub}
   :bounceLeft {:action :bounce :width 4 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub}
   :conveyorUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add}})
(local tileFunctions 
  {389 tileTypes.death
   393 tileTypes.laser
   374 tileTypes.laser
   376 tileTypes.laser
   201 tileTypes.ground
   211 tileTypes.bounce
   210 tileTypes.bounceLeft
   1 tileTypes.conveyorDown
   2 tileTypes.conveyorUp})

(fn getTile [tileId] (. tileFunctions tileId))

(fn map.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) 341))))

(fn map.setTile [x y tile]
  (tset (. tiles x) y tile)
  (let [type (getTile tile)
        {: width : height : offX : offY : action : direction} type
        realX (+ offX (* 8 (- x 1)))
        realY (+ offY (* 8 (- y 1)))
        existing (world:queryPoint (+ realX 4) (+ realY 4))]
    (each [index tile (pairs existing)] (world:remove tile))
    (when action 
      (world:add {action true :direction direction} realX realY width height))))

(fn map.draw []
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (love.graphics.draw tileSheet (. tileAtlas (. (. tiles x) y)) (* (- x 1) 8) (* (- y 1) 8)))))

map
