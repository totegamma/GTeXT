import std.stdio;
import std.conv;

void main(){

	auto fin = File("resources/fonts/KozGoPr6N-Medium.otf","rb");

	char headerID[4] = new char[4];
	fin.rawRead(headerID);
	writeln("ファイル識別子: " ~ to!string(headerID));

	ushort numOfTable[1] = new ushort[1];
	fin.rawRead(numOfTable);
	writeln("テーブルの数: " ~ to!string(numOfTable));
	writeln(numOfTable.length);
	foreach(b;numOfTable){
		writef("%02x",b);
	}
	writeln("");

	fin.seek(12);
	char tableName[4] = new char[4];
	fin.rawRead(tableName);
	writeln("テーブルの名前: " ~ to!string(tableName));
	
	uint tableInfo[3] = new uint[3];
	fin.rawRead(tableInfo);
	writeln("チェックサム: " ~ to!string(tableInfo[0]));
	writef("%02x",tableInfo[0]);
	writeln("オフセット: " ~ to!string(tableInfo[1]));
	writeln("データ長: " ~ to!string(tableInfo[2]));


	/*
	foreach (b;data)
		writef("%02x ",b);
	writeln("");
	*/



}
