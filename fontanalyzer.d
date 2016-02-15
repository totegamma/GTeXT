import std.stdio;
import std.conv;

void main(){
	writeln(trim(0,4));
}

string trim(int from,int length){
	auto fin = File("resources/fonts/KozGoPr6N-Medium.otf","rb");
	ubyte buffer[] = new ubyte[length];
	fin.seek(from);
	fin.rawRead(buffer);
	return to!string(buffer);
}
