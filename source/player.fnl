(local util (require :source.util))
(local anim8 (require :source.lib.anim8))
(local audio (require :source.audio))
(local timers (require :source.timers))
(local animations (require :source.animations))
(local tilemap (require :source.tilemap))

(local character-image (love.graphics.newImage "source/assets/astro.png"))
(local character-grid (anim8.newGrid 8 8 128 8))
(local walk (anim8.newAnimation (character-grid "2-7" 1) 0.1))
(local jump (anim8.newAnimation (character-grid 5 1) 1000000))
(local air-jump (anim8.newAnimation (character-grid 16 1 5 1) 0.1 "pauseAtEnd"))
(local fall (anim8.newAnimation (character-grid 9 1) 10000))
(local wall (anim8.newAnimation (character-grid 11 1) 1000000))

(local explosion-image (love.graphics.newImage "source/assets/explosion2.png"))
(local explosion-grid (anim8.newGrid 16 16 256 16))
(local die (anim8.newAnimation (explosion-grid "6-16" 1) 0.1 "pauseAtEnd"))
(local dust-image (love.graphics.newImage "source/assets/dust.png"))
(dust-image:setFilter "linear" "linear")
(local dust-animation
  (let [grid (anim8.newGrid 8 8 88 8)]
    (anim8.newAnimation (grid "1-10" 1) 0.05 "pauseAtEnd")))
(local small-dust-image (love.graphics.newImage "source/assets/dust2.png"))
(local small-dust-animation 
  (let [grid (anim8.newGrid 6 6 66 6)]
    (anim8.newAnimation (grid "1-10" 1) 0.05 "pauseAtEnd")))
(local dusts {})

(local SPEED 40)
(local WEIGHT 600)
(local JUMP_GRAVITY -80)
; speed      - horizontal speed
; direction  - a function that either adds or subtracts to the player's X position
; jumping    - whether the player is in the process of jumping (input)
; jump-timer  - how long player has been holding jump
; has-jump    - whether the player can double jump
; on-wall     - whether the player is hanging on a wall/
; on-ground   - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; animation  - which animation to draw (walk, die, jump, etc)
; image      - the corresponding image for the animation
; alive      - whether the player is dead or alive
(local player {:x 16 :y 164 :speed SPEED :direction util.add :jumping false :jump-timer 0
               :has-jump false :on-wall false :on-ground true :gravity 0 :weight WEIGHT
               :animation walk :image character-image :alive true})

(fn player.init [world tilemap]
  (when tilemap.player 
    (set player.x (+ tilemap.player.x tile-width))
    (set player.y (- tilemap.player.y tile-width)))
  (world:add player player.x player.y (- tile-width 2) (- tile-width 1)))

(fn player.kill []
  (audio.play :die)
  (audio.play :die2 {:volume 0.6})
  (set player.image explosion-image)
  (set player.animation die)
  (set player.alive false))

(fn player.normal-jump []
  (audio.play :jump {:pitch (+ 0.5 (love.math.random))})
  (set player.jumping true)
  (set player.gravity JUMP_GRAVITY)
  (set player.on-ground false)
  (set player.has-jump true))

(fn player.wall-jump [is-air]
  (when (not is-air)
    (audio.play :jump {:pitch (+ 0.5 (love.math.random))}))
  (if (not player.on-wall)
      (set player.has-jump false)
      (set player.has-jump true))
  (set player.jumping true)
  (set player.direction (util.opposite player.direction))
  (set player.gravity JUMP_GRAVITY)
  (set player.on-ground false)
  (set player.on-wall false)
  (set player.weight WEIGHT)
  (set player.speed SPEED))

(fn create-dust [x y animation dir]
  (animations.add x y animation dust-image dir (love.math.random 50 60) dir))

(fn player.air-jump []
  (air-jump:gotoFrame 1)
  (air-jump:resume)
  (set player.animation air-jump)
  (set player.jet (audio.play :jet {:pitch 0.75}))
  (timers.add 
    0.15
    (fn [t]
      (create-dust player.x player.y (let [d (dust-animation:clone)] (d:flipV)) (vec2 0 1))
      (create-dust (+ player.x 3) player.y (let [d (dust-animation:clone)] (d:flipH)) (vec2 0.25 1))
      (create-dust (- player.x 3) player.y (dust-animation:clone) (vec2 -0.25 1))))
  (player.wall-jump true))

