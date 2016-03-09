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

struct fontInfo{
	string fontName;
	string fontPath;
	string subtype;		//e.g. Type0
	string cidSubtype;	//e.g. CIDFontType0
	string encoding;	//e.g. Identity-H
	string baseFont;	//e.g. KozGoPr6N-Medium
	string registry;	//e.g. Adobe
	string ordering;	//e.g. Japan1
	int supplement;		//e.g. 6
	int flags;		//e.g. 4
	int[4] fontBBox;
	int italicangle;	//e.g. 0
	int ascent;
	int descender;
	int[] W;
	int WD;

	uint[uint] charCodeToGlyphId;
	short unitsPerEm;
	short lineGap;
	uint[] advanceWidth;
	widthCidStruct[] widthCidMapping;
}

fontInfo[] fonts;

struct widthCidStruct{
	uint cid;
	uint width;
}


void addNewFont(string fileName){

	string fontPath;
	string subtype = "Type0";		//e.g. Type0
	string cidSubtype = "CIDFontType0";	//e.g. CIDFontType0
	string encoding = "Identity-H";	//e.g. Identity-H
	string baseFont = fileName;	//e.g. KozGoPr6N-Medium
	string registry = "Adobe";	//e.g. Adobe
	string ordering = "Japan1";	//e.g. Japan1
	int supplement = 6;		//e.g. 6
	int flags = 4; 		//e.g. 4
	int[4] fontBBox;
	int italicangle = 0;	//e.g. 0
	int ascent;
	int descender;
	int[] W;
	int WD = 1000;

	uint[uint] charCodeToGlyphId;
	short unitsPerEm;
	short lineGap;
	uint[] advanceWidth;
	widthCidStruct[] widthCidMapping;

	//パスを入手
	auto fin = File("fontDictionary","r");
	string line;
	while(!fin.eof){
		line = fin.readln.chomp;
		string[] dataPair = line.split(';');
		if(dataPair.length >= 2){
			if(dataPair[0] == fileName){
				fontPath = dataPair[1];
				break;
			}
		}
	}
	if(fontPath == ""){
		writeln("error!: font not found.");
	}

	int numOfTable = array2uint(trim(4,2,fontPath));
	uint numberOfHMetrics;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4,fontPath));
		uint checkSum	= array2uint(trim(16 +16*i, 4,fontPath));
		uint offset		= array2uint(trim(20 +16*i, 4,fontPath));
		uint dataLength = array2uint(trim(24 +16*i, 4,fontPath));
		switch(tag){
			case "head":
				unitsPerEm = array2short(trim(offset+18,2,fontPath));
				fontBBox[0] = array2short(trim(offset+36,2,fontPath));
				fontBBox[0] = array2short(trim(offset+38,2,fontPath));
				fontBBox[0] = array2short(trim(offset+40,2,fontPath));
				fontBBox[0] = array2short(trim(offset+42,2,fontPath));
				break;
			case "cmap":
				uint numTables =							  array2uint(trim(offset+2,2,fontPath));
				for(int j; j<numTables; j++){
					uint encodingID = array2uint(trim(offset+6 +8*j,2,fontPath));
					uint tableOffset =						  array2uint(trim(offset+8 +8*j,4,fontPath));
					uint format = array2uint(trim(offset + tableOffset,2,fontPath));
					if (format == 2){
					}else if(format == 4 && encodingID == 1){
						uint segCount = array2uint(trim(offset + tableOffset+6,2,fontPath))/2;
						uint endCount[];
						for(int k; k<segCount; k++){
							endCount ~= array2uint(trim(offset + tableOffset+14 +2*k,2,fontPath));
						}
						uint startCount[];
						for(int k; k<segCount; k++){
							startCount ~= array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2,fontPath));
						}
						uint idDelta[];
						for(int k; k<segCount; k++){
							idDelta ~= array2uint(trim(offset + tableOffset+14 + segCount*4 +2 +2*k,2,fontPath));
						}
						uint idRangeOffset[];
						for(int k; k<segCount; k++){
							idRangeOffset ~= array2uint(trim(offset + tableOffset+14 + segCount*6 +2 +2*k,2,fontPath));
						}
						for(int k; k<segCount; k++){
							int pointer;
							for(uint l = startCount[k]; l<= endCount[k]; l++){
								if(idRangeOffset[k] == 0){
									charCodeToGlyphId[l] = (l+idDelta[k])%65536;
								}else{
									uint glyphOffset = offset +tableOffset+16 +segCount*8
														+((idRangeOffset[k]/2)+(l-startCount[k])+(k-segCount))*2;
									uint glyphIndex = array2uint(trim(glyphOffset,2,fontPath));
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
				ascent = array2short(trim(offset+4,2,fontPath));
				descender = array2short(trim(offset+6,2,fontPath));
				lineGap = array2short(trim(offset+8,2,fontPath));
				numberOfHMetrics = array2uint(trim(offset+34,2,fontPath));
				break;
			case "hmtx":
				for(int j; j< numberOfHMetrics; j++){
					advanceWidth ~= array2uint(trim(offset+4*j,2,fontPath));
				}
				break;
			default:
				break;
		}
	}


	fonts ~= fontInfo(	fileName, 
						fontPath, 
						subtype, 
						cidSubtype, 
						encoding, 
						fileName, 
						registry, 
						ordering, 
						supplement, 
						flags, 
						fontBBox, 
						italicangle, 
						ascent, 
						descender, 
						W, 
						WD,
						charCodeToGlyphId,
						unitsPerEm,
						lineGap,
						advanceWidth,
						widthCidMapping);


}


uint getAdvanceWidth(string in0,uint fontid){
	auto writer = appender!string();
	auto chr = array(in0)[0];

	//writeln(fonts[fontid].advanceWidth);

	return fonts[fontid].advanceWidth[fonts[fontid].charCodeToGlyphId[[chr].toUTF16[0]]];
}

ubyte[] trim(int from,int length,string filePath){
	auto fin = File(filePath,"rb");
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
