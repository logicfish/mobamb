module mobamb.dynamic.app;

version(unittest) {
	//
} else {

	private import std.stdio;

	private import mobamb.amb;

	void main()	{
		//writeln("Edit source/app.d to start your project.");
		HostAmbient x = new HostAmbient;
		MobileAmbient y = new MobileAmbient(x);
	}

}