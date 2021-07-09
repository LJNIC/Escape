(local util (require :util))
(local anim8 (require :lib/anim8))

(local tilemap {})
(var tiles {})

(local tileset-grid (anim8.newGrid 8 8 160 160))
(local conveyor-top-up (anim8.newAnimation (tileset-grid "18-20" 14) 0.1))
(local conveyor-mid-up (anim8.newAnimation (tileset-grid "18-20" 15) 0.1))
(local conveyor-bottom-up (anim8.newAnimation (tileset-grid "18-20" 16) 0.1))
(local conveyor-top-down (anim8.newAnimation (tileset-grid "20-18" 14) 0.1))
(local conveyor-mid-down (anim8.newAnimation (tileset-grid "20-18" 15) 0.1))
(local conveyor-bottom-down (anim8.newAnimation (tileset-grid "20-18" 16) 0.1))

; TODO find better way to handle tiles
(local tile-types 
  {:laser {:action "death" :width 4 :height 8 :offX 2 :offY 0}
   :laser-h {:action "death" :width 8 :height 4 :offX 0 :offY 2}
   :ground {:action "ground" :width 8 :height 8 :offX 0 :offY 0}
   :sticky-ground {:action "sticky" :width 8 :height 8 :offX 0 :offY 0}
   :bounce {:action "bounce" :width 4 :height 8 :offX 4 :offY 0 :direction util.sub}
   :bounce-left {:action "bounce" :width 4 :height 8 :offX 0 :offY 0 :direction util.add}
   :conveyor-top-down {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyor-top-down}
   :conveyor-mid-down {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyor-mid-down}
   :conveyor-bottom-down {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.add :animation conveyor-bottom-down}
   :conveyor-top-up {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyor-top-up}
   :conveyor-mid-up {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyor-mid-up}
   :conveyor-bottom-up {:action "conveyor" :width 8 :height 8 :offX 0 :offY 0 :direction util.sub :animation conveyor-bottom-up}})
(local tile-functions 
  {393 tile-types.laser
   395 tile-types.laser-h
   395 tile-types.laser-h
   395 tile-types.laser-h
   374 tile-types.laser
   376 tile-types.laser
   244 tile-types.ground
   245 tile-types.ground
   246 tile-types.ground
   243 tile-types.ground
   242 tile-types.ground
   8 tile-types.ground
   241 tile-types.ground
   211 tile-types.bounce
   210 tile-types.bounce-left
   298 tile-types.conveyor-mid-up
   318 tile-types.conveyor-bottom-up
   278 tile-types.conveyor-top-up
   299 tile-types.conveyor-mid-down
   319 tile-types.conveyor-bottom-down
   279 tile-types.conveyor-top-down})

(local tile-sheet (love.graphics.newImage "assets/tiles.png"))
(local tile-atlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tile-atlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(fn get-tile [tile-id] (. tile-functions tile-id))

(fn tilemap.init []
  (for [x 1 GAME_WIDTH]
    (table.insert tiles [])
    (for [y 1 GAME_HEIGHT]
      (table.insert (. tiles x) 400))))

;   1
;8 [ ] 2
;   4
(local auto-tiles 
;                                 0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
  {tile-types.ground            [241 242 242 242 242 246 242 246 242 242 245 245 242 246 245 8]
   tile-types.laser             [393 374 393 393 376 393 393 393 393 393 393 393 393 393 393 393]
   tile-types.laser-h           [395 395 380 395 395 395 395 395 379 395 395 395 395 395 395 395]
   tile-types.conveyor-mid-up   [298 318 298 298 278 298 298 298 298 298 298 298 298 298 298 298]
   tile-types.conveyor-mid-down [299 319 299 299 279 299 299 299 299 299 299 299 299 299 299 299]})

(fn get-tile-at [m x y]
  (get-tile (. (. m x) y)))

(fn sum-tile [m width height x y]
  (let [sum 0
        tile (get-tile-at m x y)]
    (-> sum
      (+ (if (and (> x 1) (= tile (get-tile-at m (- x 1) y))) 8 0))
      (+ (if (and (< x width) (= tile (get-tile-at m (+ 1 x) y))) 2 0))
      (+ (if (and (> y 1) (= tile (get-tile-at m x (+ 1 y)))) 4 0))
      (+ (if (and (< y height) (= tile (get-tile-at m x (- y 1)))) 1 0)))))

(fn auto-tile [m width height x y]
  (let [type (get-tile-at m x y)
        auto-type (. auto-tiles type)]
    (if auto-type
      (let [bitmask (+ 1 (sum-tile m width height x y))]
        (. auto-type bitmask))
      (. (. m x) y))))

(fn tilemap.load-map [new-map width height cam]
  "Loads a new map into the game world"
  (set tilemap.width width)
  (set tilemap.height height)
  (set tiles {})
  ; shift the camera bound up one tile, and shrink it one tile
  (cam:setBounds TILE_WIDTH 0 (- WIDTH TILE_WIDTH) (* height TILE_WIDTH))
  (for [x 1 width]
    (table.insert tiles {})
    (for [y 1 height]
      (let [id (auto-tile new-map width height x y)
            type (get-tile id)]
        (if (= 1 id)
            (do 
              (set tilemap.player {: x : y})
              (tset (. tiles x) y 400))
            (= nil type)
            (tset (. tiles x) y id)
            (tilemap.set-tile x y id))))))

(fn tilemap.set-tile [x y tile]
  "Sets a tile in the game world"
  (tset (. tiles x) y tile)
  (let [type (get-tile tile)
        {: width : height : offX : offY : action : direction} type
        realX (+ offX (* 8 (- x 1)))
        realY (+ offY (* 8 (- y 1)))
        existing (world:queryPoint (+ realX 4) (+ realY 4))]
    (each [index tile (pairs existing)] (world:remove tile))
    (when action 
      (world:add {action true :direction direction} realX realY width height))))

(fn tilemap.update [dt]
  "Updates all of the animations in the map"
  (conveyor-bottom-down:update dt)
  (conveyor-bottom-up:update dt)
  (conveyor-top-down:update dt)
  (conveyor-mid-down:update dt)
  (conveyor-top-up:update dt)
  (conveyor-mid-up:update dt))

(fn tilemap.draw []
  "Draws the map; the camera handles drawing the appropriate area"
  (for [x 1 tilemap.width]
    (for [y 1 tilemap.height]
      (let [tile (. (. tiles x) y)
            animation (if (get-tile tile) (. (get-tile tile) :animation))
            real-x (* (- x 1) 8)
            real-y (* (- y 1) 8)]
        (if (not= nil animation)
          (animation:draw tile-sheet real-x real-y)
          (love.graphics.draw tile-sheet (. tile-atlas tile) real-x real-y))))))

tilemap
