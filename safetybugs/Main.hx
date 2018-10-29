package safetybugs;

using Safety;

class IntHolder {
    public var v : Int;

    public function new(v : Int) {
        this.v = v;
    }

    public inline function inlineCopy() : IntHolder {
        return new IntHolder(v);
    }
}

class NullableStringHolder {
    public var s : Null<String>;

    public function new(s : Null<String>) {
        // safeApi generates non-null check (for more details see Bug14)
        this.s = s;
    }
}

class TypedHolder<T> {
    public var v : T;

    public function new(v : T) {
        // safeApi generates non-null check, even is T is Null<...> (for more details see Bug14)
        this.v = v;
    }
}

class SomeClass {
    public function new() {}
}

class Bug1 {
    public function bug() : Void {
        // Arrays of mixed types are only allowed if the type is forced to Array<Dynamic>
        // Bug in "safeArray"
        ["A", 1];
    }
}

class Bug2 {
    public function bug(?v : haxe.Int32) : Void {
        // Safety: Cannot cast nullable value to not nullable type.
        v == null ? "A" : "B";
    }
}

class Bug3 {
    public function bug() : Void {
        var s : Null<String> = ((Math.random() > 0.5) ? "A" : null);

        if (s != null) {
            // Safety: Cannot access "length" of a nullable value.
            function cb() : Int { return s.length; }
        }
    }
}

class MaybeBug4 {
    public function bug() : Void {
        var h : Null<IntHolder> = ((Math.random() > 0.5) ? new IntHolder(42) : null);

        // Is it possible to show `Safety: Cannot access "inlineCopy" of a nullable value.`
        // instead of `Safety: Cannot access "v" of a nullable value.`?
        function cb() : IntHolder { return h.inlineCopy(); }
    }
}

class Bug5 {
    private var v : Int;

    public function new() {
        v = 42;

        // Safety: Cannot use "this" until all instance fields are initialized.
        function cb() : Int { return v; }
    }
}

class NotABugButProposal6 {
    private var s : Null<String>;

    public function proposal() : Void {
        s = ((Math.random() > 0.5) ? "A" : null);

        if (s != null) {
            // Safety: Cannot access "length" of a nullable value.
            // While it makes sense in case of multithreading, is it possible to add something like `@:safety(threadsafe)`?
            s.length;
        }
    }
}

class Bug7 {
    public function bug() : Void {
        var s : Null<String> = ((Math.random() > 0.5) ? "A" : null);

        if (s == null || s.length == 42) {
            return;
        }

        // Safety: Cannot access "length" of a nullable value.
        s.length;
    }
}

class Bug8 {
    // Safety: Field "v" is not nullable thus should have an initial value or should be initialized in constructor.
    public var v(get, never) : Int;

    public function get_v() : Int {
        return 42;
    }
}

class Bug9 {
    public function bug() : Void {
        var s : Null<String> = ((Math.random() > 0.5) ? "A" : null);

        if (s != null) {
            // Safety: Cannot unify safetybugs.TypedHolder<Null<String>> with safetybugs.TypedHolder<String>
            var h : TypedHolder<String> = new TypedHolder(s);
        }
    }
}

class NotABugButProposal10 {
    public function proposal() : Void {
        var h = new NullableStringHolder((Math.random() > 0.5) ? "A" : null);

        if (h.s != null) {
            // Safety: Cannot access "length" of a nullable value.
            // While it makes sense in case of multithreading, is it possible to add something like `@:safety(threadsafe)`?
            h.s.length;
        }
    }
}

class Bug11 {
    public function bug(a : Null<String>, b : Null<String>) : Void {
        if (a == null || b == null) {
            return;
        }

        // Safety: Cannot access "length" of a nullable value.
        // Probably, variation of Bug7
        a.length + b.length;
    }
}

class MaybeBug12 {
    public function bug() : Void {
        var a = new SomeClass();

        // Safety: Cannot cast nullable value to not nullable type.
        // Probably this is not a bug in Safety, and this issue related to Std.instance() signature
        var b : Null<SomeClass> = Std.instance(a, SomeClass);
    }
}

class Bug13 {
    public function bug() : Void {
        function cb() : Void {
            // Safety: Cannot assign nullable value to not-nullable variable.
            // Even with `cb.sure()` or `cb.unsafe()`
            js.Browser.window.setTimeout(cb, 1000);
        }
    }
}

class Bug14 {
    // Generated code (js target):
    //
    // bug: function(s) {
    //     var this1 = s;
    //     if(this1 == null) {
    //         throw new js__$Boot_HaxeError(new safety_IllegalArgumentException("Null is not allowed for argument " + "s" + " in " + "safetybugs.Bug14" + "." + "bug" + "()"));
    //     }
    //     if(s != null) {
    //         haxe_Log.trace(s.length,{ fileName : "safetybugs/Main.hx", lineNumber : 206, className : "safetybugs.Bug14", methodName : "bug"});
    //     }
    // }
    //
    // `s` CAN be null, but safeApi still generates non-null check.

    public function bug(s : Null<String>) : Void {
        if (s != null) {
            trace(s.length);
        }
    }
}

class Main {
    public static function main() : Void {
    }
}
