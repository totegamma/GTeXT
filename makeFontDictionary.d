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
import std.string;
import std.file;
import std.path;

void main(){
	auto fout = File("fontDictionary","w");
	foreach (string name; dirEntries("/Library/Fonts", SpanMode.depth)){
		if(name[$-4..$] == ".otf" || name[$-4..$] == ".ttf"){
			fout.writeln(getFontName(name) ~ ";" ~ name);
		}
	}	
	foreach (string name; dirEntries(expandTilde("~/Library/Fonts"), SpanMode.depth)){
		if(name[$-4..$] == ".otf" || name[$-4..$] == ".ttf"){
			fout.writeln(getFontName(name) ~ ";" ~ name);
		}
	}
}

string getFontName(string filename){
	int numOfTable = array2uint(trim(4,2, filename));
	uint numberOfHMetrics;
	string fontName;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4, filename));
		uint checkSum	= array2uint(trim(16 +16*i, 4, filename));
		uint offset		= array2uint(trim(20 +16*i, 4, filename));
		uint dataLength = array2uint(trim(24 +16*i, 4, filename));
		if(tag == "name"){
			uint count = array2uint(trim(offset + 2,2, filename));
			uint stringOffset = array2uint(trim(offset + 4,2, filename));
			for(int j; j < count; j++){
				uint length = array2uint(trim(offset + 14 +12*j, 2, filename));
				uint stringOffsetOffset = array2uint(trim(offset + 16 +12*j, 2, filename));
				if(array2uint(trim(offset + 12 +12*j, 2, filename)) == 4){
					fontName = translate(array2string(trim(offset +stringOffset +stringOffsetOffset ,length, filename)),[' ' : '_']);
					break;
				}
			}
		}
	}
	return fontName;
}

ubyte[] trim(int from,int length,string filename){
	auto fin = File(filename,"rb");
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
