import "core" for Time
import "math" for Vec3
import "physics" for Physics, CollisionFlags
import "graphics" for Graphics
import "character" for Character

class EnemyState {
    static idle { 0 }
    static roaming { 1 }
    static seeking { 2 }
    static fleeing { 3 }
    static attack { 4 }
    static hit { 5 }
    static dead { 6 }
    static cheer { 7 }
}

class Enemy is Character {
    construct new(data) {
        super(data)
    }

    target { _target }
    target=(v) { _target = v }

    targetDistance { _targetDistance }

    seekDistance { _seekDistance }
    seekDistance=(v) { _seekDistance = v }

    attackDistance { _attackDistance }
    attackDistance=(v) { _attackDistance = v }

    onStateChange(oldState, newState) {
        super.onStateChange(oldState, newState)
    }

    takeDamage(dmg) {
        super.takeDamage(dmg)
        if (health < 0) {
            state = EnemyState.dead
        }
    }

    getHit(dir, dmg) {
        if (state != EnemyState.dead && state != EnemyState.hit) {
            super.getHit(dir, dmg)
            return true
        }
        return false
    }

    start() {
        super.start()

        state = EnemyState.idle
        health = 100
        seekDistance = 10
        attackDistance = 2

        _targetDistance = 0

        move = Vec3.new(0, 0, 0)
        moveSpeed = 1
    }

    update_idle() {}

    update_roaming() {
        var origin = transform.position
        var hits = Physics.sphereCastAll(origin, Vec3.new(0, 1, 0), 1, seekDistance, CollisionFlags.default, CollisionFlags.character)
        for (hit in hits) {
            if (hit.gameObject is Player) {
                target = hit.gameObject
                state = EnemyState.seeking
            }
        }
    }

    update_seeking() {
        if (targetDistance > seekDistance) {
            target = null
            state = EnemyState.roaming

        } else if (targetDistance > attackDistance - 0.5 && targetDistance < attackDistance + 0.5) {
            state = EnemyState.attack

        } else if (targetDistance < attackDistance - 0.5) {
            state = EnemyState.fleeing
        }

        if (target != null && target.state == PlayerState.dead) {
            state = EnemyState.cheer
        }
    }

    update_fleeing() {
        if (targetDistance > attackDistance + 0.5) {
            state = EnemyState.seeking
        }
    }

    update_attack() {}

    update_hit() {}

    update_dead() {}

    update_cheer() {}

    update() {
        super.update()

        if (target != null) {
            _targetDistance = (transform.position - target.transform.position).magnitude
        }

        if (state == EnemyState.idle) {
            update_idle()

        } else if (state == EnemyState.roaming) {
            update_roaming()

        } else if (state == EnemyState.seeking) {
            update_seeking()

        } else if (state == EnemyState.fleeing) {
            update_fleeing()

        } else if (state == EnemyState.attack) {
            update_attack()

        } else if (state == EnemyState.hit) {
            update_hit()

        } else if (state == EnemyState.dead) {
            update_dead()

        } else if (state == EnemyState.cheer) {
            update_cheer()
        }
    }
}

import "player" for Player, PlayerState