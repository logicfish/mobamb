module mobamb.amb.tag;

private import std.algorithm,
    std.parallelism;

private import mobamb.amb.domain;


interface Tag {
  alias Apply = bool delegate();
  alias Close = void delegate(bool);
  Capability lemma();  // the definition that proves the existence of the tag.
}

class TagPool {
  class _Tag(_exec : Tag.Apply, _close : Tag.Close) : Tag {
    void _execute() {
        removeTag(this,_exec());
    }
    void execute() {
        _taskPool.put(&_execute);
    }
    this() {
    }
  }

  final class _EnterTag() : _Tag!({
    // _exec function for _enter.
    return true;
  },f=>{}) {}

  final class _LeaveTag()  : _Tag!({
    // _exec function for _leave.
    return true;
  },f=>{}) {}

  final class _InputTag() : _Tag!({
    // _exec function for _input.
    return true;
  },f=>{}) {}

  final class _OutputTag() : _Tag!({
    // _exec function for _output.
    return true;
  },f=>{}) {}

  final class _ConstructorTag : _Tag!({
    return true;
  },f=>{}) {}

// Tags hashed by the source process name.
  Tag[] tags;

   void addTag(Tag t) {
     tags ~= t;
   }
   void
  void removeTag(Tag t,bool f) {
    tags = tags.remove!(a=>t == a);
    t.source.removeTarget(t);
    t.target.removeSource(t);
    _close(f);
  }
  auto createTag(Tag.Apply a,Tag.Close c)() {
    return new _Tag!(a,c);
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
