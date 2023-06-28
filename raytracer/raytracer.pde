String a = "custom";

String input =  "data/tests/" + a + "/test%d.json";
String output = "data/tests/" + a + "/test%d.png";
int repeat = 5;

int iteration = 1;

// If there is a procedural material in the scene,
// loop will automatically be turned on if this variable is set
boolean doAutoloop = true;

// Animation demo:
/*String input = "data/tests/custom/animation1/scene%03d.json";
String output = "data/tests/custom/animation1/frame%03d.png";
int repeat = 361;*/



RayTracer rt;

void setup() {
  size(640, 640);
  noLoop();
  if (repeat == 0)
      rt = new RayTracer(loadScene(input));  
  
}

void draw () {
  background(255);
  if (repeat == 0)
  {
    PImage out = null;
    if (!output.equals(""))
    {
       out = createImage(width, height, RGB);
       out.loadPixels();
    }
    for (int i=0; i < width; i++)
    {
      for(int j=0; j< height; ++j)
      {
        color c = rt.getColor(i,j);
        set(i,j,c);
        if (out != null)
           out.pixels[j*width + i] = c;
      }
    }
    
    // This may be useful for debugging:
    // only draw a 3x3 grid of pixels, starting at (315,315)
    // comment out the full loop above, and use this
    // to find issues in a particular region of an image, if necessary
    /*for (int i = 0; i< 3; ++i)
    {
      for (int j = 0; j< 3; ++j)
         set(315+i,315+j, rt.getColor(315+i,315+j));
    }*/
    
    if (out != null)
    {
       out.updatePixels();
       out.save(output);
    }
    
  }
  else
  {
     // With this you can create an animation!
     // For a demo, try:
     //    input = "data/tests/milestone3/animation1/scene%03d.json"
     //    output = "data/tests/milestone3/animation1/frame%03d.png"
     //    repeat = 100
     // This will insert 0, 1, 2, ... into the input and output file names
     // You can then turn the frames into an actual video file with e.g. ffmpeg:
     //    ffmpeg -i frame%03d.png -vcodec libx264 -pix_fmt yuv420p animation.mp4
     String inputi;
     String outputi;
     for (; iteration < repeat; ++iteration)
     {
        inputi = String.format(input, iteration);
        outputi = String.format(output, iteration);
        if (rt == null)
        {
            rt = new RayTracer(loadScene(inputi));
        }
        else
        {
            rt.setScene(loadScene(inputi));
        }
        PImage out = createImage(width, height, RGB);
        out.loadPixels();
        for (int i=0; i < width; i++)
        {
          for(int j=0; j< height; ++j)
          {
            color c = rt.getColor(i,j);
            out.pixels[j*width + i] = c;
            if (iteration == repeat - 1)
               set(i,j,c);
          }
        }
        out.updatePixels();
        out.save(outputi);
     }
  }
  updatePixels();


}

class Ray
{
     Ray(PVector origin, PVector direction)
     {
        this.origin = origin;
        this.direction = direction;
     }
     PVector origin;
     PVector direction;
}

// TODO: Start in this class!
class RayTracer
{
    Scene scene;  
    
    RayTracer(Scene scene)
    {
      setScene(scene);
    }
    
    void setScene(Scene scene)
    {
       this.scene = scene;
    }
    
    color getColor(int x, int y)
    {
      float w = width;
      float h = height;
      
      //u% of w/2 and v% of -(h/2)
      float u = x * 1.0 / w - 0.5;
      float v = -(y * 1.0 / h - 0.5);
      
      //calculate vectors needed for arbitrary camera angle
      PVector forward = scene.view.normalize();
      PVector left = new PVector(0, 0, 1).cross(forward).normalize();
      PVector up = forward.cross(left).normalize();
      
      //PVector origin = scene.camera;
      //PVector direction = new PVector(u*w, w/2, v*h).normalize();
      //use direction vectors to orient camera angle analogously to original way commented above
      PVector direction = PVector.add(PVector.mult(left, -u*w*tan(scene.fov/2)), PVector.add(PVector.mult(forward, w/2), PVector.mult(up, v*h*tan(scene.fov/2)))).normalize();
      Ray ray = new Ray(scene.camera, direction);
      
      ArrayList<RayHit> hits = scene.root.intersect(ray);
      
      if(hits.size() > 0 && hits.get(0).entry)
      {
        //color base = scene.lighting.getColor(hits.get(0), scene, ray.origin);
        
        //if material reflective, shoot recursive rays to get reflection color
        if(hits.get(0).material.properties.reflectiveness > 0) {
          color base = scene.lighting.getColor(hits.get(0), scene, ray.origin);
          color reflect = shootRay(ray, hits.get(0), scene.reflections);
          
          //return the interpolation of the hit color and the reflected color
          return lerpColor(base, reflect, hits.get(0).material.properties.reflectiveness);
        }
        
        return scene.lighting.getColor(hits.get(0), scene, ray.origin);
      }
      
      //this will be the fallback case
      return scene.background;
    }
    
    color shootRay(Ray ray, RayHit hit, int reflections) {
      //return most recent reflected color when reach max reflections
      if(reflections == 0) {
        return scene.lighting.getColor(hit, scene, ray.origin);
      }
      
      //calculate reflected ray and get ray hits
      PVector toViewer = PVector.mult(ray.direction, -1).normalize();
      PVector r = PVector.sub(PVector.mult(hit.normal, PVector.dot(hit.normal, toViewer) * 2), toViewer).normalize();
      Ray reflect = new Ray(PVector.add(hit.location, PVector.mult(r, EPS)), r);
      ArrayList<RayHit> hits = scene.root.intersect(reflect);
      
      if(hits.size() > 0 && hits.get(0).entry) {
        //not reflective, return hit color
        if(hits.get(0).material.properties.reflectiveness == 0) {
          return scene.lighting.getColor(hits.get(0), scene, reflect.origin);
        }
        //perfect mirror, return only reflected color
        else if(hits.get(0).material.properties.reflectiveness == 1) {
          return shootRay(reflect, hits.get(0), reflections - 1);
        }
        //semi-reflective, return interpolation of hit color and reflected color
        else {
          color hitColor = scene.lighting.getColor(hits.get(0), scene, reflect.origin);
          color reflectColor = shootRay(reflect, hits.get(0), reflections - 1);
          return lerpColor(hitColor, reflectColor, hits.get(0).material.properties.reflectiveness);
        }
      }
      
      //return background if reflection hits nothing
      return scene.background;
    }
}
