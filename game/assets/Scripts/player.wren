import "core" for Time
import "device" for Input, Key, MouseButton
import "math" for Math, Vec3, Quat, Mat4
import "physics" for Physics, CollisionFlags
import "graphics" for Graphics
import "framework" for GameObject, Transform, MeshFilter, MeshRenderer, Animator, CharacterController, Attributes
import "character" for Character
import "camera" for ThirdPersonCamera
import "enemy" for Enemy

class PlayerState {
    static idle { 0 }
    static movement { 1 }
    static block { 2 }
    static attack { 3 }
    static hit { 4 }
    static dead { 5 }
}

class Player is Character {
    construct new(data) {
        super(data)
    }

    idle_anim { 0 }
    melee_2h_idle_anim { 1 }
    running_anim { 2 }
    strafe_left_anim { 3 }
    strafe_right_anim { 4 }
    walking_backwards_anim { 5 }
    attack_block_anim { 6 }
    attack_chop_anim { 7 }
    attack_slice_dia_anim { 8 }
    attack_slice_hor_anim { 9 }
    attack_stab_anim { 10 }
    blocking_anim { 11 }
    block_hit_anim { 12 }
    hit_anim { 13 }
    death_anim { 14 }

    onStateChange(oldState, newState) {
        super.onStateChange(oldState, newState)

        if (newState == PlayerState.attack) {
            _timer = (animator.duration(attack_chop_anim + _combo) / animator.speed) - 0.2
        }
    }

    getHit(dir, dmg) {
        if (state == PlayerState.block) {
            var fwd = transform.rotation * Vec3.new(0, 0, 1)
            var dot = Vec3.dot(dir, fwd)
            if (dot < 0) {
                _blocked = true
                return false
            }
        }

        if (state != PlayerState.dead && state != PlayerState.hit) {
            super.getHit(dir, dmg)
            controller.applyImpulse(Vec3.new(dir.x, 0, dir.z) * 10)
            
            if (health > 0) {
                state = PlayerState.hit

            } else {
                state = PlayerState.dead
            }

            return true
        }
        return false
    }

    start() {
        _cam = GameObject.create(ThirdPersonCamera)
        _cam.target = this

        _axe1h = GameObject.load("[assets]/GameObjects/Characters/Axe1H.gameobject")
        _shield = GameObject.load("[assets]/GameObjects/Characters/ShieldRound.gameobject")

        animator.current = idle_anim
        state = PlayerState.idle
        
        move = Vec3.new(0, 0, 0)
        moveSpeed = 5

        // Input
        _blocking = false
        _blocked = false
        _attacked = false
        _combo = 0
        _timer = 0
    }

    update_input() {
        var mz = 0
        var mx = 0
        if (Input.getKey(Key.w)) {
            mz = mz + 1
        } else if (Input.getKey(Key.s)) {
            mz = mz - 1
        }
        if (Input.getKey(Key.a)) {
            mx = mx + 1
        } else if (Input.getKey(Key.d)) {
            mx = mx - 1
        }
        move = Vec3.new(mx, 0, mz)

        _blocking = Input.getMouseButton(MouseButton.right)

        _attacked = false
        if (Input.getMouseButtonOnce(MouseButton.left)) {
            _attacked = true
        }
    }
    
    update_idle() {
        animator.speed = 1
        animator.looping = true
        animator.current = idle_anim

        if (_blocking) {
            state = PlayerState.block
            
        } else if (_attacked) {
            state = PlayerState.attack

        } else if (move.sqrMagnitude > 0) {
            state = PlayerState.movement
        }
    }

    update_movement() {
        if (move.sqrMagnitude > 0) {
            transform.rotation = Quat.euler(0, _cam.angles.y, 0)

            move = (transform.rotation * move).normalized
            var fwd = transform.rotation * Vec3.new(0, 0, 1)
            var angle = (move.z * fwd.x - move.x * fwd.z).atan(move.z * fwd.z + move.x * fwd.x)
            angle = angle * 180 / Num.pi
    
            var anim = running_anim

            var threshold = 20
            if (angle > -45 + threshold && angle <= 45 - threshold) {
                anim = running_anim

            } else if (angle > 45 + threshold && angle <= 135 - threshold) {
                anim = strafe_right_anim

            } else if (angle > 135 + threshold || angle <= -135 - threshold) {
                anim = walking_backwards_anim

            } else if (angle > -135 + threshold && angle <= -45 - threshold) {
                anim = strafe_left_anim
            }

            animator.speed = 1.2
            animator.looping = true
            animator.current = anim

        } else {
            state = PlayerState.idle
        }

        if (_blocking) {
            state = PlayerState.block

        } else if (_attacked) {
            state = PlayerState.attack
        }
    }

    update_attack() {
        transform.rotation = Quat.euler(0, _cam.angles.y, 0)
        move = Vec3.new(0, 0, 0)

        animator.speed = 2
        animator.looping = false
        animator.current = attack_chop_anim + _combo

        var pos = _axe1h.transform.position
        var fwd = _axe1h.transform.rotation * Vec3.new(0, 1, 0)
        var origin = pos + fwd * 0.5
        var hit = Physics.sphereCast(origin, fwd, 0.8, 0.2, CollisionFlags.default, CollisionFlags.character)
        if (hit.hasHit) {
            if (hit.gameObject is Enemy) {
                hit.gameObject.getHit(-hit.normal, 10)
            }
        }

        if (animator.hasEnded) {
            state = PlayerState.idle
            _combo = 0
        }

        _timer = _timer - Time.deltaTime
        if (_timer <= 0 && _attacked) {
            _combo = (_combo + 1) % 4
            state = PlayerState.attack
        }
    }

    update_block() {
        transform.rotation = Quat.euler(0, _cam.angles.y, 0)
        move = Vec3.new(0, 0, 0)

        if (_blocked) {
            animator.speed = 1
            animator.looping = false
            animator.current = block_hit_anim
            if (animator.hasEnded) {
                _blocked = false
            }

        } else {
            animator.speed = 1
            animator.looping = true
            animator.current = blocking_anim
        }

        if (!_blocking) {
            _blocked = false
            state = PlayerState.idle
        }
    }

    update_hit() {
        move = Vec3.new(0, 0, 0)
        animator.looping = false
        animator.current = hit_anim
        if (animator.hasEnded) {
            state = PlayerState.idle
        }
    }

    update_dead() {
        move = Vec3.new(0, 0, 0)
        animator.speed = 1
        animator.looping = false
        animator.current = death_anim
    }

    update() {
        super.update()

        update_input()

        if (state == PlayerState.idle) {
            update_idle()

        } else if (state == PlayerState.movement) {
            update_movement()

        } else if (state == PlayerState.attack) {
            update_attack()

        } else if (state == PlayerState.block) {
            update_block()

        } else if (state == PlayerState.hit) {
            update_hit()

        } else if (state == PlayerState.dead) {
            update_dead()
        }

        var offset = Mat4.trs(Vec3.new(0, 0, 0), Quat.euler(0, 180, 0), Vec3.new(1, 1, 1))
        _axe1h.transform.matrix = transform.matrix * animator.getBoneMatrix("1H_Axe") * offset
        _shield.transform.matrix = transform.matrix * animator.getBoneMatrix("Barbarian_Round_Shield")
    }
}

GameObject.register(Player)