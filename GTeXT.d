//
//  GTeXT.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/04.
//
//	#このファイル:
//		GTeXTの本体ファイル。
//		今の所構造体をPDFに出力するコードだけが実装されている。
//
//	#(今実装されている)コードの流れ:
//		1.PDFを構成するオブジェクトが入った配列からオブジェクトを一つずつ取り出し、ファイルに書き出す。
//		2.この際、書き出した文字のバイト数を数えてsizeに足す。
//		3.すなわちsizeは先頭からその次のオブジェクトまでのバイト数を示す。
//		4.それぞれのオブジェクトまでのバイト数を、sizeをdistanceFromTop[]に格納することでメモる。(詳しくはoutputpdf()のコメント参照のこと)
//		5.最後にdistanceFromTop[]を用いて相互参照テーブルを作成する。
//
//

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.format;
import std.array;
import std.utf;

import pdfObjectClass;
import parser;

const string outputFile = "output.pdf";
pdfObject[] pdfObjects;
uint[] distanceFromTop;

void main(){

	parse();		//input.gtの解析
	construct();	//PDFの構造体を作る
	outputpdf();	//構造体を元に実際にPDFを書き出す
}


void outputpdf(){

	//上書き
	auto fout = File(outputFile,"w");

	//ヘッダ
	fout.writeln("%PDF-1.3");
	fout.write("%");
	fout.rawWrite([0xE2E3CFD3]); //バイナリファイルであることを明示
	fout.write("\n");

	//オブジェクトの書き出し
	for(uint i = 1;i < pdfObjects.length;i++){
		distanceFromTop ~= size;
		fout.writeln(to!string(i) ~ " 0 obj");
		fout.write(pdfObjects[i].outputText());
		fout.writeln("endobj");
		size += to!string(i).length + 14;
	}

	//相互参照テーブルの書き出し
	fout.writeln("xref");
	fout.writeln("0 " ~ to!string(pdfObjects.length));
	fout.writeln("0000000000 65535 f ");
	foreach(i;distanceFromTop){
		fout.writeln(rightJustify(to!string(i),10,'0') ~ " 00000 n ");
	}

	//フッタ
	fout.writeln("trailer");
	fout.writeln("<<");
	fout.writeln("/Size " ~ to!string(pdfObjects.length));
	fout.writeln("/Info 1 0 R");
	fout.writeln("/Root 2 0 R");
	fout.writeln(">>");
	fout.writeln("startxref");
	fout.writeln(to!string(size)); //相互参照テーブルまでのバイト数=全てのオブジェクトのバイト数の和
	fout.writeln("%%EOF");
}

