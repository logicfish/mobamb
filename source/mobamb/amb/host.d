module mobamb.amb.host;

private import std.random;

private import mobamb.amb.tag;
private import mobamb.amb.domain;
private import mobamb.amb.ambient;

final class HostObject {
  void evaluate(TypedProcess r) {
    while(r.cleanup is false) {}
    bool f = tagPool.evaluate;
    while(f) {
      while(r.cleanup is false) {}
      f = tagPool.evaluate;
    }
  }
  TagPool _tagPool;
  this(TagPool t = new TagPool) {
    _tagPool = t;
  }
  auto tagPool() {
    return _tagPool;
  }
}

class HostAmbient : MobileAmbient {
  HostObject _hostObject;

  this(HostObject o = new HostObject) {
    super();
    this._hostObject = o;
  }
  bool createTag(T)(Capability cap,MobileAmbient amb) {
    return tagPool.createTag!T(cap,amb);
  }
  protected auto tagPool() {
    return _hostObject.tagPool;
  }
  HostObject hostObject() {
    return _hostObject;
  }
  const(HostObject) hostObject() const {
    return _hostObject;
  }
  void evaluate() {
    hostObject.evaluate(this);
  }
}
