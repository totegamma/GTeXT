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

class fontInfo{
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

//関数 addNewFont
//
//与えられたフォント名のフォント情報を読み込み、fonts[]に格納する。
//
//入力(引数)
//string fileName
//出力(グローバル)
//fonts[]
//

void addNewFont(string fileName){

	fontInfo newFont = new fontInfo;

	newFont.subtype = "Type0";		//e.g. Type0
	newFont.cidSubtype = "CIDFontType0";	//e.g. CIDFontType0
	newFont.encoding = "Identity-H";	//e.g. Identity-H
	newFont.baseFont = fileName;	//e.g. KozGoPr6N-Medium
	newFont.registry = "Adobe";	//e.g. Adobe
	newFont.ordering = "Japan1";	//e.g. Japan1
	newFont.supplement = 6;		//e.g. 6
	newFont.flags = 4; 		//e.g. 4
	newFont.italicangle = 0;	//e.g. 0
	newFont.WD = 1000;

	//パスを入手
	auto fin = File("fontDictionary","r");
	string line;
	while(!fin.eof){
		line = fin.readln.chomp;
		string[] dataPair = line.split(';');
		if(dataPair.length >= 2){
			if(dataPair[0] == fileName){
				newFont.fontPath = dataPair[1];
				break;
			}
		}
	}
	if(newFont.fontPath == ""){
		writeln("error!: font not found.(" ~ fileName ~ ")");
	}

	newFont.fontName = fileName;

	int numOfTable = array2uint(trim(4,2,newFont.fontPath));
	uint numberOfHMetrics;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4,newFont.fontPath));
		uint checkSum	= array2uint(trim(16 +16*i, 4,newFont.fontPath));
		uint offset		= array2uint(trim(20 +16*i, 4,newFont.fontPath));
		uint dataLength = array2uint(trim(24 +16*i, 4,newFont.fontPath));
		switch(tag){
			case "head":
				newFont.unitsPerEm = array2short(trim(offset+18,2,newFont.fontPath));
				newFont.fontBBox[0] = array2short(trim(offset+36,2,newFont.fontPath));
				newFont.fontBBox[1] = array2short(trim(offset+38,2,newFont.fontPath));
				newFont.fontBBox[2] = array2short(trim(offset+40,2,newFont.fontPath));
				newFont.fontBBox[3] = array2short(trim(offset+42,2,newFont.fontPath));
				break;
			case "cmap":
				uint numTables =							  array2uint(trim(offset+2,2,newFont.fontPath));
				for(int j; j<numTables; j++){
					uint encodingID = array2uint(trim(offset+6 +8*j,2,newFont.fontPath));
					uint tableOffset =						  array2uint(trim(offset+8 +8*j,4,newFont.fontPath));
					uint format = array2uint(trim(offset + tableOffset,2,newFont.fontPath));
					if (format == 2){
					}else if(format == 4 && encodingID == 1){
						uint segCount = array2uint(trim(offset + tableOffset+6,2,newFont.fontPath))/2;
						uint endCount[];
						for(int k; k<segCount; k++){
							endCount ~= array2uint(trim(offset + tableOffset+14 +2*k,2,newFont.fontPath));
						}
						uint startCount[];
						for(int k; k<segCount; k++){
							startCount ~= array2uint(trim(offset + tableOffset+14 + segCount*2 +2 +2*k,2,newFont.fontPath));
						}
						uint idDelta[];
						for(int k; k<segCount; k++){
							idDelta ~= array2uint(trim(offset + tableOffset+14 + segCount*4 +2 +2*k,2,newFont.fontPath));
						}
						uint idRangeOffset[];
						for(int k; k<segCount; k++){
							idRangeOffset ~= array2uint(trim(offset + tableOffset+14 + segCount*6 +2 +2*k,2,newFont.fontPath));
						}
						for(int k; k<segCount; k++){
							int pointer;
							for(uint l = startCount[k]; l<= endCount[k]; l++){
								if(idRangeOffset[k] == 0){
									newFont.charCodeToGlyphId[l] = (l+idDelta[k])%65536;
								}else{
									uint glyphOffset = offset +tableOffset+16 +segCount*8
														+((idRangeOffset[k]/2)+(l-startCount[k])+(k-segCount))*2;
									uint glyphIndex = array2uint(trim(glyphOffset,2,newFont.fontPath));
									if(glyphIndex != 0){
										glyphIndex += idDelta[k];
										glyphIndex %= 65536;
										newFont.charCodeToGlyphId[l] = glyphIndex;
									}
								}
							}
						}
						newFont.charCodeToGlyphId.rehash;
					}
				}
				
				break;
			case "hhea":
				newFont.ascent = array2short(trim(offset+4,2,newFont.fontPath));
				newFont.descender = array2short(trim(offset+6,2,newFont.fontPath));
				newFont.lineGap = array2short(trim(offset+8,2,newFont.fontPath));
				numberOfHMetrics = array2uint(trim(offset+34,2,newFont.fontPath));
				break;
			case "hmtx":
				for(int j; j< numberOfHMetrics; j++){
					newFont.advanceWidth ~= array2uint(trim(offset+4*j,2,newFont.fontPath));
				}
				break;
			default:
				break;
		}
	}
	fonts ~= newFont;
}

//関数 getAdvanceWidth
//
//指定されたフォントにおける、指定された文字の送り幅(AdvanceWidth)を取得し、返す。
//
//入力(引数)
//string in0	文字1文字
//uint fontid	フォントID
//入力(グローバル)
//fonts[]
//出力(戻り値)
//uint			フォントの送り幅
//

uint getAdvanceWidth(string in0,uint fontid){
	auto writer = appender!string();
	auto chr = array(in0)[0];

	return fonts[fontid].advanceWidth[fonts[fontid].charCodeToGlyphId[[chr].toUTF16[0]]];
}


//関数 trim
//
//指定されたパスにあるファイルの指定された区間のバイナリを読み取り返す。
//
//入力(引数)
//int offset		くり抜く区間までのバイトオフセット
//int length		くり抜く区間の長さ
//string filePath	くり抜くファイルのパス
//出力(戻り値)
//ubyte[]			くりぬかれたファイルのバイナリ
//

ubyte[] trim(int offset,int length,string filePath){
	auto fin = File(filePath,"rb");
	ubyte buffer[] = new ubyte[length];
	fin.seek(offset);
	fin.rawRead(buffer);
	return buffer;
}

//イカ、類似してるのでまとめます
//
//入力(引数)
//ubyte[] in0	バイナリ入力
//出力(戻り値)
//変換されたバイナリ(詳しいのはそれぞれに書く)

//バイナリを数値(short)へ
short array2short(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!ushort(writer.data,16);
}

//バイナリを数値(uint)へ
uint array2uint(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!uint(writer.data,16);
}

//バイナリを数値(ulong)へ
ulong array2ulong(ubyte[] in0){
	auto writer = appender!string();
	foreach(elem;in0){
		formattedWrite(writer,"%02x",elem);
	}
	return to!ulong(writer.data,16);
}

//バイナリを文字列へ
string array2string(ubyte[] in0){
	string output;
	foreach(elem;in0){
		char buf = elem;
		output ~= to!string(buf);
	}
	return output;
}

//これらのナイフを使ってバイナリを解剖する。
//プログラミング全然できないのでバイナリファイルの正しい読み方がわからないから、
//こんなクソコードになってます。アーメン
//「こうしたらいいよ！」って言うのがあったらぜひとも教えてください。お待ちしてます。
