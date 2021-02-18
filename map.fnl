(local util (require :util))
(local anim8 (require :lib/anim8))

(local map {})
(var tiles {})

(local tilesetGrid (anim8.newGrid 8 8 160 160))
(local conveyorTopUp (anim8.newAnimation (tilesetGrid "18-20" 14) 0.1))
(local conveyorMidUp (anim8.newAnimation (tilesetGrid "18-20" 15) 0.1))
(local conveyorBottomUp (anim8.newAnimation (tilesetGrid "18-20" 16) 0.1))
(local conveyorTopDown (anim8.newAnimation (tilesetGrid "20-18" 14) 0.1))
(local conveyorMidDown (anim8.newAnimation (tilesetGrid "20-18" 15) 0.1))
(local conveyorBottomDown (anim8.newAnimation (tilesetGrid "20-18" 16) 0.1))

; TODO find better way to handle tiles
(local tileTypes 
  {:laser {:action :death :width 4 :height 8 :offX 2 :offY 0}
   :laserH {:action :death :width 8 :height 4 :offX 0 :offY 2}
   :ground {:action :ground :width 8 :height 8 :offX 0 :offY 0}
   :bounce {:action :bounce :width 4 :height 8 :offX 4 :offY 0 :direction util.sub}
   :bounceLeft {:action :bounce :width 4 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyorTopDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyorTopDown}
   :conveyorMidDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyorMidDown}
   :conveyorBottomDown {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyorBottomDown}
   :conveyorTopUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorTopUp}
   :conveyorMidUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorMidUp}
   :conveyorBottomUp {:action :conveyor :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyorBottomUp}})
(local tileFunctions 
  {393 tileTypes.laser
   395 tileTypes.laserH
   374 tileTypes.laser
   376 tileTypes.laser
   244 tileTypes.ground
   245 tileTypes.ground
   246 tileTypes.ground
   243 tileTypes.ground
   242 tileTypes.ground
   211 tileTypes.bounce
   210 tileTypes.bounceLeft
   298 tileTypes.conveyorMidUp
   318 tileTypes.conveyorBottomUp
   278 tileTypes.conveyorTopUp
   299 tileTypes.conveyorMidDown
   319 tileTypes.conveyorBottomDown
   279 tileTypes.conveyorTopDown})

(fn getTile [tileId] (. tileFunctions tileId))

(fn map.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) 400))))

(fn map.loadMap [newMap]
  "Loads a new map into the game world"
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (let [id (. (. newMap x) y)
            type (getTile id)]
        (if (= nil type)
          (tset (. tiles x) y id)
          (map.setTile x y id))))))

(fn map.setTile [x y tile]
  "Sets a tile in the game world"
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
