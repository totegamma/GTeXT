import std.stdio;
import std.conv;
import std.format;
import std.array;

void main(){
	writeln("ファイル識別子: " ~ array2string(trim(0,4)));
	int numOfTable = array2uint(trim(4,2));
	writeln("テーブルの数: " ~ to!string(numOfTable));
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4));
		uint checkSum	= array2uint(trim(16 +16*i, 4));
		uint offset		= array2uint(trim(20 +16*i, 4));
		uint dataLength = array2uint(trim(24 +16*i, 4));
		writeln("テーブル名: " ~ tag);
		writeln("\tチェックサム: " ~ to!string(checkSum));
		writeln("\tオフセット: " ~ to!string(offset));
		writeln("\tデータ長: " ~ to!string(dataLength));
		
		switch(tag){
			case "cmap":
				writeln("\t#version: " ~ to!string(array2uint(trim(offset,2))));
				uint numTables = array2uint(trim(offset+2,2));
				writeln("\t#numTables: " ~ to!string(numTables));
				for(int j; j<numTables; j++){
					writeln("\t-=-=-=-=-=-=-=-=-=[#" ~ to!string(j) ~ "]");
					writeln("\t##platformID: " ~ to!string(array2uint(trim(offset+4 +8*j,2))));
					writeln("\t##encodingID: " ~ to!string(array2uint(trim(offset+6 +8*j,2))));
					uint tableOffset = array2uint(trim(offset+8 +8*j,4));
					writeln("\t##offset: " ~ to!string(tableOffset));
					writeln("\t\t#format: " ~ to!string(array2uint(trim(offset + tableOffset,2))));
				}
				
				break;
			case "hhea":
				writeln("\t#version: " ~ to!string(array2uint(trim(offset,4))));
				writeln("\t#Ascender: " ~ to!string(array2uint(trim(offset+4,2))));
				writeln("\t#Descender: " ~ to!string(array2uint(trim(offset+6,2))));
				writeln("\t#LineGap: " ~ to!string(array2uint(trim(offset+8,2))));
				writeln("\t#advanceWidthMax: " ~ to!string(array2uint(trim(offset+10,2))));
				writeln("\t#minLeftSideBearing: " ~ to!string(array2uint(trim(offset+12,2))));
				writeln("\t#minRightSideBearing: " ~ to!string(array2uint(trim(offset+14,2))));
				writeln("\t#xMaxExtent: " ~ to!string(array2uint(trim(offset+16,2))));
				writeln("\t#caretSlopeRise: " ~ to!string(array2uint(trim(offset+18,2))));
				writeln("\t#caretSlopeRun: " ~ to!string(array2uint(trim(offset+20,2))));
				writeln("\t#caretOffset: " ~ to!string(array2uint(trim(offset+22,2))));
				writeln("\t#metricDataFormat: " ~ to!string(array2uint(trim(offset+32,2))));
				writeln("\t#numberOfHMetrics: " ~ to!string(array2uint(trim(offset+34,2))));
				break;
			default:
				break;
		}
		
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
