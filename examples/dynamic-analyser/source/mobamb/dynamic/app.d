module mobamb.dynamic.app;

version(unittest) {
	//
} else {

	private import std.stdio;

	private import mobamb.amb;

	void main()	{
		//writeln("Edit source/app.d to start your project.");
		auto X = new NameLiteral("X");
		HostAmbient x = new HostAmbient(null,X);
		auto Y = new NameLiteral("Y");
		MobileAmbient y = new MobileAmbient(x,Y);
		scope(exit) x.close;
	}

}
