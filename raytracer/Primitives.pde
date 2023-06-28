class Sphere implements SceneObject
{
    PVector center;
    float radius;
    Material material;
    
    Sphere(PVector center, float radius, Material material)
    {
       this.center = center;
       this.radius = radius;
       this.material = material;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        
        //find point of closest approach
        float tp = PVector.dot(PVector.sub(center, r.origin), r.direction);
        PVector p = PVector.add(r.origin, PVector.mult(r.direction, tp));
        float x = PVector.sub(p, center).mag();
        
        //if closest point within radius, hit
        if(x < radius)
        {
          //get both t values in order to easily loop over
          float t[] = new float[]{tp - sqrt(sq(radius) - sq(x)), tp + sqrt(sq(radius) - sq(x))};

          for(int i = 0; i < t.length; ++i) {
            //skip if behind camera
            if(t[i] < 0) {
              continue;
            }
            
            //init ray hit
            RayHit hit = new RayHit();
            hit.t = t[i];
            hit.location = PVector.add(r.origin, PVector.mult(r.direction, t[i]));
            hit.normal = PVector.sub(hit.location, center).normalize();
            hit.entry = i == 0 ? true : false;
            hit.material = material;
            
            //get local coordinates to determine u and v texture coordinates
            PVector local = PVector.sub(hit.location, center).normalize();
            hit.u = 0.5 + atan2(local.y, local.x) / (2 * PI);
            hit.v = 0.5 - asin(local.z) / PI;
            
            result.add(hit);
          }
        }
        
        return result;
    }
}

class Plane implements SceneObject
{
    PVector center;
    PVector normal;
    float scale;
    Material material;
    PVector left;
    PVector up;
    
    Plane(PVector center, PVector normal, Material material, float scale)
    {
       this.center = center;
       this.normal = normal.normalize();
       this.material = material;
       this.scale = scale;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        float denom = PVector.dot(r.direction, normal);
        
        //dont divide by 0
        if(denom != 0)
        {
          float t = (PVector.dot(PVector.sub(center, r.origin), normal)) / denom;
          
          //dont add if behind camera
          if(t >= 0)
          {
            //init ray hit
            RayHit hit = new RayHit();
            hit.t = t;
            hit.location = PVector.add(r.origin, PVector.mult(r.direction, t));
            hit.normal = normal;
            hit.entry = denom < 0 ? true : false;
            hit.material = material;
            
            //basis vectors for texture grid tiling
            PVector z = new PVector(0, 0, 1);
            PVector right = PVector.angleBetween(z, normal) == 0 ? new PVector(0, 1, 0).cross(normal).normalize() : z.cross(normal).normalize(); 
            PVector up = normal.cross(right).normalize();
            
            //coordinate of impact point scaled to texture size
            PVector d = PVector.sub(hit.location, center);
            float x = PVector.dot(d, right) / scale;
            float y = PVector.dot(d, up) / scale;
            
            //texture coordinates
            hit.u = x - floor(x);
            hit.v = (-y) - floor(-y);
            
            result.add(hit);
          }
        }
        
        //if never hit plane and ray origin in plane volume
        //add exit hit at infinity for csg to recognize that you're in the half space and correctly initialize depth
        //check if in plane volume based on dot product of normal vector and vector from center to origin
        if(PVector.dot(PVector.sub(r.origin, center), normal) < 0) {
          RayHit hit = new RayHit();
          hit.t = Float.POSITIVE_INFINITY;
          hit.location = new PVector(0, 0, 0);
          hit.normal = normal;
          hit.entry = false;
          hit.material = material;
          hit.u = 0;
          hit.v = 0;
              
          result.add(hit);
        }
        
        return result;
    }
}

class Triangle implements SceneObject
{
    PVector v1;
    PVector v2;
    PVector v3;
    PVector normal;
    PVector tex1;
    PVector tex2;
    PVector tex3;
    Material material;
    
