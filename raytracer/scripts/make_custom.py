scene = """{
	"scene": {
		"type": "union",
        "children": [
            {
            	"type": "plane",
                "scale": 2,
                "center": {"z": -4},
                "normal": {"z": 1},
                "material": {"type": "textured", "reflectiveness": 0.6}
            },
            {
            	"type": "moverotation",
            	"rotation" : {"z": %d, "x": 0, "y": 0},
            	"movement": {"y": 10},
                "child": {
                    	"type": "sphere",
                     	"radius": 2,
                     	"center": {"z": 0, "y": 0},
                     	"material": {"type": "textured", "texture": "test2.png"}
                }
            },
            {
            	"type": "plane",
                "center": {"x": 0, "y": 10, "z": -20},
                "normal": {"x": 1, "y": -0.5, "z": 0.3},
                "material": {"reflectiveness": 1, "color": {"color": 168}}
            },
            {
            	"type": "plane",
                "center": {"x": 0, "y": 10, "z": -20},
                "normal": {"x": -1, "y": -0.5, "z": 0.3},
                "material": {"reflectiveness": 1, "color": {"color": 168}}
            }
        ]
    },
   "reflections": 100,
   "lighting": {"type": "phong", "ambient": {"color": 128}, "shadows": true,
                "lights": [{"position": {"x": -50, "y": -700, "z": 30}, "color": {"r": 255, "g": 0, "b": 0}},
                           {"position": {"x": 50, "y": -700, "z": 30}, "color": {"r": 0, "g": 255, "b": 0}},
                           {"position": {"x": 0, "y": -700, "z": -60}, "color": {"r": 0, "g": 0, "b": 255}}]}
}"""

for i in range(360):
    f = open("C:/Users/Gavin/Documents/School/CS 4450 - Computer Graphics/raytracer/data/tests/custom/animation1/scene%03d.json" % i, "w")
    f.write(scene % i)
    f.close()
