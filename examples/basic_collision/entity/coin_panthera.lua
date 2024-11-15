return {
    data = {
        nodes = {
        },
        metadata = {
            gui_path = "/examples/basic_collision/entity/coin.go",
            fps = 60,
            layers = {
            },
            gizmo_steps = {
            },
            settings = {
                font_size = 30,
            },
        },
        animations = {
            {
                duration = 1,
                animation_id = "default",
                animation_keys = {
                },
            },
            {
                duration = 0.5,
                animation_id = "on_remove",
                animation_keys = {
                    {
                        start_value = 1,
                        easing = "outsine",
                        key_type = "tween",
                        node_id = "#sprite",
                        duration = 0.5,
                        property_id = "color_a",
                    },
                },
            },
        },
    },
    version = 1,
    format = "json",
    type = "animation_editor",
}