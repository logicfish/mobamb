module mobamb.amb.tag;

private import std.algorithm,
    std.parallelism,
    std.range;

private import mobamb.amb.domain;
private import mobamb.amb.ambient;
private import mobamb.amb.names;

debug {
    import std.experimental.logger;
    import std.conv;
}

/**
A tag represents a pending operation on a mobile process.
They are maintained by a particular TagPool instance, attached to a
host process.  The caller invokes evaluation methods on the host to
incurr tag processing. Operations which modify the process heirarchy
(with respect to ambient boundaries) are synchronised by being
delegated to a single mobility thread.

**/
interface Tag {
  alias Apply = bool delegate(Tag);
  alias Close = void delegate(Tag,bool);
  Capability lemma();  // the definition that proves the existence of the tag.
  MobileAmbient ambient(); // the owner of the tag
  MobileAmbient target(); // the owner of the tag
  void evaluate();
  void close(bool);
}

class TagPool {
  abstract class _Tag : Tag {
    Capability _lemma;
    MobileAmbient _ambient;
    MobileAmbient _target;
    @property {
      Capability lemma() {
        return _lemma;
      }
      MobileAmbient ambient() {
        return _ambient;
      }
      MobileAmbient target() {
        return _target;
      }
    }
    /* bool __exec(Tag t) {
      return false;
    }
    void __close(Tag t,bool b) {
    } */
  }
  /**
  AsyncTags are processed in the caller thread.
  **/
  //class AsyncTag(_exec : Tag.Apply , _close : Tag.Close) : _Tag {
  class AsyncTag(alias _exec,alias _close) : _Tag {

    static void _execute(_Tag t) {
        auto __d = ProcessDomain.localDomain(t.ambient.domain);
        scope(exit) {
          debug(Tagging) {
              sharedLog.info("restore domain ",__d);
          }
          ProcessDomain.localDomain(__d);
        }
        bool b = _exec(t);
        t.outer.closeTag(t,b);
    }
    void evaluate() {
        _taskPool.put(task!_execute(this));
    }
    void close(bool f) {
      _close(this,f);
    }
  }
  /**
  SyncTags are processed in single thread attached to the enclosing
  TagPool.
  **/
  //class SyncTag (_exec : Tag.Apply, _close : Tag.Close)
  //    : AsyncTag!(_exec,_close) {
  class SyncTag (alias _exec, alias _close)
      : AsyncTag!(_exec,_close) {
    override void evaluate() {
        if(runningTask) {
            _execute(this);
        } else {
            super._execute(this);
        }
    }
  }
  //final class _EnterTag : SyncTag!(delegate bool(Tag x) {
  final class _EnterTag : SyncTag!(function bool(Tag x) {
    // _exec function for _enter.
    debug(Tagging) {
        sharedLog.info("_EnterTag "~ x.ambient.name.to!string);
        sharedLog.info("_EnterTag --> "~ x.target.name.to!string);
    }
    x.ambient.moveIn(cast(ProcessName.Caps)x.lemma,x.target);
    return true;
  },(x,f) {
    if(f) {
        // look for any siblings matching 'in' tags
        // look for a matching 'out' tag...
    }
  }) {}

  final class _LeaveTag : SyncTag!(function bool(Tag x) {
    // _exec function for _leave.
    debug(Tagging) {
        sharedLog.info("_LeaveTag " ~ x.ambient.name.to!string);
        sharedLog.info("_LeaveTag --> "~ x.target.name.to!string);
    }
    x.ambient.moveOut(cast(ProcessName.Caps)x.lemma,x.target);
    //x.ambient.moveOut(cast(ProcessName.Caps)x.lemma,x.ambient.getParentAmbient);
    return true;
  },(x,f){
  }) {}

  abstract class SyncIOTag(alias _exec,alias _close) : SyncTag!(_exec,_close)
  {
  }
  final class _InputTag() : SyncIOTag!((t) {
    // _exec function for _input.
    debug(Tagging) {
        sharedLog.info("_InputTag "~ t.ambient.name.to!string);
        sharedLog.info("_InputTag --> "~ t.lemma.name.to!string);
    }
    return t.ambient.domain.input(t.lemma);
  },(t,f) {
    if(f) {
      auto _t = task!((Tag t){
        t.ambient.caps = t.ambient.caps.remove!(x => x == t.lemma);
      })(t);
      t.ambient.getHostAmbient.put!(typeof(_t))(_t);
    }
  }) {
  }

  final class _OutputTag() : SyncIOTag!((t) {
    // _exec function for _output.
    debug(Tagging) {
        sharedLog.info("_OutputTag " ~ t.ambient.name.to!string);
        sharedLog.info("_OutputTag --> "~ t.lemma.name.to!string);
    }
    return t.ambient.domain.output(t.lemma);
  },(t,f){
    if(f) {
      t.ambient.caps = t.ambient.caps.remove!(x => x == t.lemma);
    }
  }) {
  }

