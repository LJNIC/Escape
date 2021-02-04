(local util (require :util))
(local anim8 (require :lib/anim8))

(local map {})
(local tiles {})

(local tilesetGrid (anim8.newGrid 8 8 160 160))
(local conveyorTopUp (anim8.newAnimation (tilesetGrid "18-20" 14) 0.1))
(local conveyorMidUp (anim8.newAnimation (tilesetGrid "18-20" 15) 0.1))
(local conveyorBottomUp (anim8.newAnimation (tilesetGrid "18-20" 16) 0.1))
(local conveyorTopDown (anim8.newAnimation (tilesetGrid "18-20" 14) 0.1))
(local conveyorMidDown (anim8.newAnimation (tilesetGrid "18-20" 14) 0.1))
(local conveyorBottomDown (anim8.newAnimation (tilesetGrid "18-20" 14) 0.1))

; TODO find better way to handle tiles
(local tileTypes 
  {:death {:action :death :width 8 :height 8 :offX 0 :offY 0}
   :laser {:action :death :width 4 :height 8 :offX 2 :offY 0}
   :ground {:action :ground :width 8 :height 8 :offX 0 :offY 0}
   :bounce {:action :bounce :width 4 :height 8 :offX 4 :offY 0 :direction util.sub}
   :bounceLeft {:action :bounce :width 4 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorTopDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorMidDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorBottomDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorTopUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorTopUp}
   :conveyorMidUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorMidUp}
   :conveyorBottomUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorBottomUp}})
(local tileFunctions 
  {389 tileTypes.death
   393 tileTypes.laser
   374 tileTypes.laser
   376 tileTypes.laser
   201 tileTypes.ground
   211 tileTypes.bounce
   210 tileTypes.bounceLeft
   298 tileTypes.conveyorMidUp
   318 tileTypes.conveyorBottomUp
   278 tileTypes.conveyorTopUp})

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

(fn map.update [dt]
  (conveyorBottomDown:update dt)
  (conveyorBottomUp:update dt)
  (conveyorTopDown:update dt)
  (conveyorMidDown:update dt)
  (conveyorTopUp:update dt)
  (conveyorMidUp:update dt))

(fn map.draw []
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (let [tile (. (. tiles x) y)
            animation (if (getTile tile) (. (getTile tile) :animation))
            realX (* (- x 1) 8)
            realY (* (- y 1) 8)]
        (if (not= nil animation)
          (animation:draw tileSheet realX realY)
          (love.graphics.draw tileSheet (. tileAtlas tile) realX realY))))))

map
