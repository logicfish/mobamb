module mobamb.amb.host;

private import mobamb.amb.tag;
private import mobamb.amb.domain;
private import mobamb.amb.ambients;

final class HostObject {
  TagPool _tagPool;
  void runProcess(TypedProcess r) {
    while(p.cleanup is false) {}
    auto h = p.evolutions;
    while(h.length>0) {
      if(h.length==1) h[0].execute;
      else h[uniform(0, h.length-1)].execute;
      while(r.cleanup is false){}
      h = r.evolutions;
    }
  }
}

class HostAmbient : MobileAmbient {
  HostObject _hostObject;

  this(HostObject o) {
    super();
    this._hostObject = o;
  }
}
