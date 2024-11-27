return {
    type = "animation_editor",
    data = {
        metadata = {
            layers = {
            },
            fps = 60,
            settings = {
                font_size = 30,
            },
            gizmo_steps = {
            },
            gui_path = "/examples/boids/boid/boid.go",
        },
        animations = {
            {
                animation_id = "default",
                duration = 1,
                animation_keys = {
                    {
                        duration = 0.37,
                        property_id = "size_x",
                        end_value = 329,
                        node_id = "#sprite",
                        start_value = 129,
                        key_type = "tween",
                        easing = "outsine",
                    },
                    {
                        duration = 0.37,
                        property_id = "size_y",
                        end_value = 499.876,
                        node_id = "#sprite",
                        start_value = 196,
                        key_type = "tween",
                        easing = "outsine",
                    },
                    {
                        start_time = 0.37,
                        duration = 0.63,
                        property_id = "size_x",
                        end_value = 129,
                        node_id = "#sprite",
                        start_value = 329,
                        key_type = "tween",
                        easing = "outsine",
                    },
                    {
                        start_time = 0.37,
                        duration = 0.63,
                        property_id = "size_y",
                        end_value = 196,
                        node_id = "#sprite",
                        start_value = 499.876,
                        key_type = "tween",
                        easing = "outsine",
                    },
                },
            },
        },
        nodes = {
        },
    },
    format = "json",
    version = 1,
}