  final class InputTag() : AsyncTag!((Tag t){
    // _exec function for _input.
    auto p = t.ambient.getParentAmbient();
    if(p is null) return false;
    //const(Name) channel = (cast(IOTag)t).channel;
    return t.ambient.getHostAmbient.createTag!(_InputTag!())(
        t.lemma,t.ambient,p
    );
  },(x,f)=>{}) {
  }

  final class OutputTag() : AsyncTag!((Tag t){
    // _exec function for _output.
    auto p = t.ambient.getParentAmbient();
    if(p is null) return false;
    return t.ambient.getHostAmbient.createTag!(_OutputTag!())(
      t.lemma,t.ambient,p
    );
  },(x,f)=>{}) {
  }

/*  final class _ConstructorTag() : AsyncTag!(x=>{
    return true;
  },(x,f)=>{}) {} */

  final class InTag() : AsyncTag!((Tag x) {
    auto p = x.ambient.getParentAmbient();
    if(p is null) return false;
    //auto t = cast(MobileAmbient)x.ambient.getParentAmbient.findChildByName(cast(ProcessName)x.lemma.);
    //if(t is null) return false;
    x.ambient.getHostAmbient.createTag!(_LeaveTag)(x.lemma,x.ambient,p);
    x.target.getHostAmbient.createTag!(_EnterTag)(x.lemma,x.ambient,x.target);
    return true;
  },(Tag x,bool f) {
  }) {
  }

  final class OutTag() : AsyncTag!((Tag x){
    //auto p = x.ambient.getParentAmbient();
    //auto p = x.ambient.parent;
    auto p = x.target;
    if(p is null) return false;
    auto t = p.getParentAmbient;
    //auto t = x.target;
    if(t is null) return false;
    x.ambient.getHostAmbient.createTag!(_LeaveTag)(x.lemma,x.ambient,p);
    t.getHostAmbient.createTag!(_EnterTag)(x.lemma,x.ambient,t);
    return true;
  },(Tag x,bool f) {
    /*if(f) {
      _outTag = null;
    }*/
  }) {
  }

// Tags hashed by the source process name.
  //Tag[] tags;

   //void addTag(Tag t) {
    // tags ~= t;
   //}
   void closeTag(Tag t,bool f) {
    //tags = tags.remove!(a=>t == a);
    //t.source.removeTarget(t);
    //t.target.removeSource(t);
    /*_taskPool.put(task!(function void(Tag t,bool f){
      auto a = t.ambient;
      a.deleteTag(t);
      t.close(f);
    }))(t,f))();*/
    auto a = task!(function void(Tag t,bool f){
      //t.ambient.deleteTag(t);
      t.close(f);
    })(t,f);
    _taskPool.put(a);
  }

  Tag _outTag = null;
  Tag[MobileAmbient] _inTags;

  Tag _inputTag = null;
  Tag[MobileAmbient] _outputTags;

  Tag[] _otherTags;

  /*static bool evaluateTask(TagPool p) {
    return p.evaluate;
  }*/
  bool evaluate() {
    return __eval(this);
  }
  static bool __evalPI(TagPool p) {
    debug(Tagging) {
      sharedLog.info("TagPool.__evalPI");
    }
    Tag _inputTag = null;
    Tag[MobileAmbient] _outputTags;
    synchronized(p) {
      if(empty(p._outputTags) && p._inputTag is null) {
          return false;
      }
      _outputTags = p._outputTags.dup;
    }
    foreach(a,tag ; _outputTags) {
        debug(Tagging) {
          sharedLog.info("output "~a.to!string);
        }
        tag.evaluate();
    }
    synchronized(p) {
        Tag[MobileAmbient] x;
        p._outputTags = x;
        _outputTags = x;
    }
    synchronized(p) {
        _inputTag = p._inputTag;
    }
    if(_inputTag !is null) {
        debug(Tagging) {
          sharedLog.info("input "~_inputTag.to!string);
        }
        _inputTag.evaluate;
        synchronized(p) {
          assert(p._inputTag is _inputTag);
          p._inputTag = null;
          _inputTag = null;
        }
    }
    return true;
  }
  static bool __eval(TagPool p) {
    debug(Tagging) {
      sharedLog.info("TagPool.__eval");
    }
    /*if(!runningTask) {
      debug(Tagging) {
        sharedLog.info("evaluate not running in taskpool.");
      }
      auto t = task!evaluateTask(this);
      _taskPool.put(t);
      while(!t.done){}
      return t.yieldForce;
    }*/

    if(__evalPI(p)) return true;

    Tag _outTag = null;
    Tag[MobileAmbient] _inTags;
    Tag[] _otherTags;

    synchronized(p) {
      if(empty(p._inTags) && p._outTag is null && empty(p._otherTags)) {
          return false;
      }
      _inTags = p._inTags.dup;
    }

    foreach(a,tag ; _inTags) {
        debug(Tagging) {
          sharedLog.info("in "~a.to!string);
        }
        tag.evaluate();
        //synchronized(p) {
          //p._inTags = p._inTags.remove!(x=>x == tag);
        //}
    }
    synchronized(p) {
        Tag[MobileAmbient] x;
        p._inTags = x;
        _inTags = x;
    }
    synchronized(p) {
        _outTag = p._outTag;
    }
    if(_outTag) {
        debug(Tagging) {
          sharedLog.info("out "~_outTag.to!string);
        }
        _outTag.evaluate;
        synchronized(p) {
          assert(p._outTag is _outTag);
          p._outTag = null;
          _outTag = null;
        }
    }
    do {
      synchronized(p) {
        _otherTags = p._otherTags.dup;
      }
      foreach(t ; _otherTags) {
        debug(Tagging) {
          sharedLog.info("other "~t.to!string);
        }
        t.evaluate();
        synchronized(p) {
          p._otherTags = p._otherTags.remove!(x=>x == t);
        }
      }
    } while(!_otherTags.empty);

    /*synchronized(p) {
      p._otherTags = [];
      _otherTags = [];
    }*/
    return true;
  }
  // generic tag
  /*void createTag(Tag.Apply A,Tag.Close C)(Capability cap,MobileAmbient amb) {
    auto a = new _Tag!(A,C);
    a._lemma = cap;
    a._ambient = amb;
    /*_taskPool.put({
        /* amb.evol ~= a; * /
    });* /
    _otherTags ~= a;
  }*/

