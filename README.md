# Raytracer
Raytracer made in processing for CS4450

The framework for the project was provided by Professor Markus Eger [(@yawgmoth)](https://github.com/yawgmoth), and can be found [here](https://github.com/yawgmoth/CS4450-framework)

## Modifications made
### Primitives.pde
Add support for spheres, planes, triangles, and quadrics: cylinders, cones, parabaloids, 1-sheet hyperboloids, and 2-sheet hyperboloids.
The quadric shapes can be either finite or infinite in height.
Shapes return a list of ray hits, which provide the location of the hit, the distance to the hit, the normal vector of the hit, as well as texture coordinates for the hit.

### CSG.pde
Implements union, intersection, and difference operations to allow for combinations of shapes to build a more complex shape.

### Lighting.pde
Implement the phong lighting model to get more complex lighting. Also allows objects to have different material properties.
Implement shadows.

### Transforms.pde
Allows for translation and rotation of shapes.
Since quadrics are all centered vertically around origin for ease of calculating ray hits, these operations allow them to bne placed anywhere in the scene.
Order of operations is rotate around z-axis, rotate x-axis, rotate y-axis, then translation.

### raytracer.pde
Add support for camera to have any arbitrary viewing angle.
Allow for arbitrary field of view.
Implement reflections to allow shapes to range from opaque to transparent.