    Triangle(PVector v1, PVector v2, PVector v3, PVector tex1, PVector tex2, PVector tex3, Material material)
    {
       this.v1 = v1;
       this.v2 = v2;
       this.v3 = v3;
       this.tex1 = tex1;
       this.tex2 = tex2;
       this.tex3 = tex3;
       this.normal = PVector.sub(v2, v1).cross(PVector.sub(v3, v1)).normalize();
       this.material = material;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
                
        //check if intersect plane, can use any vertex for point
        float planeDenom = PVector.dot(r.direction, normal);
        
        //dont divide by 0
        if(planeDenom != 0) {
          float t = (PVector.dot(PVector.sub(v1, r.origin), normal)) / planeDenom;
          PVector location = PVector.add(r.origin, PVector.mult(r.direction, t));

          if(t >= 0) {
            //barycentric coordinates for point in triangle check
            PVector e = PVector.sub(v2, v1);
            PVector g = PVector.sub(v3, v1);
            PVector d = PVector.sub(location, v1);
              
            //check how far hit is along barycentric coordinates
            float triDenom = PVector.dot(e, e) * PVector.dot(g, g) - PVector.dot(e, g) * PVector.dot(g, e);
            float u = (PVector.dot(g, g) * PVector.dot(d, e) - PVector.dot(e, g) * PVector.dot(d, g)) / triDenom;
            float v = (PVector.dot(e, e) * PVector.dot(d, g) - PVector.dot(e, g) * PVector.dot(d, e)) / triDenom;
              
            //add hit if in triangle
            if(u >= 0 && v >= 0 && u + v <= 1)
            {
              //init ray hit
              RayHit hit = new RayHit();
              hit.t = t;
              hit.location = location;
              hit.normal = normal;
              hit.entry = planeDenom < 0 ? true : false;
              hit.material = material;
                
              //i don't have the texture coordinates ordered right to match coefficients in order
              //and to be honest, got lazy and just trial and errored to get the right order (2nd to last possible combination of course)
              float psi = 1 - u - v;
              hit.u = (tex2.x * u) + (tex3.x * v) + (psi * tex1.x);
              hit.v = (tex2.y * u) + (tex3.y * v) + (psi * tex1.y);
              
              //only add entry hits, and add second exit hit eps away for union initialization
              if(hit.entry) {
                result.add(hit);
                RayHit exit = new RayHit();
                exit.entry = false;
                exit.t = hit.t + EPS;
                exit.normal = normal;
                exit.material = material;
                exit.location = PVector.add(hit.location, PVector.mult(r.direction, EPS));
                exit.u = hit.u;
                exit.v = hit.v;
                result.add(exit);
              }
            }
          } 
        }
        
        return result;
    }
}

//return both results from quadratic formula
float[] quadraticFormula(float a, float b, float c)
{
    float determinant = sq(b) - 4 * a * c;
    
    //return empty array if no real roots
    if(determinant < 0) {
       return new float[0];
    }
    
    float root = sqrt(determinant);
    return new float[]{(-b - root) / (2 * a), (-b + root) / (2 * a)};
}

//base class for quadrics since only difference between them is a, b, c values
class Quadric
{
    Material material;
    float scale;
  
    Quadric(Material mat, float scale)
    {
       this.material = mat;
       this.scale = scale;
    }
  
    ArrayList<RayHit> intersect(Ray r, float a, float b, float c)
    {
       ArrayList<RayHit> result = new ArrayList<RayHit>();
       float[] t = quadraticFormula(a, b, c);
       
       for(int i = 0; i < t.length; ++i) {
          //skip if behind camera
          if(t[i] < 0) {
            continue;
          }
            
          RayHit hit = new RayHit();
          hit.t = t[i];
          hit.location = PVector.add(r.origin, PVector.mult(r.direction, t[i]));
          //hit.normal = new PVector(hit.location.x, hit.location.y, 0).normalize(); //set each quadrics normal differently in their intersect()
          hit.entry = i == 0 ? true : false;
          hit.material = material;
          hit.u = 0;
          hit.v = 0;
            
          result.add(hit);
        }
       
       return result;
    }
    
    ArrayList<PVector> getFiniteIntersections(Ray r, PVector[] norm, PVector[] center) {
        ArrayList<PVector> hits = new ArrayList<PVector>();
        
        //bot/top caps info as arrays to loop over
        for(int i = 0; i < norm.length; ++i) {
            float denom = PVector.dot(r.direction, norm[i]);
        
            //dont divide by 0
            if(denom != 0) {
                float t = (PVector.dot(PVector.sub(center[i], r.origin), norm[i])) / denom;
                        
                //dont add if behind camera
                if(t >= 0) {
                    hits.add(PVector.add(r.origin, PVector.mult(r.direction, t)));
                }
            }
        }
        
        return hits;
    }
}

