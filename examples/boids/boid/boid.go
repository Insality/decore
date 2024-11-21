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
    value: "32.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "size_y"
    value: "49.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"boid\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
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
    x: 0.25
    y: 0.25
  }
}