void construct(){

	//0 0 objは空(プログラムの簡易化のために下駄を履かせた)
	pdfObjects ~= new pdfObject("null");
	
	//1 0 obj Info
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Title"),
								new pdfObject("str",title)
							),
							new pdfObject("recoad",
								new pdfObject("name","Author"),
								new pdfObject("str",author)
							),
							new pdfObject("recoad",
								new pdfObject("name","Creator"),
								new pdfObject("str","GTeXT")
							)
						])
					]);

	//2 0 obj Root
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Pages"),
								new pdfObject("refer",3)
							),
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Catalog")
							)
						])
					]);

	//3 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Pages")
							),
							new pdfObject("recoad",
								new pdfObject("name","Kids"),
								new pdfObject("array",[
									new pdfObject("refer",4)
								])
							),
							new pdfObject("recoad",
								new pdfObject("name","Count"),
								new pdfObject("number",1)
							)
						])
					]);

	//4 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Page")
							),
							new pdfObject("recoad",
								new pdfObject("name","Parent"),
								new pdfObject("refer",3)
							),
							new pdfObject("recoad",
								new pdfObject("name","Resources"),
								new pdfObject("refer",5)
							),
							new pdfObject("recoad",
								new pdfObject("name","MediaBox"),
								new pdfObject("array",[
									new pdfObject("number",paperSize[0]),
									new pdfObject("number",paperSize[1]),
									new pdfObject("number",paperSize[2]),
									new pdfObject("number",paperSize[3])
								])
							),
							new pdfObject("recoad",
								new pdfObject("name","Contents"),
								new pdfObject("refer",8)
							)
						])
					]);
	//5 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Font"),
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","F0"),
										new pdfObject("dictionary",[
											new pdfObject("recoad",
												new pdfObject("name","Type"),
												new pdfObject("name","Font")
											),
											new pdfObject("recoad",
												new pdfObject("name","BaseFont"),
												new pdfObject("name","KozGoPr6N-Medium")
											),
											new pdfObject("recoad",
												new pdfObject("name","Subtype"),
												new pdfObject("name","Type0")
											),
											new pdfObject("recoad",
												new pdfObject("name","Encoding"),
												new pdfObject("name","Identity-H")
											),
											new pdfObject("recoad",
												new pdfObject("name","DescendantFonts"),
												new pdfObject("array",[
													new pdfObject("refer",6)
												])
											)
										])
									)
								])
							)
						])
					]);
	//6 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Font")
							),
							new pdfObject("recoad",
								new pdfObject("name","Subtype"),
								new pdfObject("name","CIDFontType0")
							),
							new pdfObject("recoad",
								new pdfObject("name","BaseFont"),
								new pdfObject("name","KozGoPr6N-Medium")
							),
							new pdfObject("recoad",
								new pdfObject("name","CIDSystemInfo"),
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","Registry"),
										new pdfObject("str","Adobe")
									),
									new pdfObject("recoad",
										new pdfObject("name","Ordering"),
										new pdfObject("str","Japan1")
									),
									new pdfObject("recoad",
										new pdfObject("name","Supplement"),
										new pdfObject("number",6)
									)
								])
							),
							new pdfObject("recoad",
								new pdfObject("name","FontDescriptor"),
								new pdfObject("refer",7)
							)
						])
					]);
	//7 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","FontDescriptor")
							),
							new pdfObject("recoad",
								new pdfObject("name","FontName"),
								new pdfObject("name","KozGoPr6N-Medium")
							),
							new pdfObject("recoad",
								new pdfObject("name","Flags"),
								new pdfObject("number",4)
							),
							new pdfObject("recoad",
								new pdfObject("name","FontBBox"),
								new pdfObject("array",[
									new pdfObject("number",-437),
									new pdfObject("number",-340),
									new pdfObject("number",1147),
									new pdfObject("number",1317)
								])
							),
							new pdfObject("recoad",
								new pdfObject("name","ItalicAngle"),
								new pdfObject("number",0)
							),
							new pdfObject("recoad",
								new pdfObject("name","Ascent"),
								new pdfObject("number",1317)
							),
							new pdfObject("recoad",
								new pdfObject("name","Descent"),
								new pdfObject("number",-349)
							),
							new pdfObject("recoad",
								new pdfObject("name","CapHeight"),
								new pdfObject("number",742)
							),
							new pdfObject("recoad",
								new pdfObject("name","StemV"),
								new pdfObject("number",80)
							)
						])
					]);
	//8 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Length"),
								new pdfObject("number",streamBuff.length)
							)
						]),
						new pdfObject("stream",streamBuff)
					]);



}

string[string] argumentAnalyzer(string in0){

	if(indexOf(in0,":") == -1){
		return ["_default_":in0];
	}


	string[string] argument;

	string keyBuff;
	string valueBuff;

	const bool readKey = false;
	const bool readValue = true;
	bool mode = readKey;

	foreach(str; in0){
		if(str == ':'){
			mode = readValue;
		}else if(str == ','){
			mode = readKey;

			argument[keyBuff] = valueBuff;
			keyBuff = "";
			valueBuff = "";

		}else if(str == ' '){
			continue; //スペースは無視する
		}else{
			if(mode == readKey){
				keyBuff ~= str;
			}else{
				valueBuff ~= str;
			}
		}
	}
	argument[keyBuff] = valueBuff; //最後には","がないので別途記述

	return argument;

}

int mmTOpt(int in0){
	return to!int(in0 * 2.834);
}