  /*static bool createTagTask(T:Tag)(TagPool p,Capability cap,MobileAmbient amb,
    MobileAmbient t) {
    debug(Tagging) {
      sharedLog.info("createTagTask: " ~ typeid(T).name);
    }
    return p.createTag!T(cap,amb,t);
  }*/
  // return true to halt evaluation and process tags...
  bool createTag(T : Tag)(
    Capability cap,MobileAmbient amb,MobileAmbient tamb)
     {
    /*if(!runningTask()) {
      debug(Tagging) {
        sharedLog.info("createTag not running in pool: " ~ typeid(T).name);
      }
      //  return p.createTag!T(_cap,_amb);
      //bool delegate (TagPool,Capability,MobileAmbient) _t = (p,_cap,_amb){
      //};
      //auto t = task!(&_t)(this,cap,amb);
      auto t = task!(createTagTask!T)(this,cap,amb,tamb);
      _taskPool.put(t);
      while(!t.done){}
      return t.yieldForce;
    }*/
    auto mk = delegate Tag(){
      debug(Tagging) {
        sharedLog.info("New tag: " ~ typeid(T).name);
      }
      auto a = new T();
      a._lemma = cap;
      a._ambient = amb;
      a._target = tamb;
      return a;
    };
    /*_taskPool.put({
        /* amb.evol ~= a; * /
    });*/

    //waitForPool;

    synchronized(this) {
        static if(is(T == OutTag!())) {
            if(_outTag is null && amb !in _inTags) {
                _outTag = mk();
                return true;
            } else {
                return false;
            }
        } else if(is(T == InTag!())) {
            if(amb !in _inTags) {
                if(_outTag !is null && amb == _outTag.ambient) {
                    return false;
                }
                _inTags[amb] = mk();
                return true;
            } else {
                return false;
            }
        } else if(is(T == InputTag!())) {
          //if(_inputTag is null && amb !in _outputTags) {
          if(_inputTag is null) {
            _inputTag = mk();
            return true;
          } else return false;
        } else if(is(T == OutputTag!())) {
          // one output per ambient...
          if(amb !in _outputTags) {
            //if(_inputTag !is null && amb == _inputTag.ambient) {
            //  return false;
            //}
            _outputTags[amb] = mk();
            return true;
          } else return false;
        } else {
            _otherTags ~= mk();
            return true;
        }
    }
    //return false;
  }
  /**
    Boolean true if we are in running inside the single task thread;
    Returns:
      true if the current thread is the task pool thread.
  **/
  bool runningTask() {
    debug(Tagging) {
      sharedLog.info("runningTask ",_taskPool.workerIndex);
    }
    return _taskPool.workerIndex != 0;
  }
  /*void waitForPool() {
    try {
      if(!runningTask) {
        taskPool.finish(true);
      }
    } catch(Exception e) {
      debug(Tagging) {
        sharedLog.info(e.message);
      }
    }
  }*/
  void finish() {
    _taskPool.finish(true);
  }

  void put(alias T)(T _t) {
    _taskPool.put(_t);
  }

  // Single-threaded task pool
  private TaskPool _taskPool;

  this() {
    _taskPool = new TaskPool(1);
    _taskPool.put(task!({
        debug(Tagging) {
          sharedLog.info("Task pool active.");
        }
      }));
  }

}

class TagTask(T : TagTask!T) {
  TagPool _pool;

  this(TagPool p) {
    this._pool = p;
  }

  @property
  auto TagPool pool() {
    return _pool;
  }

  auto run() {
    return new T(pool);
  }
}
