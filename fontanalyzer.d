import std.stdio;
import std.conv;
import std.format;
import std.array;

void main(){
	ubyte[4] a = trim(0,4);
	writeln(array2uint(a));
	writeln(array2string(a));
}

ubyte[] trim(int from,int length){
	auto fin = File("resources/fonts/KozGoPr6N-Medium.otf","rb");
	ubyte buffer[] = new ubyte[length];
	fin.seek(from);
	fin.rawRead(buffer);
	return buffer;
}

uint array2uint(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%x",elem);
	}
	return to!uint(writer.data,16);
}

string array2string(ubyte[] in0){
	string output;
	foreach(elem;in0){
		char buf = elem;
		output ~= to!string(buf);
	}
	return output;
}
