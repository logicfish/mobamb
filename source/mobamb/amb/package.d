module mobamb.amb;

debug {
  import std.experimental.logger;
}

private import mobamb.amb.domain;

final class PIChannel : Channel {
    const(Name) _name;

    bool _inputAvailable = false;
    Capability inputCap = null;
    OnInput onInput = null;

    @property {
      bool inputAvailable() @safe nothrow pure const {
        return _inputAvailable;
      }
      typeof(this) inputAvailable(bool b) @safe nothrow pure {
        _inputAvailable = b;
        return this;
      }
      const(Name) name() @safe nothrow pure const {
        return _name;
      }
    }
    bool matches(const(Name) n)const {
        return name.matches(n);
    }

    bool output(Capability o) {
        if(inputAvailable) return false;
        debug(Types) {
          sharedLog.info("channel output ",o);
        }
        synchronized(this) {
            if(onInput!=null) {
                onInput(o);
                onInput = null;
            } else {
                inputAvailable = true;
                inputCap = o;
            }
        }
        return true;
    }

    bool input(OnInput o) {
        debug(Types) {
          sharedLog.info("PIchannel input ",o);
        }
        synchronized(this) {
            if(inputAvailable==true) {
                o(inputCap);
                inputCap=null;
                inputAvailable = false;
            } else {
                if(onInput !is null) return false;
                onInput = o;
            }
            return true;
        }
    }
    this(const(Name) n) {
        _name = n;
    }
};
