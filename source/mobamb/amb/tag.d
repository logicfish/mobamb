module mobamb.amb.tag;

private import std.algorithm,
    std.parallelism,
    std.range;

private import mobamb.amb.domain;
private import mobamb.amb.ambient;
private import mobamb.amb.names;

interface Tag {
  alias Apply = bool delegate(Tag);
  alias Close = void delegate(Tag,bool);
  Capability lemma();  // the definition that proves the existence of the tag.
  MobileAmbient ambient(); // the owner of the tag
  void evaluate();
  void close(bool);
}

class TagPool {
  class _Tag : Tag {
    Capability _lemma;
    MobileAmbient _ambient;
    Capability lemma() {
      return _lemma;
    }
    MobileAmbient ambient() {
      return _ambient;
    }
    bool __exec(Tag t) {
      return false;
    }
    void __close(Tag t,bool b) {
    }
  }
  class AsyncTag(_exec : Tag.Apply , _close : Tag.Close) : _Tag {

    void _execute() {
        removeTag(this,_exec());
    }
    void evaluate() {
        _taskPool.put(&_execute);
    }
    void close(bool f) {
      _close(f);
    }
  }
  class SyncTag (_exec : Tag.Apply, _close : Tag.Close)
      : AsyncTag!(_exec,_close) {
    void evaluate() {
        _execute();
    }
  }
  /*final class _EnterTag(alias target) : SyncTag!(delegate bool(Tag x) {
    // _exec function for _enter.
    x.ambient.moveIn(x.lemma,target);
    return true;
  },delegate void(Tag x,bool f) {}) {

  }*/

  final class _EnterTag : SyncTag!(&_Tag.__exec,&_Tag.__close) {
    bool __exec(Tag t) {

    }
    void __close(Tag T,bool f) {

    }
  }

  final class _LeaveTag(alias target)  : SyncTag!(delegate bool(Tag x) {
    // _exec function for _leave.
    x.ambient.moveOut(x.lemma,target);
    return true;
  },delegate void(Tag x,bool f){}) {}

  final class _InputTag() : AsyncTag!(x=>{
    // _exec function for _input.
    return true;
  },(x,f)=>{}) {}

  final class _OutputTag() : AsyncTag!(x=>{
    // _exec function for _output.
    return true;
  },(x,f)=>{}) {}

  final class _ConstructorTag() : AsyncTag!(x=>{
    return true;
  },(x,f)=>{}) {}

  final class InTag() : AsyncTag!(delegate bool (Tag x) {
    auto p = x.ambient.getParentAmbient();
    if(p is null) return false;
    auto t = x.ambient.getParentAmbient.findChildByName(cast(ProcessName)x.lemma.getName);
    createTag!(_LeaveTag!p)(x.lemma,x.ambient);
    createTag!(_EnterTag!t)(x.lemma,x.ambient);
    return true;
  },delegate void(Tag x,bool f) {
    // clear the intag entry
  }) {
  }

  final class OutTag() : AsyncTag!(delegate bool(Tag x){
    auto p = x.ambient.getParentAmbient();
    if(p is null) return false;
    auto t = p.getParentAmbient;
    if(t is null) return false;
    createTag!(_LeaveTag!p(x.lemma,x.ambient));
    createTag!(_EnterTag!t(x.lemma,x.ambient));
    return true;
  },delegate void (Tag x,bool f) {
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
   void removeTag(Tag t,bool f) {
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
    taskPool.put(a);
  }

  Tag _outTag = null;
  Tag[MobileAmbient] _inTags;
  Tag[] _otherTags;

  bool evaluate() {
    if(empty(_inTags) && _outTag is null && empty(_otherTags)) {
      return false;
    }
    foreach(a,tag ; _inTags) {
        tag.evaluate();
    }
    {
      Tag[MobileAmbient] x;
      _inTags = x;
    }
    if(_outTag) {
      _outTag.evaluate;
      _outTag = null;
    }
    foreach(t ; _otherTags) {
        t.evaluate();
    }
    _otherTags = [];
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

  // return true to halt evaluation and process tags...
  bool createTag(T : Tag)(Capability cap,MobileAmbient amb) {
    auto mk() {
      auto a = new T();
      a._lemma = cap;
      a._ambient = amb;
      return a;
    }
    /*_taskPool.put({
        /* amb.evol ~= a; * /
    });*/

    static if(T is OutTag) {
      if(amb !in _inTags) {
        _outTag = mk;
        return true;
      } else {
        return false;
      }
    }
    static if(T is InTag) {
      if(amb !in _inTags) {
        if(_outTag !is null && amb == _outTag._ambient) {
          return true;
        }
        _inTags[amb] = mk;
        return false;
      } else {
        return true;
      }
    }
    /*static if(T is _LeaveTag || T is _EnterTag) {
      mk.evaluate;
    }*/
    _otherTags ~= mk;
    return false;
  }

  // Single-threaded task pool
  private TaskPool _taskPool;

  this() {
    _taskPool = new TaskPool(1);
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
