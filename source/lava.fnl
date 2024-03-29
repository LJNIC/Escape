(local anim8 (require :source.lib.anim8))
(local util (require :source.util))

(local lava {:moving false :action "death" :x tile-width :y tile-width 
             :image (love.graphics.newImage "source/assets/lava_wave.png")
             :background (love.graphics.newImage "source/assets/lava.png")})
(local lava-grid (anim8.newGrid 16 8 128 8))
(fn animation [frames duration]
  (anim8.newAnimation frames duration))
(set lava.animation (animation (lava-grid "1-8" 1) 0.15))

; Initialize lava
(fn lava.init [world tilemap]
  (let [height (* tilemap.height tile-width)]
    (set lava.y height)
    (world:add lava lava.x lava.y game-width height)))

(fn lava.update [dt]
  (when lava.moving
    (util.update-object lava lava.x (- lava.y (* 10 dt)))
    (lava.animation:update dt)))

(fn lava.draw [] 
  (love.graphics.draw lava.background 0 lava.y)
  (for [x 0 128 16]
    (lava.animation:draw lava.image x lava.y)))

lava
