components {
  id: "entity"
  component: "/decore/entity.script"
  properties {
    id: "prefab_id"
    value: "player"
    type: PROPERTY_TYPE_HASH
  }
  properties {
    id: "size_x"
    value: "64.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "size_y"
    value: "64.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ui_circle_64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlases/game.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 80.0\n"
  "  y: 40.0\n"
  "}\n"
  "color {\n"
  "  x: 0.2\n"
  "  y: 0.2\n"
  "  z: 0.2\n"
  "}\n"
  "outline {\n"
  "  w: 0.0\n"
  "}\n"
  "shadow {\n"
  "  w: 0.0\n"
  "}\n"
  "pivot: PIVOT_W\n"
  "text: \"3.52\"\n"
  "font: \"/core/fonts/text.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: -25.0
    z: 0.1
  }
  scale {
    x: 0.7
    y: 0.7
  }
}