class Cylinder extends Quadric implements SceneObject
{
    float radius;
    float height;
    
    Cylinder(float radius, Material mat, float scale)
    {
       super(mat, scale);
       this.radius = radius;
       this.height = -1;
    }
    
    Cylinder(float radius, float height, Material mat, float scale)
    {
       super(mat, scale);
       this.radius = radius;
       this.height = height;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        float a = sq(r.direction.x) + sq(r.direction.y),
              b = 2 * r.origin.x * r.direction.x + 2 * r.origin.y * r.direction.y,
              c = sq(r.origin.x) + sq(r.origin.y) - sq(radius);

        //get list of hits
        ArrayList<RayHit> temp = super.intersect(r, a, b, c), result = new ArrayList<RayHit>();
        
        for(RayHit hit : temp) {
            //if hit above or below cylinder, need to check if hits caps
            if(height > 0 && (hit.location.z < 0 || hit.location.z > height)) {
                //bot/top caps info as arrays to loop over
                PVector[] norm = new PVector[]{new PVector(0, 0, -1), new PVector(0, 0, 1)},
                          center = new PVector[]{new PVector(0, 0, 0), new PVector(0, 0, height)};
                ArrayList<RayHit> capHits = new ArrayList<RayHit>();
                
                for(int i = 0; i < norm.length; ++i) {
                    float denom = PVector.dot(r.direction, norm[i]);
        
                    //dont divide by 0
                    if(denom != 0)
                    {
                        float t = (PVector.dot(PVector.sub(center[i], r.origin), norm[i])) / denom;
                        
                        //dont add if behind camera
                        if(t >= 0)
                        {
                            PVector location = PVector.add(r.origin, PVector.mult(r.direction, t));
                            
                            //if intersect plane, check that intersection location within cap
                            if(sq(location.x) + sq(location.y) <= sq(radius)) {
                                RayHit capHit = new RayHit();
                                capHit.t = t;
                                capHit.location = location;
                                capHit.normal = norm[i];
                                capHit.entry = denom < 0 ? true : false;
                                capHit.material = material;
                                capHit.u = 0;
                                capHit.v = 0;
                                capHits.add(capHit);
                            }
                        }
                    }
                }
                
                if(capHits.size() > 1) {
                    if(capHits.get(0).t < capHits.get(1).t) {
                        capHits.get(0).entry = true;
                        capHits.get(1).entry = false;
                        result.add(capHits.get(0));
                        result.add(capHits.get(1));
                    } else {
                        capHits.get(0).entry = false;
                        capHits.get(1).entry = true;
                        result.add(capHits.get(1));
                        result.add(capHits.get(0));
                    }
                } else if(capHits.size() == 1) {
                    //capHits.get(0).entry = true;
                    result.add(capHits.get(0));
                }
                 
                continue;
            }
            
            hit.normal = new PVector(hit.location.x, hit.location.y, 0).normalize();
            result.add(hit);
        }
        
        return result;
    }
}

/*
* For remaining quadrics, simply determine a, b, c values, use parent interscet() to get list of hits,
* then loop through hits setting appropriate normal vectors
*/

class Cone extends Quadric implements SceneObject
{
    float height;
    
    Cone(Material mat, float scale)
    {
        super(mat, scale);
        this.height = -1;
    }
    
