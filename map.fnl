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
   395 tileTypes.laserH
   395 tileTypes.laserH
   374 tileTypes.laser
   376 tileTypes.laser
   244 tileTypes.ground
   245 tileTypes.ground
   246 tileTypes.ground
   243 tileTypes.ground
   242 tileTypes.ground
   8 tileTypes.ground
   241 tileTypes.ground
   211 tileTypes.bounce
   210 tileTypes.bounceLeft
   298 tileTypes.conveyorMidUp
   318 tileTypes.conveyorBottomUp
   278 tileTypes.conveyorTopUp
   299 tileTypes.conveyorMidDown
   319 tileTypes.conveyorBottomDown
   279 tileTypes.conveyorTopDown})

(local tileSheet (love.graphics.newImage "assets/tiles.png"))
(local tileAtlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tileAtlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(fn getTile [tileId] (. tileFunctions tileId))

(fn map.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) 400))))

;   1
;8 [ ] 2
;   4
(local autoTiles 
;                              0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
  {tileTypes.ground          [241 242 242 242 242 246 242 246 242 242 245 245 242 246 245 8]
   tileTypes.laser           [393 374 393 393 376 393 393 393 393 393 393 393 393 393 393 393]
   tileTypes.laserH          [395 395 380 395 395 395 395 395 379 395 395 395 395 395 395 395]
   tileTypes.conveyorMidUp   [298 318 298 298 278 298 298 298 298 298 298 298 298 298 298 298]
   tileTypes.conveyorMidDown [299 319 299 299 279 299 299 299 299 299 299 299 299 299 299 299]})

(fn getTileAt [map x y]
  (getTile (. (. map x) y)))

(fn sumTile [m width height x y]
  (let [sum 0
        tile (getTileAt m x y)]
    (-> sum
      (+ (if (and (> x 1) (= tile (getTileAt m (- x 1) y))) 8 0))
      (+ (if (and (< x width) (= tile (getTileAt m (+ 1 x) y))) 2 0))
      (+ (if (and (> y 1) (= tile (getTileAt m x (+ 1 y)))) 4 0))
      (+ (if (and (< y height) (= tile (getTileAt m x (- y 1)))) 1 0)))))

(fn autoTile [m width height x y]
  (let [type (getTileAt m x y)
        autoType (. autoTiles type)]
    (if autoType
      (let [bitmask (+ 1 (sumTile m width height x y))]
        (. autoType bitmask))
      (. (. m x) y))))

(fn map.loadMap [newMap width height cam]
  "Loads a new map into the game world"
  (tset map :width width)
  (tset map :height height)
  (set tiles {})
  ; shift the camera bound up one tile, and shrink it one tile
  (cam:setBounds TILE_WIDTH 0 (- WIDTH TILE_WIDTH) (* height TILE_WIDTH))
  (for [x 1 width]
    (table.insert tiles {})
    (for [y 1 height]
      (print x y)
      (let [id (autoTile newMap width height x y)
            type (getTile id)]
        (if (= 1 id)
            (do 
              (tset map :player {:x x :y y})
              (tset (. tiles x) y 400))
            (= nil type)
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
  "Updates all of the animations in the map"
  (conveyorBottomDown:update dt)
  (conveyorBottomUp:update dt)
  (conveyorTopDown:update dt)
  (conveyorMidDown:update dt)
  (conveyorTopUp:update dt)
  (conveyorMidUp:update dt))

(fn map.draw []
  "Draws the map; the camera handles drawing the appropriate area"
  (for [x 1 map.width]
    (for [y 1 map.height]
      (let [tile (. (. tiles x) y)
            animation (if (getTile tile) (. (getTile tile) :animation))
            realX (* (- x 1) 8)
            realY (* (- y 1) 8)]
        (if (not= nil animation)
          (animation:draw tileSheet realX realY)
          (love.graphics.draw tileSheet (. tileAtlas tile) realX realY))))))

map
