components {
  id: "entity"
  component: "/decore/entity.script"
  properties {
    id: "prefab_id"
    value: "boid"
    type: PROPERTY_TYPE_HASH
  }
  properties {
    id: "size_x"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "size_y"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"boid\"\n"
  "material: \"/panthera/materials/sprite.material\"\n"
  "size {\n"
  "  x: 129.0\n"
  "  y: 196.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/examples/boids/boids.atlas\"\n"
  "}\n"
  ""
  rotation {
    z: -0.70710677
    w: 0.70710677
  }
  scale {
    x: 0.1
    y: 0.1
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"player\"\n"
  "mask: \"level\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 6.910569\n"
  "}\n"
  ""
}
