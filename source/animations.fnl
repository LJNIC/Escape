(local animations {:list (sequence)})

(fn animations.add [x y animation image dir speed]
  (let [dir   (or dir (vec2 0 0))
        pos   (vec2 x y)
        speed (or speed 0)]
    (animations.list:insert {: pos : animation : image : dir : speed})))

(fn animations.update [dt]
  (for [i (# animations.list) 1 -1]
    (let [animation (. animations.list i)
          new-pos (+ animation.pos (* animation.dir (* dt animation.speed)))]
      (animation.animation:update dt)
      (set animation.pos new-pos)
      (when (= animation.animation.status "paused") 
        (table.remove animations.list i)))))

(fn animations.draw []
  (each [_ animation (ipairs animations.list)]
    (let [{: image : pos : animation} animation]
      (animation:draw image pos.x pos.y))))

animations
