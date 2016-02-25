//
//  makeFontDictionary.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/25.
//
//	#このファイル:
//		フォントファイルを解析し、様々な情報を得る。
//		今の所head,cmap,hhea,htmxテーブルを読み込むことができる。
//		また、cmapテーブルに於いてはformat4のみ、実装されている。
//
import std.stdio;
import std.conv;
import std.format;
import std.array;
import std.utf;
import std.string;


void main(){
	int numOfTable = array2uint(trim(4,2));
	uint numberOfHMetrics;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4));
		uint checkSum	= array2uint(trim(16 +16*i, 4));
		uint offset		= array2uint(trim(20 +16*i, 4));
		uint dataLength = array2uint(trim(24 +16*i, 4));
		if(tag == "name"){
			uint count = array2uint(trim(offset + 2,2));
			uint stringOffset = array2uint(trim(offset + 4,2));
			for(int j; j < count; j++){
				uint length = array2uint(trim(offset + 14 +12*j, 2));
				uint stringOffsetOffset = array2uint(trim(offset + 16 +12*j, 2));
				if(array2uint(trim(offset + 12 +12*j, 2)) == 4){
					string fontName = translate(array2string(trim(offset +stringOffset +stringOffsetOffset ,length)),[' ' : '_']);
					writeln("fontName: " ~ fontName);
					break;
				}
			}
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
		formattedWrite(writer,"%02x",elem);
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
