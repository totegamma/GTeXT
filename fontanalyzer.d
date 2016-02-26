//
//  fontanalyzer.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/22.
//
//	#このファイル:
//		フォントファイルを解析し、様々な情報を得る。
//		今の所head,cmap,hhea,htmxテーブルを読み込むことができる。
//		また、cmapテーブルに於いてはformat4のみ、実装されている。
//
module fontanalyzer;
import std.stdio;
import std.conv;
import std.format;
import std.array;
import std.utf;
import std.string;

uint[uint] charCodeToGlyphId;

uint[] advanceWidth;
short unitsPerEm;
short xMin;
short yMin;
short xMax;
short yMax;
short ascender;
short descender;
short lineGap;


void makeFontMapping(){
	int numOfTable = array2uint(trim(4,2));
	uint numberOfHMetrics;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4));
		uint checkSum	= array2uint(trim(16 +16*i, 4));
		uint offset		= array2uint(trim(20 +16*i, 4));
		uint dataLength = array2uint(trim(24 +16*i, 4));
		switch(tag){
			case "head":
				unitsPerEm = array2short(trim(offset+18,2));
				xMin = array2short(trim(offset+36,2));
				yMin = array2short(trim(offset+38,2));
				xMax = array2short(trim(offset+40,2));
				yMax = array2short(trim(offset+42,2));
				break;
			case "cmap":
				uint numTables =							  array2uint(trim(offset+2,2));
				for(int j; j<numTables; j++){
					uint encodingID = array2uint(trim(offset+6 +8*j,2));
					uint tableOffset =						  array2uint(trim(offset+8 +8*j,4));
					uint format = array2uint(trim(offset + tableOffset,2));
					if (format == 2){
					}else if(format == 4 && encodingID == 1){
						uint segCount = array2uint(trim(offset + tableOffset+6,2))/2;
						uint endCount[];
						for(int k; k<segCount; k++){
							endCount ~= array2uint(trim(offset + tableOffset+14 +2*k,2));
						}
						uint startCount[];
						for(int k; k<segCount; k++){
							startCount ~= array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2));
						}
						uint idDelta[];
						for(int k; k<segCount; k++){
							idDelta ~= array2uint(trim(offset + tableOffset+14 + segCount*4 +2 +2*k,2));
						}
						uint idRangeOffset[];
						for(int k; k<segCount; k++){
							idRangeOffset ~= array2uint(trim(offset + tableOffset+14 + segCount*6 +2 +2*k,2));
						}
						for(int k; k<segCount; k++){
							int pointer;
							for(uint l = startCount[k]; l<= endCount[k]; l++){
								if(idRangeOffset[k] == 0){
									charCodeToGlyphId[l] = (l+idDelta[k])%65536;
								}else{
									uint glyphOffset = offset +tableOffset+16 +segCount*8
														+((idRangeOffset[k]/2)+(l-startCount[k])+(k-segCount))*2;
									uint glyphIndex = array2uint(trim(glyphOffset,2));
									if(glyphIndex != 0){
										glyphIndex += idDelta[k];
										glyphIndex %= 65536;
										charCodeToGlyphId[l] = glyphIndex;
									}
								}
							}
						}
						charCodeToGlyphId.rehash;
					}
				}
				
				break;
			case "hhea":
				ascender = array2short(trim(offset+4,2));
				descender = array2short(trim(offset+6,2));
				lineGap = array2short(trim(offset+8,2));
				numberOfHMetrics = array2uint(trim(offset+34,2));
				break;
			case "hmtx":
				for(int j; j< numberOfHMetrics; j++){
					advanceWidth ~= array2uint(trim(offset+4*j,2));
				}
				break;
			default:
				break;
		}
	}
}

uint getAdvanceWidth(string in0){
	auto writer = appender!string();
	auto chr = array(in0)[0];
	return advanceWidth[charCodeToGlyphId[[chr].toUTF16[0]]];
}

ubyte[] trim(int from,int length){
	auto fin = File("resources/fonts/KozGoPr6N-Medium.otf","rb");
	ubyte buffer[] = new ubyte[length];
	fin.seek(from);
	fin.rawRead(buffer);
	return buffer;
}

short array2short(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!ushort(writer.data,16);
}

uint array2uint(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!uint(writer.data,16);
}

ulong array2ulong(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!ulong(writer.data,16);
}

string array2string(ubyte[] in0){
	string output;
	foreach(elem;in0){
		char buf = elem;
		output ~= to!string(buf);
	}
	return output;
}
