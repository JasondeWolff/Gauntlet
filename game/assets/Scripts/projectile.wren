import "core" for Time
import "math" for Vec3
import "physics" for Physics, CollisionFlags
import "framework" for GameObject, Transform, MeshFilter, MeshRenderer

class Projectile is GameObject {
    construct new(init) {
        super(init)

        _trx = addComponent(Transform)
        _mf = addComponent(MeshFilter)
        _mr = addComponent(MeshRenderer)

        _target = null
        _direction = Vec3.new(0, 0, 0)
        _speed = 0
        _lifetime = 2
    }

    transform { _trx }
    meshFilter { _mf }
    meshRenderer { _mr }

    target { _target }
    target=(v) { _target = v }

    direction { _direction }
    direction=(v) { _direction = v }

    speed { _speed }
    speed=(v) { _speed = v }

    lifetime { _lifetime }
    lifetime=(v) { _lifetime = v }

    start() {}

    update() {
        transform.position = transform.position + direction * speed * Time.deltaTime

        var origin = transform.position
        var hit = Physics.sphereCast(origin, direction, 0.1, 0.5, CollisionFlags.default, CollisionFlags.all)
        if (hit.hasHit) {
            if (hit.gameObject is target) {
                hit.gameObject.getHit(direction, 10)
            }
            destroy()
        }

        lifetime = lifetime - Time.deltaTime
        if (lifetime <= 0) {
            destroy()
        }
    }
}

GameObject.register(Projectile)