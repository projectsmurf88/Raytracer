class Light
{
   PVector position;
   color diffuse;
   color specular;
   Light(PVector position, color col)
   {
     this.position = position;
     this.diffuse = col;
     this.specular = col;
   }
   
   Light(PVector position, color diffuse, color specular)
   {
     this.position = position;
     this.diffuse = diffuse;
     this.specular = specular;
   }
   
   color shine(color col)
   {
       return scaleColor(col, this.diffuse);
   }
   
   color spec(color col)
   {
       return scaleColor(col, this.specular);
   }
}

class LightingModel
{
    ArrayList<Light> lights;
    LightingModel(ArrayList<Light> lights)
    {
      this.lights = lights;
    }
    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      color hitcolor = hit.material.getColor(hit.u, hit.v);
      color surfacecol = lights.get(0).shine(hitcolor);
      PVector tolight = PVector.sub(lights.get(0).position, hit.location).normalize();
      float intensity = PVector.dot(tolight, hit.normal);
      return lerpColor(color(0), surfacecol, intensity);
    }
  
}

class PhongLightingModel extends LightingModel
{
    color ambient;
    boolean withshadow;
    PhongLightingModel(ArrayList<Light> lights, boolean withshadow, color ambient)
    {
      super(lights);
      this.withshadow = withshadow;
      this.ambient = ambient;
    }
    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      //get color at hit location, and init the color to return by scaling by the ambient color and multiplying by ka
      color hitColor = hit.material.getColor(hit.u, hit.v);
      color scaledAmbient = multColor(scaleColor(ambient, hitColor), hit.material.properties.ka);
      color finalColor = color(0);
      
      for(Light light : lights) {
          //get vector that points to the light and init origin of ray to check for shadows to be offset by EPS
          PVector toLight = PVector.sub(light.position, hit.location).normalize();
          PVector origin = PVector.add(hit.location, PVector.mult(toLight, EPS));
          
          //if anything between light and hit, skip this light, will be shadow
          if(withshadow) {
              ArrayList<RayHit> shadowHits = sc.root.intersect(new Ray(origin, toLight));
              
              //compare distance of first hit to light position to see which is closer
              if(shadowHits.size() > 0 && shadowHits.get(0).t < hit.location.dist(light.position)) {
                  continue;
              }
          }
          
          //vectors needed to calculate specular color
          PVector r = PVector.sub(PVector.mult(PVector.mult(hit.normal, 2), PVector.dot(hit.normal, toLight)), toLight).normalize();
          PVector v = PVector.sub(viewer, hit.location).normalize();
          
          //get shine and spec colors
          color id = light.shine(hitColor);
          color is = light.spec(hitColor);
          
          //calculate diffuse and specular colors for this light
          color diffuse = multColor(multColor(id, hit.material.properties.kd), PVector.dot(toLight, hit.normal));
          color specular = multColor(multColor(is, hit.material.properties.ks), pow(PVector.dot(r, v), hit.material.properties.alpha));
          
          //apply diffuse and specular contributions for this light
          finalColor = addColors(finalColor, addColors(diffuse, specular));
      }
      
      return addColors(scaledAmbient, finalColor);
    }
  
}
