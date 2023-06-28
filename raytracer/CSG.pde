import java.util.Comparator;

class HitCompare implements Comparator<RayHit>
{
  int compare(RayHit a, RayHit b)
  {
     if (a.t < b.t) return -1;
     if (a.t > b.t) return 1;
     if (a.entry) return -1;
     if (b.entry) return 1;
     return 0;
  }
}

class Union implements SceneObject
{
  SceneObject[] children;
  Union(SceneObject[] children)
  {
    this.children = children;
  }

  ArrayList<RayHit> intersect(Ray r)
  {
     
     ArrayList<RayHit> hits = new ArrayList<RayHit>(), result = new ArrayList<RayHit>();
     int depth = 0;
     
     // Reminder: this is *not* a true union
     // For a true union, you need to ensure that enter-
     // and exit-hits alternate
     for (SceneObject sc : children)
     {
       ArrayList<RayHit> temp = sc.intersect(r);
       
       //if first hit of a child is an exit, you start within that object, increment depth
       if(temp.size() > 0 && temp.get(0).entry == false) {
         ++depth;
       }
       
       hits.addAll(temp);
     }
     hits.sort(new HitCompare());
     
     for(RayHit hit : hits) {
         //add enter hits at 0
         if(hit.entry) {
             if(depth == 0) {
                 result.add(hit);
             }
             
             ++depth;
         }
         //add exits hits at 1
         else {
             if(depth == 1) {
                 result.add(hit);
             }
             
             --depth;
         }
     }
     
     return result;
  }
  
}

class Intersection implements SceneObject
{
  SceneObject[] elements;
  Intersection(SceneObject[] elements)
  {
    this.elements = elements;
  }
  
  
  ArrayList<RayHit> intersect(Ray r)
  {
     ArrayList<RayHit> hits = new ArrayList<RayHit>(), result = new ArrayList<RayHit>();
     int depth = 0;
     
     for (SceneObject sc : elements)
     {
       ArrayList<RayHit> temp = sc.intersect(r);
       
       //if first hit of a child is an exit, you start within that object, increment depth
       if(temp.size() > 0 && temp.get(0).entry == false) {
         ++depth;
       }
       
       hits.addAll(temp);
     }
     hits.sort(new HitCompare());
     
     for(RayHit hit : hits) {
         //add enter hits when entering all objects
         if(hit.entry) {
             if(depth == elements.length - 1) {
                 result.add(hit);
             }
             
             ++depth;
         }
         //add exit hits when no longer in all objects
         else {
             if(depth == elements.length) {
                 result.add(hit);
             }
             
             --depth;
         }
     }
     
     /*if(result.size() > 0) {
       boolean b = result.get(0).entry;
       
       for(RayHit hit : result) {
         assert b == hit.entry;
         b = !b;
       }
     }*/
     
     return result;
  }
  
}

class Difference implements SceneObject
{
  SceneObject a;
  SceneObject b;
  Difference(SceneObject a, SceneObject b)
  {
    this.a = a;
    this.b = b;
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
     ArrayList<RayHit> hitsA = a.intersect(r), hitsB = b.intersect(r), result = new ArrayList<RayHit>();
     hitsA.sort(new HitCompare()); //pretty sure this is unnecessary
     hitsB.sort(new HitCompare());
     
     //return if either list of hits empty, will either return all a hits, or empty list if no a hits
     if(hitsA.size() == 0 || hitsB.size() == 0) {
         return hitsA;
     }
     
     //use !entry since an exit hit (entry = false) corresponds to starting in that volume (inA/inB = true)
     int indexA = 0, indexB = 0;
     boolean inA = !hitsA.get(0).entry, inB = !hitsB.get(0).entry;
     
     /*
     * This loop is needlessly verbose, but i need it to be able to wrap my head around it and follow the logic... let me have this
     */
     
     for(int i = 0; i < hitsA.size() + hitsB.size(); ++i) {
         //still a hits, next closest hit is a or no more b hits
         if(indexA < hitsA.size() && (indexB >= hitsB.size() || hitsA.get(indexA).t < hitsB.get(indexB).t)) {
             //case: hit a first (since in neither yet)
             if(!inA && !inB) {
                 //can simply use enter hit
                 result.add(hitsA.get(indexA));
                 //inA = true;
             }
             
             //case: leave a before hitting b
             else if(inA && !inB) {
                 //can simply use exit hit
                 result.add(hitsA.get(indexA));
                 //inA = false;
             }
             
             //case: enter a before leaving b
             else if(!inA && inB) {
                 //do nothing, in b
                 //inA = true;
             }
             
             //case: exit a before exiting b
             else if(inA && inB) {
                 //do nothing, still in b
                 //inA = false;
             }
             
             //flip boolean that tracks whether in a or not, and increment to next a hit
             inA = !inA;
             ++indexA;
         }
         //next closest hit is b
         else {
             //case: hit b first (since in neither yet)
             if(!inA && !inB) {
                 //do nothing
             }
             
             //case: exit b before entering a
             else if(!inA && inB) {
                 //do nothing
             }
             
             //case: hit b before exiting a
             else if(inA && !inB) {
                 //convert enter hit to an exit hit (change entry to false and flip normal vector)
                 hitsB.get(indexB).entry = false;
                 hitsB.get(indexB).normal.mult(-1);
                 result.add(hitsB.get(indexB));
             }
             
             //case: exit b before exiting a
             else if(inA && inB) {
                 //convert exit hit to an enter hit (change entry to true and flip normal vector)
                 hitsB.get(indexB).entry = true;
                 hitsB.get(indexB).normal.mult(-1);
                 result.add(hitsB.get(indexB));
             }
             
             //flip boolean that tracks whether in b or not, and increment to next b hit
             inB = !inB;
             ++indexB;
         }
     }
     
     return result;
  }
  
}