    Cone(float height, Material mat, float scale)
    {
        super(mat, scale);
        this.height = height;
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        float a = sq(r.direction.x) + sq(r.direction.y) - sq(r.direction.z),
              b = 2 * r.origin.x * r.direction.x + 2 * r.origin.y * r.direction.y - 2 * r.origin.z * r.direction.z,
              c = sq(r.origin.x) + sq(r.origin.y) - sq(r.origin.z);

        ArrayList<RayHit> temp = super.intersect(r, a, b, c), result = new ArrayList<RayHit>();
        
        
        
        
        for(RayHit hit : temp) {
            //if hit above or below cylinder, need to check if hits caps
            if(height > 0 && (hit.location.z < -height || hit.location.z > height)) {
                //bot/top caps info as arrays to loop over
                PVector[] norm = new PVector[]{new PVector(0, 0, -1), new PVector(0, 0, 1)},
                          center = new PVector[]{new PVector(0, 0, -height), new PVector(0, 0, height)};
                ArrayList<RayHit> capHits = new ArrayList<RayHit>();
                
                for(int i = 0; i < norm.length; ++i) {
                    float denom = PVector.dot(r.direction, norm[i]);
        
                    //dont divide by 0
                    if(denom != 0)
                    {
                        float t = (PVector.dot(PVector.sub(center[i], r.origin), norm[i])) / denom;
                        
                        //dont add if behind camera
                        if(t >= 0)
                        {
                            PVector location = PVector.add(r.origin, PVector.mult(r.direction, t));
                            
                            //if intersect plane, check that intersection location within cap
                            if(sq(location.x) + sq(location.y) <= sq(location.z)) {
                                RayHit capHit = new RayHit();
                                capHit.t = t;
                                capHit.location = location;
                                capHit.normal = norm[i];
                                capHit.entry = denom < 0 ? true : false;
                                capHit.material = material;
                                capHit.u = 0;
                                capHit.v = 0;
                                capHits.add(capHit);
                            }
                        }
                    }
                }
                
                if(capHits.size() > 1) {
                    if(capHits.get(0).t < capHits.get(1).t) {
                        capHits.get(0).entry = true;
                        capHits.get(1).entry = false;
                        result.add(capHits.get(0));
                        result.add(capHits.get(1));
                    } else {
                        capHits.get(0).entry = false;
                        capHits.get(1).entry = true;
                        result.add(capHits.get(1));
                        result.add(capHits.get(0));
                    }
                } else if(capHits.size() == 1) {
                    //capHits.get(0).entry = true;
                    result.add(capHits.get(0));
                }
                 
                continue;
            }
            
            hit.normal = new PVector(2 * hit.location.x, 2 * hit.location.y, -2 * hit.location.z).normalize();
            result.add(hit);
        }
        
        
        /*for(RayHit hit : result) {
            hit.normal = new PVector(2 * hit.location.x, 2 * hit.location.y, -2 * hit.location.z).normalize();
        }*/
        
        return result;
    }
   
}

class Paraboloid extends Quadric implements SceneObject
{
    Paraboloid(Material mat, float scale)
    {
        super(mat, scale);
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        float a = sq(r.direction.x) + sq(r.direction.y),
              b = 2 * r.origin.x * r.direction.x + 2 * r.origin.y * r.direction.y - r.direction.z,
              c = sq(r.origin.x) + sq(r.origin.y) - r.origin.z;

        ArrayList<RayHit> result = super.intersect(r, a, b, c);
        
        for(RayHit hit : result) {
            hit.normal = new PVector(2 * hit.location.x, 2 * hit.location.y, -1).normalize();;
        }
        
        return result;
    }
   
}

class HyperboloidOneSheet extends Quadric implements SceneObject
{
    HyperboloidOneSheet(Material mat, float scale)
    {
        super(mat, scale);
    }
  
    ArrayList<RayHit> intersect(Ray r)
    {
        float a = sq(r.direction.x) + sq(r.direction.y) - sq(r.direction.z),
              b = 2 * r.origin.x * r.direction.x + 2 * r.origin.y * r.direction.y - 2 * r.origin.z * r.direction.z,
              c = sq(r.origin.x) + sq(r.origin.y) - sq(r.origin.z) - 1;

        ArrayList<RayHit> result = super.intersect(r, a, b, c);
        
        for(RayHit hit : result) {
            hit.normal = new PVector(2 * hit.location.x, 2 * hit.location.y, -2 * hit.location.z).normalize();;
        }
        
        return result;
    }
}

class HyperboloidTwoSheet extends Quadric implements SceneObject
{
    HyperboloidTwoSheet(Material mat, float scale)
    {
        super(mat, scale);
    }
    
    ArrayList<RayHit> intersect(Ray r)
    {
        float a = sq(r.direction.x) + sq(r.direction.y) - sq(r.direction.z),
              b = 2 * r.origin.x * r.direction.x + 2 * r.origin.y * r.direction.y - 2 * r.origin.z * r.direction.z,
              c = sq(r.origin.x) + sq(r.origin.y) - sq(r.origin.z) + 1;

        ArrayList<RayHit> result = super.intersect(r, a, b, c);
        
        for(RayHit hit : result) {
            hit.normal = new PVector(2 * hit.location.x, 2 * hit.location.y, -2 * hit.location.z).normalize();;
        }
        
        return result;
    }
}
