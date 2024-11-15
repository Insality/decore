components {
  id: "score_counter"
  component: "/examples/basic_collision/entity/score_counter.gui"
}
components {
  id: "entity"
  component: "/decore/entity.script"
  properties {
    id: "prefab_id"
    value: "score_counter"
    type: PROPERTY_TYPE_HASH
  }
}
