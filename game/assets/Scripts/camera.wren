import "device" for Input
import "math" for Math, Vec3, Quat
import "physics" for Physics, CollisionFlags
import "framework" for GameObject, Transform, Camera, AudioListener

class ThirdPersonCamera is GameObject {
    construct new(data) {
        super(data)

        _trx = addComponent(Transform)
        _cam = addComponent(Camera)
        _al = addComponent(AudioListener)
    }

    // Components
    transform { _trx }
    camera { _cam }
    audioListener { _al }

    // Variables
    target { _target }
    target=(x) { _target = x }
    angles { _angles }

    start() {
        _angles = Vec3.new(0, 0, 0)
        _mx = Input.getMouseX()
        _my = Input.getMouseY()

        _distance = 5
        _offset = Vec3.new(0, 2, 0)

        if (target) {
            _targetPos = target.transform.position.copy
        }
    }

    update() {
        if (target) {
            var dx = _mx - Input.getMouseX()
            var dy = _my - Input.getMouseY()
            _angles = _angles + Vec3.new(-dy * 0.1, dx * 0.1, 0)
            _mx = Input.getMouseX()
            _my = Input.getMouseY()
            
            if (_angles.x < -89) _angles.x = -89
            if (_angles.x > 89) _angles.x = 89
            transform.rotation = Quat.euler(_angles.x, _angles.y, _angles.z)

            var ypos = _targetPos.y
            _targetPos = target.transform.position.copy
            _targetPos.y = Math.lerp(ypos, _targetPos.y, 0.1)

            var targetPos = _targetPos + _offset
            var fwd = transform.rotation * Vec3.new(0, 0, 1)
            var hit = Physics.rayCast(targetPos, -fwd, _distance, CollisionFlags.default, CollisionFlags.all ^ CollisionFlags.character)
            if (hit.hasHit) {
                transform.position = hit.point + fwd * 0.5
            } else {
                transform.position = targetPos + transform.rotation * Vec3.back * _distance
            }
        }
    }
}

GameObject.register(ThirdPersonCamera)