(local timers {:timers {}})

(fn timers.add [duration on-finish]
  (let [new-timer (timer duration nil on-finish)]
    (table.insert timers.timers new-timer)))

(fn timers.update [dt]
  (when (> (# timers.timers) 0)
    (for [i (# timers.timers) 1 -1]
      (let [timer (. timers.timers i)]
        (timer:update dt)
        (if (timer:expired) (table.remove timers.timers i))))))

timers