(fn player.jump []
  (set player.animation jump)
  (if player.on-wall
      (player.wall-jump)
      player.has-jump
      (player.air-jump)
      player.on-ground
      (player.normal-jump)))

(fn create-small-dust [x y animation dir]
  (animations.add x y animation small-dust-image dir 55))

(fn player.handle-ground [col]
  (if (or (= col.normal.x -1) (= col.normal.x 1))
      (do 
        (set player.on-wall true)
        (set player.animation wall)
        (set player.weight 1)
        (set player.gravity 10)
        (set player.has-jump true))
        ; we hit the ground
      (= col.normal.y -1)
      (do 
        (set player.gravity 0)
        (when (not player.on-ground)
          (create-small-dust player.x (+ player.y 3) (let [d (dust-animation:clone)] (d:flipV)) (vec2 1 0))
          (create-small-dust (+ player.x 3) (+ player.y 3) (let [d (dust-animation:clone)] (d:flipH)) (vec2 -1 0)))
        (set player.on-ground true)
        (set player.speed SPEED)
        (when (not player.on-wall) (set player.animation walk))
        (set player.has-jump false))
      ; we hit a ceiling
      (= col.normal.y 1)
      (do 
        (set player.gravity 25))))

(fn player.conveyor [col]
  (player.handle-ground col)
  (if (= col.normal.x -1) 
      (set player.gravity (col.other.direction 0 20))
      (= col.normal.x 1)
      (set player.gravity (col.other.direction 0 -20))))

(fn get-direction [num]
  (let [sign (math.sign num)]
    (if (= sign -1) util.sub util.add)))

(fn player.bounce [col]
  (set player.speed SPEED)
  (set player.animation jump)
  (if (or (= col.normal.y 1) (= col.normal.y -1))
      (player.handle-ground col)
      player.on-wall
      (do
        (audio.play :bounce)
        (player.wall-jump) 
        (set player.gravity -100))
      (do 
        (audio.play :bounce)
        (set player.direction (get-direction col.normal.x))
        (player.normal-jump)
        (set player.gravity -100))))

(fn player.button [col]
  (set col.other.tile-id 193)
  (world:remove col.other)
  (audio.play :button))

(fn void [] (+ 0 0))

(fn player.move [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      (let [action col.other.action]
        (if (not player.alive)
            (void)
            (= :death action)
            (player.kill)
            (= :ground action)
            (player.handle-ground col)
            (= :bounce action)
            (player.bounce col)
            (= :conveyor action)
            (player.conveyor col)
            (= :button action)
            (player.button col))))
    ; we fell off a wall
    (when (and (= len 0) player.on-wall)
      (set player.animation fall)
      (set player.on-wall false)
      (set player.gravity 50)
      (set player.weight WEIGHT)
      (set player.speed 0)
      (set player.direction (util.opposite player.direction)))
    (when player.alive 
      (let [right-edge (+ (- (* tilemap.width tile-width) tile-width) 4)]
        (if (> player.x right-edge)
            (util.update-object player 4 player.y)
            (< player.x 4)
            (util.update-object player (- right-edge tile-width) player.y)
            (do 
              (set player.x actualX)
              (set player.y actualY)))))))

(fn player.update [dt]
  (when player.alive (let [x (player.direction player.x (* player.speed dt))
        y (+ player.y (* player.gravity dt))]
    (if (and player.jumping (love.keyboard.isDown "space") (< player.jump-timer 0.3)) 
      (do 
        (set player.gravity (+ player.gravity (* 150 dt)))
        (set player.jump-timer (+ player.jump-timer dt)))
      (do 
        (if (< player.gravity 200) (set player.gravity (+ player.gravity (* player.weight dt))))
        (set player.jumping false)
        (set player.jump-timer 0)))
    (player.move x y)))
  (player.animation:update dt))

(fn player.draw []
  (let [right (= player.direction util.add)
        dead (not player.alive)
        orientation (if right 1 -1)
        ox (if right (if dead 4 0) (if dead 12 6))]
    (player.animation:draw player.image (math.floor player.x) (math.floor (+ player.y 0)) 0 orientation 1 ox (if dead 4 0))))

player
