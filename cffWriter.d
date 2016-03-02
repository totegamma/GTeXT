import std.stdio;
import std.conv;
import std.array;
import std.format;

ubyte[] binary;

string fontName = "hogeFont";
auto writer = appender!string();

void main(){
	//HEAD
	binary ~= [01,00,04,02];
	//NAME INDEX
	binary ~= [00,01,01,01];
	binary ~= fontName.length & 0b11111111;
	foreach(chr;fontName){
		writer = appender!string();
		formattedWrite(writer,"%02x",chr);
		binary ~= to!ubyte(writer.data,16);
	}
	//TOP DICT INDEX

	//STRING INDEX
	//GLOBAL SUBR INDEX

	writeln(binary);

}
