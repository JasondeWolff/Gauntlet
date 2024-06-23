import "random" for Random
import "core" for Time
import "math" for Math, Vec3
import "framework" for GameObject, Transform, MeshFilter, MeshRenderer, Collider, RigidBody, Light

class StaticModel is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _mf = addComponent(MeshFilter)
        _mr = addComponent(MeshRenderer)
        _coll = addComponent(Collider)
    }

    // Components
    transform { _trx }
    meshFilter { _mf }
    meshRenderer { _mr }
    collider { _coll }

    start() {}
    update() {}
}

class InvisibleCollider is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _coll = addComponent(Collider)
    }

    // Components
    transform { _trx }
    collider { _coll }

    start() {}
    update() {}
}

class LightSource is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _light = addComponent(Light)
    }

    // Components
    transform { _trx }
    light { _light }

    start() {
        __rng = Random.new()

        _intensity = light.intensity
        _color = light.color
        _min = _intensity - 0.5
        _max = _intensity + 0.5
        _flickerSpeed = 5
        _timer = 0
    }

    update() {
        _timer = _timer - Time.deltaTime
        if (_timer <= 0) {
            _timer = __rng.float(0.1, 0.3)
            _intensity = __rng.float(_min, _max)

            var color = __rng.int(0, 2)
            if (color == 0) {
                _color = Vec3.new(1.0, 0.4, 0.0)
            } else if (color == 1) {
                _color = Vec3.new(1.0, 0.3, 0.0)
            } else {
                _color = Vec3.new(1.0, 0.2, 0.0)
            }
        }
        light.intensity = Math.lerp(light.intensity, _intensity, _flickerSpeed * Time.deltaTime)
        light.color = Vec3.lerp(light.color, _color, _flickerSpeed * Time.deltaTime)
    }
}

class DynamicObject is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _mf = addComponent(MeshFilter)
        _mr = addComponent(MeshRenderer)
        _coll = addComponent(Collider)
        _rb = addComponent(RigidBody)
    }

    // Components
    transform { _trx }
    meshFilter { _mf }
    meshRenderer { _mr }
    collider { _coll }
    rigidBody { _rb }

    start() {}
    update() {}
}

GameObject.register(StaticModel)
GameObject.register(InvisibleCollider)
GameObject.register(LightSource)
GameObject.register(DynamicObject)