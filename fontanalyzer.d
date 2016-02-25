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
	//writeln("ファイル識別子: " ~ array2string(trim(0,4)));
	int numOfTable = array2uint(trim(4,2));
	uint numberOfHMetrics;
	//writeln("テーブルの数: " ~ to!string(numOfTable));
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4));
		uint checkSum	= array2uint(trim(16 +16*i, 4));
		uint offset		= array2uint(trim(20 +16*i, 4));
		uint dataLength = array2uint(trim(24 +16*i, 4));
		/*
		writeln("テーブル名: " ~ tag);
		writeln("\tチェックサム: " ~ to!string(checkSum));
		writeln("\tオフセット: " ~ to!string(offset));
		writeln("\tデータ長: " ~ to!string(dataLength));
		*/
		switch(tag){
			case "head":
				
				//writeln("\t#version: " ~			to!string(array2uint(trim(offset,4))));
				//writeln("\t#fontRevision: " ~		to!string(array2uint(trim(offset+4,4))));
				//writeln("\tcheckSumAdjustment: " ~	to!string(array2uint(trim(offset+8,4))));
				//writeln("\t#magicNumber: " ~		to!string(array2uint(trim(offset+12,4))));
				//writeln("\t#flags: " ~				to!string(array2uint(trim(offset+16,2))));
				//writeln("\t#unitsPerEm: " ~			to!string(array2uint(trim(offset+18,2))));
				unitsPerEm = array2short(trim(offset+18,2));
				//writeln("\t#created: " ~			to!string(array2ulong(trim(offset+20,8))));
				//writeln("\t#modified: " ~			to!string(array2ulong(trim(offset+28,8))));
				//writeln("\t#xMin: " ~				to!string(array2short(trim(offset+36,2))));
				xMin = array2short(trim(offset+36,2));
				//writeln("\t#yMin: " ~				to!string(array2short(trim(offset+38,2))));
				yMin = array2short(trim(offset+38,2));
				//writeln("\t#xMax: " ~				to!string(array2short(trim(offset+40,2))));
				xMax = array2short(trim(offset+40,2));
				//writeln("\t#yMax: " ~				to!string(array2short(trim(offset+42,2))));
				yMax = array2short(trim(offset+42,2));
				//writeln("\t#macStyle: " ~			to!string(array2uint(trim(offset+44,2))));
				//writeln("\t#lowestRecPPEM: " ~		to!string(array2uint(trim(offset+46,2))));
				//writeln("\t#fontDirectionHint: " ~	to!string(array2short(trim(offset+48,2))));
				//writeln("\t#indexToLocFormat: " ~	to!string(array2short(trim(offset+50,2))));
				//writeln("\t#glyphDataFormat: " ~	to!string(array2short(trim(offset+52,2))));
				
				break;
			case "cmap":
				//writeln("\t#version: " ~			to!string(array2uint(trim(offset,2))));
				uint numTables =							  array2uint(trim(offset+2,2));
				//writeln("\t#numTables: " ~ to!string(numTables));
				for(int j; j<numTables; j++){
					//writeln("\t-=-=-=-=-=-=-=-=-=[#" ~ to!string(j) ~ "]");
					//writeln("\t##platformID: " ~	to!string(array2uint(trim(offset+4 +8*j,2))));
					uint encodingID = array2uint(trim(offset+6 +8*j,2));
					//writeln("\t##encodingID: " ~	to!string(encodingID));
					uint tableOffset =						  array2uint(trim(offset+8 +8*j,4));
					//writeln("\t##offset: " ~ to!string(tableOffset));
					uint format = array2uint(trim(offset + tableOffset,2));
					//writeln("\t\t#format: " ~		to!string(format));
					if (format == 2){
						/*
						writeln("\t\t#length: " ~ to!string(array2uint(trim(offset + tableOffset+2,2))));
						writeln("\t\t#language: " ~ to!string(array2uint(trim(offset + tableOffset+4,2))));
						for(int k; k<256; k++){
							write("\t\t#subHeaderKeys(");
							writef("%02x",k);
							writeln("): " ~ to!string(array2uint(trim(offset + tableOffset+6 +2*k,2))/8));
						}
						*/
					}else if(format == 4 && encodingID == 1){
						//writeln("\t\t#length: " ~ to!string(array2uint(trim(offset + tableOffset+2,2))));
						//writeln("\t\t#language: " ~ to!string(array2uint(trim(offset + tableOffset+4,2))));
						uint segCount = array2uint(trim(offset + tableOffset+6,2))/2;
						/*
						writeln("\t\t#segCount: " ~ to!string(segCount));
						writeln("\t\t#searchRange: " ~ to!string(array2uint(trim(offset + tableOffset+8,2))));
						writeln("\t\t#entrySelector: " ~ to!string(array2uint(trim(offset + tableOffset+10,2))));
						writeln("\t\t#rangeShift: " ~ to!string(array2uint(trim(offset + tableOffset+12,2))));
						*/
						uint endCount[];
						for(int k; k<segCount; k++){
							//writeln("\t\t#endCount: " ~ to!string(array2uint(trim(offset + tableOffset+14 +2*k,2))));
							endCount ~= array2uint(trim(offset + tableOffset+14 +2*k,2));
						}
						//writeln("\t\t#reservedPad: " ~ to!string(array2uint(trim(offset +tableOffset +14 +segCount*2,2))));
						uint startCount[];
						for(int k; k<segCount; k++){
							//writeln("\t\t#startCount: " ~ to!string(array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2))));
							startCount ~= array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2));
						}
						uint idDelta[];
						for(int k; k<segCount; k++){
							//writeln("\t\t#startCount: " ~ to!string(array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2))));
							idDelta ~= array2uint(trim(offset + tableOffset+14 + segCount*4 +2 +2*k,2));
						}
						uint idRangeOffset[];
						for(int k; k<segCount; k++){
							//writeln("\t\t#startCount: " ~ to!string(array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2))));
							idRangeOffset ~= array2uint(trim(offset + tableOffset+14 + segCount*6 +2 +2*k,2));
						}

						for(int k; k<segCount; k++){
							int pointer;
							//writeln("start: " ~ to!string(startCount[k]) ~ " end: " ~ to!string(endCount[k]));
							for(uint l = startCount[k]; l<= endCount[k]; l++){
								//writef("%04x ",l);
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
						//writeln(charCodeToGlyphId);
					}
				}
				
				break;
			case "hhea":
				
				//writeln("\t#version: " ~			to!string(array2uint(trim(offset,4))));
				//writeln("\t#Ascender: " ~			to!string(array2uint(trim(offset+4,2))));
				ascender = array2short(trim(offset+4,2));
				//writeln("\t#Descender: " ~			to!string(array2short(trim(offset+6,2))));
				descender = array2short(trim(offset+6,2));
				//writeln("\t#LineGap: " ~			to!string(array2uint(trim(offset+8,2))));
				lineGap = array2short(trim(offset+8,2));
				//writeln("\t#advanceWidthMax: " ~	to!string(array2uint(trim(offset+10,2))));
				//writeln("\t#minLeftSideBearing: " ~ to!string(array2uint(trim(offset+12,2))));
				//writeln("\t#minRightSideBearing: "~ to!string(array2uint(trim(offset+14,2))));
				//writeln("\t#xMaxExtent: " ~			to!string(array2uint(trim(offset+16,2))));
				//writeln("\t#caretSlopeRise: " ~		to!string(array2uint(trim(offset+18,2))));
				//writeln("\t#caretSlopeRun: " ~		to!string(array2uint(trim(offset+20,2))));
				//writeln("\t#caretOffset: " ~		to!string(array2uint(trim(offset+22,2))));
				//writeln("\t#metricDataFormat: " ~	to!string(array2uint(trim(offset+32,2))));
				//writeln("\t#numberOfHMetrics: " ~	to!string(array2uint(trim(offset+34,2))));
				
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
	/*
	string bo = "消えろ！消えろ！つかの間の灯火！Life's but a walking shadow, a poor player.";
	//writeln(advanceWidth[charCodeToGlyphId[0x65e5]]);
	auto writer = appender!string();
	foreach(c; array(bo)) {
		foreach(b; [c].toUTF16) {
			formattedWrite(writer,"%04x",b);
		}
		writeln(advanceWidth[charCodeToGlyphId[to!int(writer.data,16)]]);
		writer = appender!string();
	}
	*/
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
	//writeln(writer.data);
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
