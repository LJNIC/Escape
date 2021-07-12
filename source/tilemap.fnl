(local util (require :util))
(local anim8 (require :lib/anim8))
(local map functional.map)

; tile sheet - just the image
; tile atlas - array of quads
; tile set   - id -> tile info table

(local tile-sheet (love.graphics.newImage "assets/tiles.png"))
(local tile-atlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tile-atlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(fn create-animation [animation]
  (if (= nil animation)
    nil
    (anim8.newAnimation 
      (map animation (fn [frame] (. tile-atlas frame.tileid)))
      (map animation (fn [frame] frame.duration)))))

(local default-tile {:width 8 :height 8 :offset-x 0 :offset-y 0 :action nil})
(tset default-tile :__index default-tile)
(local tileset 
  (let [tiled (. (require :levels/tileset) :tiles)
        tileset {}]
    (each [_ tile (ipairs tiled)]
      (let [{: id : properties : animation} tile
            animation (create-animation animation)
            tile-info (setmetatable (table.overlay {: animation} (or properties {})) default-tile)]
        (tset tileset id tile-info)))
    tileset))

(local tilemap {})
(var tiles {})
(var background {})

(fn tilemap.each-tile [apply tile-list]
  (var x 1)
  (var y 1)
  (each [index tile-id (ipairs (or tile-list tiles))]
    (apply x y tile-id)
    (set x (+ x 1))
    (when (> x tilemap.width) 
      (set y (+ 1 y))
      (set x 1))))

(fn load-objects [objects]
  (each [_ object (ipairs objects)]
    (when (= object.name "spawn")
      (set tilemap.player (vec2 object.x object.y)))))

(fn tilemap.load-map [level-file cam]
  "Loads a new map into the game world"
  (local level (require level-file))
  (set tilemap.width level.width)
  (set tilemap.height level.height)
  (each [_ layer (ipairs (. level.layers))]
    (if 
      (= layer.name "tiles")
      (set tiles layer.data)
      (= layer.name "background")
      (set background layer.data)
      (= layer.name "objects")
      (load-objects layer.objects)))
  ; shift the camera bound up one tile, and shrink it one tile
  (cam:setBounds TILE_WIDTH 0 (- WIDTH TILE_WIDTH) (* tilemap.height TILE_WIDTH))
  (tilemap.each-tile tilemap.set-tile))

(fn tilemap.set-tile [x y tile-id]
  "Sets a tile in the game world"
  (let [tile-info (or (. tileset (- tile-id 1)) default-tile)
        {: width : height : offset-x : offset-y : action : direction} tile-info 
        real-x (+ offset-x (* 8 (- x 1)))
        real-y (+ offset-y (* 8 (- y 1)))
        existing (world:queryPoint (+ real-x 4) (+ real-y 4))]
    (each [index tile (pairs existing)] (world:remove tile))
    (when action 
      (world:add {action true :direction direction} real-x real-y width height))))

(fn tilemap.update [dt cam]
  "Updates all of the animations in the map"
  (each [_ tile (ipairs tileset)]
    (when tile.animation
      (tile.animation:update dt))))

(fn draw-tile [x y tile-id]
  "Draws a single tile"
  (let [tile-info (. tileset tile-id)
        real-x (* (- x 1) 8)
        real-y (* (- y 1) 8)
        animation (and tile-info tile-info.animation)]
    (if (not= nil animation)
      (animation:draw tile-sheet real-x real-y)
      (love.graphics.draw tile-sheet (. tile-atlas (or (and (= tile-id 0) 400) tile-id)) real-x real-y))))

(fn tilemap.draw []
  "Draws the map; the camera handles drawing the appropriate area"
  (tilemap.each-tile draw-tile))

(fn tilemap.draw-background [cam]
  (let [orig-y cam.y
        new-y (math.floor (* cam.y 0.5))]
    (set cam.y new-y)
    (cam:attach)
    (tilemap.each-tile draw-tile background)
    (set cam.y orig-y)
    (cam:detach)))

tilemap
