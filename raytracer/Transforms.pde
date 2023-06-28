class MoveRotation implements SceneObject
{
  SceneObject child;
  PVector movement;
  PVector rotation;
  
  MoveRotation(SceneObject child, PVector movement, PVector rotation)
  {
    this.child = child;
    this.movement = movement;
    this.rotation = rotation;
  }
  
  void rotateZ(PVector original, float angle) {
      float x = (cos(angle) * original.x) - (sin(angle) * original.y);
      float y = (sin(angle) * original.x) + (cos(angle) * original.y);
      original.x = x;
      original.y = y;
  }
  
  void rotateY(PVector original, float angle) {
      float x = (sin(angle) * original.z) + (cos(angle) * original.x);
      float z = (cos(angle) * original.z) - (sin(angle) * original.x);
      original.x = x;
      original.z = z;
  }
  
  void rotateX(PVector original, float angle) {
      float y = (cos(angle) * original.y) - (sin(angle) * original.z);
      float z = (sin(angle) * original.y) + (cos(angle) * original.z);
      original.y = y;
      original.z = z;
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
      //inverse translate origin, copy direction vector to not alter original ray
      PVector origin = PVector.sub(r.origin, movement);
      PVector direction = r.direction.copy();
      
      //inverse rotate origin
      rotateY(origin, -rotation.y);
      rotateX(origin, -rotation.x);
      rotateZ(origin, -rotation.z);
      
      //inverse rotate direction
      rotateY(direction, -rotation.y);
      rotateX(direction, -rotation.x);
      rotateZ(direction, -rotation.z);
      
      ArrayList<RayHit> result = child.intersect(new Ray(origin, direction));
     
      //transform back
      for(RayHit hit : result) {
          PVector norm = hit.normal.copy();
          
          //rotate direction
          rotateZ(norm, rotation.z);
          rotateX(norm, rotation.x);
          rotateY(norm, rotation.y);
          
          //rotate origin
          rotateZ(hit.location, rotation.z);
          rotateX(hit.location, rotation.x);
          rotateY(hit.location, rotation.y);
          
          //translate location
          hit.location.add(movement);
          hit.normal = norm;
      }
     
      return result;
  }
}

class Scaling implements SceneObject
{
  SceneObject child;
  PVector scaling;
  
  Scaling(SceneObject child, PVector scaling)
  {
    this.child = child;
    this.scaling = scaling;
  }
  
  
  ArrayList<RayHit> intersect(Ray r)
  {
      //copy vectors to not alter original ray
      PVector origin = r.origin.copy(), direction = r.direction.copy();
      
      //inverse rotate origin
      origin.x = origin.x / scaling.x;
      origin.y = origin.y / scaling.y;
      origin.z = origin.z / scaling.z;
      
      //inverse rotate direction
      direction.x = direction.x / scaling.x;
      direction.y = direction.y / scaling.y;
      direction.z = direction.z / scaling.z;
      direction.normalize();
      
      ArrayList<RayHit> result = child.intersect(new Ray(origin, direction));
     
      //transform back
      for(RayHit hit : result) {
          PVector norm = hit.normal.copy();
          
          //rotate origin
          hit.location.x = hit.location.x * scaling.x;
          hit.location.y = hit.location.y * scaling.y;
          hit.location.z = hit.location.z * scaling.z;
          
          //rotate direction
          norm.x = norm.x * scaling.x;
          norm.y = norm.y * scaling.y;
          norm.z = norm.z * scaling.z;
          norm.normalize();
          hit.normal = norm;
      }
     
      return result;
  }
}
