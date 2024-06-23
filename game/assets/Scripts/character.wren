import "core" for Time
import "math" for Vec3
import "framework" for GameObject, Transform, MeshFilter, MeshRenderer, Animator, CharacterController, Attributes

class Character is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _mf = addComponent(MeshFilter)
        _mr = addComponent(MeshRenderer)
        _anim = addComponent(Animator)
        _cc = addComponent(CharacterController)
        _att = addComponent(Attributes)

        _health = 100
        _move = Vec3.new(0, 0, 0)
        _moveSpeed = 1
    }

    // Components
    transform { _trx }
    meshFilter { _mf }
    meshRenderer { _mr }
    animator { _anim }
    controller { _cc }
    attributes { _att }

    health { _health }
    health=(v) { _health = v }

    state { _state }
    state=(v) {
        onStateChange(_state, v)
        _state = v
    }

    move { _move }
    move=(v) { _move = v }

    moveSpeed { _moveSpeed }
    moveSpeed=(v) { _moveSpeed = v }

    onStateChange(oldState, newState) {}

    takeDamage(dmg) {
        health = health - dmg
        if (health < 0) {
            health = 0
        }
    }

    getHit(dir, dmg) {
        takeDamage(dmg)
        return true
    }
    
    start() {}
    update() {
        controller.moveVector = move * moveSpeed * Time.deltaTime
    }
}