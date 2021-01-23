(local bump (require :lib/bump))
(local anim8 (require :lib/anim8))

(love.graphics.setDefaultFilter "nearest" "nearest")
(local (WIDTH HEIGHT) (love.graphics.getDimensions))
(local world (bump.newWorld 32))

(local characterImage (love.graphics.newImage "assets/astro.png"))
(local characterGrid (anim8.newGrid 8 8 120 8))
(local walk (anim8.newAnimation (characterGrid "2-7" 1) 0.1))

(local explosionImage (love.graphics.newImage "assets/explosion2.png"))
(local explosionGrid (anim8.newGrid 16 16 240 16))
(local die (anim8.newAnimation (explosionGrid "6-15" 1) 0.1))

(fn sub [a b] (- a b))
(fn add [a b] (+ a b))
(fn opposite [operation]
  (if (= operation add) sub add))

; speed      - horizontal speed
; jumping    - whether the player is in the process of jumping (input)
; jumpTimer - how long player has been holding jump
; hasJump   - whether the player can double jump
; onWall    - whether the player is hanging on a wall
; onGround  - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; direction  - moving left or right 
(local player {:x 64 :y (- HEIGHT 64) :width 32 :height 32 :speed 100 :direction add :jumping false
               :onWall false :onGround true :hasJump false :gravity 0 :weight 650
               :jumpTimer 0})

(fn createRect [x y width height] {: x : y : width : height})
(local ground 
  [(createRect 0 (- HEIGHT 32) WIDTH 32)
   (createRect 128 256 32 128)
   (createRect (- WIDTH 32) 0 32 HEIGHT)
   (createRect 0 0 32 HEIGHT)])

(fn add-object [object]
  (world:add object object.x object.y object.width object.height))

(add-object player)
(each [index rect (pairs ground)]
  (add-object rect))

(fn filter [item other] "slide")

(fn move-player [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      ; we hit a wall
      (if (or (= col.normal.x -1) (= col.normal.x 1))
          (do 
            (set player.onWall true)
            (set player.weight 1)
            (set player.gravity 10)
            (set player.hasJump true))
          ; we hit the ground
          (= col.normal.y -1)
          (do 
            (set player.gravity 0)
            (set player.onGround true)
            (set player.speed 100)
            (set player.hasJump false))
          (= col.normal.y 1)
          (do 
            (set player.gravity 50))))
    ; we fell off a wall
    (when (and (= len 0) player.onWall)
      (set player.onWall false)
      (set player.gravity 50)
      (set player.weight 650)
      (set player.speed 0))
    (set player.x actualX)
    (set player.y actualY)))

(fn normalJump []
  (set player.jumping true)
  (set player.gravity -150)
  (set player.onGround false)
  (set player.hasJump true))

(fn wallJump []
  (when (not player.onWall)
    (set player.hasJump false))
  (set player.jumping true)
  (set player.direction (opposite player.direction))
  (set player.gravity -150)
  (set player.onGround false)
  (set player.onWall false)
  (set player.weight 650)
  (set player.speed 100))

(fn jumpPlayer []
  (set player.animation die)
  (if (or player.onWall player.hasJump)
      (wallJump)
      player.onGround
      (normalJump)))

(fn love.update [dt]
  (let [x (player.direction player.x (* player.speed dt))
        y (+ player.y (* player.gravity dt))]
    (if (and player.jumping (love.keyboard.isDown "space") (< player.jumpTimer 0.3)) 
      (do 
        (set player.gravity (- player.gravity 2))
        (set player.jumpTimer (+ player.jumpTimer dt)))
      (do 
        (set player.gravity (+ player.gravity (* player.weight dt)))
        (set player.jumping false)
        (set player.jumpTimer 0)))
    (move-player x y))
  (walk:update dt))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (= "space" key)
      (jumpPlayer)))

(fn draw-ground [rect]
  (love.graphics.rectangle "line" rect.x rect.y rect.width rect.height))

(fn love.draw []
  (love.graphics.setLineWidth 2)
  (love.graphics.setColor 0.6 0.6 1)
  (each [index rect (pairs ground)]
    (draw-ground rect))
  (love.graphics.setColor 1 1 1)
  (let [orientation (if (= player.direction add) 4 -4)
        ox (if (= player.direction add) 0 8)]
   (walk:draw characterImage player.x player.y 0 orientation 4 ox)))
  