import "random" for Random
import "core" for Time
import "device" for Input, Key
import "math" for Math, Vec3, Quat, Mat4
import "framework" for GameObject, Transform, Camera, MeshFilter, MeshRenderer, Animator, CharacterController, Attributes
import "enemy" for Enemy, EnemyState
import "player" for Player

class Skeleton is Enemy {
    construct new(data) {
        super(data)
    }

    onStateChange(oldState, newState) {
        super.onStateChange(oldState, newState)
    }

    getHit(dir, dmg) {
        if (super.getHit(dir, dmg)) {
            controller.applyImpulse(Vec3.new(dir.x, 0, dir.z) * 10)
            
            if (health > 0) {
                _timer = 0.5
                state = EnemyState.hit

            } else {
                _timer = 5.0
                state = EnemyState.dead
            }

            return true
        }
        return false
    }

    start() {
        super.start()

        __rng = Random.new()
        _timer = __rng.float()

        move = Vec3.new(0, 0, 0)
        moveSpeed = 2.5
    }

    alignToMove() {
        if (move.sqrMagnitude > 0) {
            var angle = Math.degrees(move.x.atan(move.z))
            transform.rotation = Quat.euler(0, angle, 0)
        }
    }

    update_idle() {
        super.update_idle()

         _timer = _timer - Time.deltaTime
         if (_timer <= 0) {
            _timer = __rng.float()

            state = __rng.int(EnemyState.idle, EnemyState.roaming + 1)
            if (state == EnemyState.roaming) {
                move = Vec3.new(1 - __rng.float() * 2, 0, 1 - __rng.float() * 2).normalized
            }
         }
    }

    update_roaming() {
        super.update_roaming()

        _timer = _timer - Time.deltaTime
        if (_timer <= 0) {
            _timer = __rng.float()

            state = __rng.int(EnemyState.idle, EnemyState.roaming + 1)
            if (state == EnemyState.idle) {
                move = Vec3.new(0, 0, 0)

            } else if (state == EnemyState.roaming) {
                move = Vec3.new(1 - __rng.float() * 2, 0, 1 - __rng.float() * 2).normalized
            }
        }

        alignToMove()
    }

    update_seeking() {
        super.update_seeking()

        if (target != null) {
            move = (target.transform.position - transform.position).normalized
        }

        alignToMove()
    }

    update_fleeing() {
        super.update_fleeing()

        if (target != null) {
            move = (transform.position - target.transform.position).normalized
        }

        alignToMove()
    }

    update_attack() {
        super.update_attack()
        move = Vec3.new(0, 0, 0)
    }

    update_hit() {
        super.update_hit()
        move = Vec3.new(0, 0, 0)

        _timer = _timer - Time.deltaTime
        if (_timer <= 0) {
            state = EnemyState.seeking
        }
    }

    onDeath() {
        destroy()
    }

    update_dead() {
        super.update_dead()

        move = Vec3.new(0, 0, 0)
        //controller.width = 0.5
        //controller.height = 0.1

        _timer = _timer - Time.deltaTime
        if (_timer <= 0) {
            onDeath()
        }
    }

    update_cheer() {
        super.update_cheer()
        move = Vec3.new(0, 0, 0)
    }

    update() {
        super.update()
    }
}

class SkeletonMage is Skeleton {
    construct new(data) {
        super(data)
    }

    idle_anim { 0 }
    walking_anim { 1 }
    hit_anim { 2 }
    death_anim { 3 }
    shoot_anim { 4 }
    cheer_anim { 5 }

    onStateChange(oldState, newState) {
        super.onStateChange(oldState, newState)
    }

    start() {
        super.start()

        seekDistance = 10
        attackDistance = 5

        _hat = GameObject.load("[assets]/GameObjects/Skeletons/Hat.gameobject")
        _staff = GameObject.load("[assets]/GameObjects/Skeletons/Staff.gameobject")
    }

    update_idle() {
        super.update_idle()

        animator.looping = true
        animator.current = idle_anim
    }

    update_roaming() {
        super.update_roaming()

        animator.looping = true
        animator.current = walking_anim
    }

    update_seeking() {
        super.update_seeking()

        animator.looping = true
        animator.current = walking_anim
    }

    update_fleeing() {
        super.update_fleeing()

        animator.looping = true
        animator.current = walking_anim
    }

    update_attack() {
        super.update_attack()

        animator.looping = false
        animator.current = shoot_anim

        if (animator.hasEnded) {
            var spell = GameObject.load("[assets]/GameObjects/Skeletons/Spell.gameobject")
            spell.transform.position = transform.position + Vec3.new(0, 1, 0)
            spell.transform.scale = spell.transform.scale * 0.5
            spell.target = Player
            spell.direction = transform.rotation * Vec3.new(0, 0, 1)
            spell.speed = 20
            state = EnemyState.seeking
        }
    }

    update_hit() {
        super.update_hit()

        animator.looping = false
        animator.current = hit_anim
    }

    onDeath() {
        super.onDeath()

        _hat.destroy()
        _staff.destroy()
    }

    update_dead() {
        super.update_dead()

        animator.looping = false
        animator.current = death_anim
    }

    update_cheer() {
        super.update_cheer()

        animator.looping = true
        animator.current = cheer_anim
    }

    update() {
        super.update()

        _hat.transform.matrix = transform.matrix * animator.getBoneMatrix("head")

        var offset = Mat4.trs(Vec3.new(0, 0, 0), Quat.euler(0, 0, 0), Vec3.new(0.01, 0.01, 0.01))
        _staff.transform.matrix = transform.matrix * animator.getBoneMatrix("handslot.r") * offset
    }
}

class SkeletonMinion is Skeleton {
    construct new(data) {
        super(data)
    }
}

class SkeletonRogue is Skeleton {
    construct new(data) {
        super(data)
    }
}

class SkeletonWarrior is Skeleton {
    construct new(data) {
        super(data)
    }
}

GameObject.register(SkeletonMage)
GameObject.register(SkeletonMinion)
GameObject.register(SkeletonRogue)
GameObject.register(SkeletonWarrior)