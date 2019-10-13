module mobamb.amb.host;

private import std.random;

private import mobamb.amb.tag;
private import mobamb.amb.domain;
private import mobamb.amb.types;
private import mobamb.amb.ambient;
private import mobamb.amb.process;
private import mobamb.amb.names;

debug {
    import std.experimental.logger;
}


final class HostObject {
  void evaluate(TypedProcess r) {
    debug(Host) {
        sharedLog.info("Host evaluation start.");
    }
    auto __d = ProcessDomain.localDomain(r.domain);
    scope(exit) {
      debug(Host) {
          sharedLog.info("restore domain ",__d);
      }
      ProcessDomain.localDomain(__d);
    }
    while(r.cleanup is false) {}
    //bool f = tagPool.evaluate;
    //waitForPool;
    //if(!f) f = r.evaluateAll;
    bool f = r.evaluateAll;
    //tagPool.waitForPool;

    do {
      debug(Host) {
        sharedLog.info("Host evaluation loop.");
      }
      while(r.cleanup is false) {}
      //if(!f) f = r.evaluateAll;
      f = tagPool.evaluate;
      if(!f) {
        r.evaluateAll;
        while(r.cleanup is false) {}
        f = tagPool.evaluate;
      }
      //tagPool.waitForPool;
    } while(f);
    debug(Host) {
        sharedLog.info("Host evaluation finished.");
    }
    _tagPool.finish();
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

  this(MobileProcess p,ProcessName n,HostObject o = new HostObject) {
    super(p,n);
    this._hostObject = o;
  }
  bool createTag(T : Tag,Args...)(
    Capability cap,MobileAmbient amb,MobileAmbient t,Args args
  ) {
    return tagPool.createTag!(T,Args)(cap,amb,t,args);
  }
  //bool createTag(T)(Capability cap,MobileAmbient amb) {
  //  return tagPool.createTag!T(cap,amb);
  //}
  bool createTag(string T)(Capability cap,MobileAmbient amb,MobileAmbient t) {
    static if (T is "out") {
        return createTag!(TagPool.OutTag!())(cap,amb,t);
    } else if (T is "in") {
        return createTag!(TagPool.InTag!())(cap,amb,t);
    } else if (T is "input") {
        auto c = (cast(ProcessName.Input)cap).channel;
        return createTag!(TagPool.InputTag!())(cap,amb,t);
    } else if (T is "output") {
        auto c = (cast(ProcessName.Output)cap).channel;
        return createTag!(TagPool.OutputTag!())(cap,amb,t);
    } else return false;
  }
  protected auto tagPool() {
    return _hostObject.tagPool;
  }
  void put(alias T)(T _t) {
    tagPool.put!T(_t);
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
