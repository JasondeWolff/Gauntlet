import "framework" for GameObject, Transform, MeshFilter, MeshRenderer, Collider, RigidBody

class Item is GameObject {
    construct new(init) {
        super(init)

        _trx = addComponent(Transform)
        _mf = addComponent(MeshFilter)
        _mr = addComponent(MeshRenderer)
        //_coll = addComponent(Collider)
        //_rb = addComponent(RigidBody)
    }

    // Components
    transform { _trx }
    meshFilter { _mf }
    meshRenderer { _mr }
    //collider { _coll }
    //rigidBody { _rb }

    start() {}
    update() {}
}

GameObject.register(Item)