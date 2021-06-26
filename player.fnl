(local util (require :util))
(local anim8 (require :lib/anim8))
(local audio (require :audio))

(local characterImage (love.graphics.newImage "assets/astro.png"))
(local characterGrid (anim8.newGrid 8 8 120 8))
(local walk (anim8.newAnimation (characterGrid "2-7" 1) 0.1))
(local jump (anim8.newAnimation (characterGrid 5 1) 1000000))
(local fall (anim8.newAnimation (characterGrid 9 1) 10000))
(local wall (anim8.newAnimation (characterGrid 11 1) 1000000))

(local explosionImage (love.graphics.newImage "assets/explosion2.png"))
(local explosionGrid (anim8.newGrid 16 16 256 16))
(local die (anim8.newAnimation (explosionGrid "6-16" 1) 0.1 "pauseAtEnd"))

(local SPEED 40)
(local WEIGHT 600)
(local JUMP_GRAVITY -80)
; speed      - horizontal speed
; direction  - a function that either adds or subtracts to the player's X position
; jumping    - whether the player is in the process of jumping (input)
; jumpTimer  - how long player has been holding jump
; hasJump    - whether the player can double jump
; onWall     - whether the player is hanging on a wall/
; onGround   - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; animation  - which animation to draw (walk, die, jump, etc)
; image      - the corresponding image for the animation
; alive      - whether the player is dead or alive
(local player {:x 16 :y (- (* GAME_HEIGHT TILE_WIDTH) 16) :speed SPEED :direction util.add :jumping false :jumpTimer 0
               :hasJump false :onWall false :onGround true :gravity 0 :weight WEIGHT
               :animation walk :image characterImage :alive true})

(fn player.kill []
  (audio.play :die)
  (set player.image explosionImage)
  (set player.animation die)
  (set player.alive false))

(fn player.normalJump []
  (set player.jumping true)
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.hasJump true))

(fn player.wallJump []
  (if (not player.onWall)
      (set player.hasJump false)
      (set player.hasJump true))
  (set player.jumping true)
  (set player.direction (util.opposite player.direction))
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.onWall false)
  (set player.weight WEIGHT)
  (set player.speed SPEED))

(fn player.jump []
  (set player.animation jump)
  (if player.onWall
      (do (audio.play :jump) (player.wallJump))
      player.hasJump
      (do (set player.jet (audio.play :jet {:loop true})) (player.wallJump))
      player.onGround
      (do (audio.play :jump) (player.normalJump))))

(fn player.handleGround [col]
  (if (or (= col.normal.x -1) (= col.normal.x 1))
      (do 
        (set player.onWall true)
        (set player.animation wall)
        (set player.weight 1)
        (set player.gravity 10)
        (set player.hasJump true))
        ; we hit the ground
      (= col.normal.y -1)
      (do 
        (set player.gravity 0)
        (set player.onGround true)
        (set player.speed SPEED)
        (when (not player.onWall) (set player.animation walk))
        (set player.hasJump false))
      ; we hit a ceiling
      (= col.normal.y 1)
      (do 
        (set player.gravity 25))))

(fn player.conveyor [col]
  (player.handleGround col)
  (if (= col.normal.x -1) 
      (set player.gravity (col.other.direction 0 20))
      (= col.normal.x 1)
      (set player.gravity (col.other.direction 0 -20))))

(fn player.bounce [col]
  (set player.speed SPEED)
  (set player.animation jump)
  (if (or (= col.normal.y 1) (= col.normal.y -1))
      (player.handleGround col)
      player.onWall
      (do
        (audio.play :bounce)
        (player.wallJump) 
        (set player.gravity -100))
      (do 
        (audio.play :bounce)
        (set player.direction col.other.direction)
        (player.normalJump)
        (set player.gravity -100))))

(fn doNothing [] (+ 0 0))

(fn player.move [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      (if (not player.alive)
          (doNothing)
          col.other.death
          (player.kill)
          col.other.ground 
          (player.handleGround col)
          col.other.bounce
          (player.bounce col)
          col.other.conveyor
          (player.conveyor col)))
    ; we fell off a wall
    (when (and (= len 0) player.onWall)
      (set player.animation fall)
      (set player.onWall false)
      (set player.gravity 50)
      (set player.weight WEIGHT)
      (set player.speed 0)
      (set player.direction (util.opposite player.direction)))
    (when player.alive 
      (if (> player.x (+ WIDTH 4))
          (util.updateObject player 4 player.y)
          (< player.x 4)
          (util.updateObject player (+ WIDTH 4) player.y)
          (do 
            (set player.x actualX)
            (set player.y actualY))))))

(fn player.update [dt]
  (when player.alive (let [x (player.direction player.x (* player.speed dt))
        y (+ player.y (* player.gravity dt))]
    (if (and player.jumping (love.keyboard.isDown "space") (< player.jumpTimer 0.3)) 
      (do 
        (set player.gravity (+ player.gravity (* 150 dt)))
        (set player.jumpTimer (+ player.jumpTimer dt)))
      (do 
        (if (< player.gravity 200) (set player.gravity (+ player.gravity (* player.weight dt))))
        (when player.jet (player.jet:stop))
        (set player.jumping false)
        (set player.jumpTimer 0)))
    (player.move x y)))
  (player.animation:update dt))

(fn player.draw []
  (let [right (= player.direction util.add)
        dead (not player.alive)
        orientation (if right 1 -1)
        ox (if right (if dead 4 0) (if dead 12 6))]
    (player.animation:draw player.image (math.floor player.x) (math.floor (- player.y 1)) 0 orientation 1 ox (if dead 4 0))))

player
