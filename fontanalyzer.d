import std.stdio;
import std.conv;
import std.format;
import std.array;

void main(){
	writeln("ファイル識別子: " ~ array2string(trim(0,4)));
	int numOfTable = array2uint(trim(4,2));
	writeln("テーブルの数: " ~ to!string(numOfTable));
	for(int i; i<numOfTable; i++){
		writeln("テーブル名: " ~ array2string(trim(12 +16*i, 4)));
		writeln("\tチェックサム: " ~ to!string(array2uint(trim(16 +16*i, 4))));
		writeln("\tオフセット: " ~ to!string(array2uint(trim(20 +16*i, 4))));
		writeln("\tデータ長: " ~ to!string(array2uint(trim(24 +16*i, 4))));
	}
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
