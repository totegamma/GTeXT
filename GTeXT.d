//
//  GTeXT.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/04.
//
//	#このファイル:
//		GTeXTの本体ファイル。(の予定)
//		今は、PDFの構造体を組み立てるコードと、それを実際にファイルとして書き出すコードが実装されている。
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
uint[] distanceFromTop;

//###関数 main
//
//エントリポイント。何書くのが定石なのかわからん。
//
void main(){

	writeln("GTeXT 0.0.0");

//	addNewFont("KozGoPr6N-Medium","CID");
//	addNewFont("XITSMath","MATH");

	parse();		//input.gtの解析
	construct();	//PDFの構造体を作る
	outputpdf();	//構造体を元に実際にPDFを書き出す

}

//###関数 outputpdf
//
//pdfObjects[]に格納されたPdfオブジェクトを読み込んで、実際にPDFファイルにして書き出す関数。
//
void outputpdf(){

	writeln("PDFを出力しています");

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

	writeln("お待たせしました！PDFの出力が完了しました");
}

//関数 construct
//
//様々な情報をまとめてPDFオブジェクトとしてpdfObjects[]に格納する。
//
//入力(グローバル)
//parser.title
//parser.author
//parser.paperSize[]
//fontanalyzer.fonts[]
//
//出力(グローバル)
//pdfObjectClass.pdfObjects[]
//

void construct(){

	writeln("PDFの構造体を作っています");

	//0 0 objは空(プログラムの簡易化のために下駄を履かせた)
	pdfObjects ~= new pdfObject("null");
	
	//1 0 obj Info
	pdfObjects ~=	new pdfObject("object", "info", 0, [
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
	pdfObjects ~=	new pdfObject("object", "root", 0, [
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Pages"),
								new pdfObject("refer","page",0)
							),
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Catalog")
							)
						])
					]);

	//3 0 obj
	pdfObjects ~=	new pdfObject("object", "pages", 0, [
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Pages")
							),
							new pdfObject("recoad",
								new pdfObject("name","Kids"),
								new pdfObject("refarray","page")
							),
							new pdfObject("recoad",
								new pdfObject("name","Count"),
								new pdfObject("number",1)
							)
						])
					]);

	//4 0 obj
	pdfObjects ~=	new pdfObject("object", "page", 0, [
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Page")
							),
							new pdfObject("recoad",
								new pdfObject("name","Parent"),
								new pdfObject("refer","pages",0)
							),
							new pdfObject("recoad",
								new pdfObject("name","Resources"),
								new pdfObject("refer","resources",0)
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
								new pdfObject("refer","content",0)
							)
						])
					]);

	pdfObject fontList = new pdfObject("dictionary",[]);
	foreach(i, font; fonts){
		fontList.dictionary ~=	new pdfObject("recoad",
									new pdfObject("name","F" ~ to!string(i)),
									new pdfObject("refer","font",i)
							);
	}
	//5 0 obj
	pdfObjects ~=	new pdfObject("object", "resources", 0, [
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Font"),
								fontList
							)
						])
					]);


	foreach(i, font; fonts){
		//--ここからフォント項目
		if(font.fontType == "CID"){
			pdfObjects ~=	new pdfObject("object", "font", i, [
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","Type"),
										new pdfObject("name","Font")
									),
									new pdfObject("recoad",
										new pdfObject("name","BaseFont"),
										new pdfObject("name",font.baseFont)
									),
									new pdfObject("recoad",
										new pdfObject("name","Subtype"),
										new pdfObject("name",font.subtype)
									),
									new pdfObject("recoad",
										new pdfObject("name","Encoding"),
										new pdfObject("name",font.encoding)
									),
									new pdfObject("recoad",
										new pdfObject("name","DescendantFonts"),
										new pdfObject("array",[
											new pdfObject("refer","decendantFonts",i)
										])
									)
								])
							]);

			pdfObject Wentry = new pdfObject("array",[]);
			//writeln(font.W);
			foreach(Welem;font.W){
				Wentry.array ~= new pdfObject("number",Welem);
			}

			//6 0 obj
			pdfObjects ~=	new pdfObject("object", "decendantFonts", i, [
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","Type"),
										new pdfObject("name","Font")
									),
									new pdfObject("recoad",
										new pdfObject("name","Subtype"),
										new pdfObject("name",font.cidSubtype)
									),
									new pdfObject("recoad",
										new pdfObject("name","BaseFont"),
										new pdfObject("name",font.baseFont)
									),
									new pdfObject("recoad",
										new pdfObject("name","CIDSystemInfo"),
										new pdfObject("dictionary",[
											new pdfObject("recoad",
												new pdfObject("name","Registry"),
												new pdfObject("str",font.registry)
											),
											new pdfObject("recoad",
												new pdfObject("name","Ordering"),
												new pdfObject("str",font.ordering)
											),
											new pdfObject("recoad",
												new pdfObject("name","Supplement"),
												new pdfObject("number",font.supplement)
											)
										])
									),
									new pdfObject("recoad",
										new pdfObject("name","FontDescriptor"),
										new pdfObject("refer","fontDescriptor",i)
									),
									new pdfObject("recoad",
										new pdfObject("name","W"),
										Wentry
									),
									new pdfObject("recoad",
										new pdfObject("name","DW"),
										new pdfObject("number",font.WD)
									)
								])
							]);
			//7 0 obj
			pdfObjects ~=	new pdfObject("object", "fontDescriptor", i, [
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","Type"),
										new pdfObject("name","FontDescriptor")
									),
									new pdfObject("recoad",
										new pdfObject("name","FontName"),
										new pdfObject("name",font.baseFont)
									),
									new pdfObject("recoad",
										new pdfObject("name","Flags"),
										new pdfObject("number",font.flags)
									),
									new pdfObject("recoad",
										new pdfObject("name","FontBBox"),
										new pdfObject("array",[
											new pdfObject("number",to!int(font.fontBBox[0])),
											new pdfObject("number",to!int(font.fontBBox[1])),
											new pdfObject("number",to!int(font.fontBBox[2])),
											new pdfObject("number",to!int(font.fontBBox[3]))
										])
									),
									new pdfObject("recoad",
										new pdfObject("name","ItalicAngle"),
										new pdfObject("number",font.italicangle)
									),
									new pdfObject("recoad",
										new pdfObject("name","Ascent"),
										new pdfObject("number",to!int(font.ascent))
									),
									new pdfObject("recoad",
										new pdfObject("name","Descent"),
										new pdfObject("number",to!int(font.descender))
									)/*	//本当は必須項目　だが、入手するのが大変....
									new pdfObject("recoad",
										new pdfObject("name","CapHeight"),
										new pdfObject("number",742)
									),
									new pdfObject("recoad",
										new pdfObject("name","StemV"),
										new pdfObject("number",80)
									)
									*/
								])
							]);
		}else{
			pdfObjects ~=	new pdfObject("object", "font", i, [
								new pdfObject("dictionary",[
									new pdfObject("recoad",
										new pdfObject("name","Type"),
										new pdfObject("name","Font")
									),
									new pdfObject("recoad",
										new pdfObject("name","BaseFont"),
										new pdfObject("name",font.baseFont)
									),
									new pdfObject("recoad",
										new pdfObject("name","Subtype"),
										new pdfObject("name","Type1")
									)
								])
							]);

		}
	}



	//-----------------------------フォント項目ここまで

	//8 0 obj
	pdfObjects ~=	new pdfObject("object", "content", 0, [
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Length"),
								new pdfObject("number",streamBuff.length)
							)
						]),
						new pdfObject("stream",streamBuff)
					]);
}


//関数 argumentAnalyzer
//
//stringで表現された引数表現を連想配列に変換する
//入力形式は"key:value,key:value"
//また、keyが与えられず、"value"だけ与えられた場合はkeyが_default_と言う値で要素が一つだけ格納される。
//
//入力(引数)
//string in0		解析する前の文字列(e.g. "width:300, height:500")
//出力(戻り値)
//string[string]	鍵と値の連想配列(e.g. width->300, height->500)
//

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

//関数 mmTOpt
//
//mmで入力された数値をptに単位換算する
//
//入力(引数)
//int in0
//出力(戻り値)
//int
int mmTOpt(int in0){
	return to!int(in0 * 2.834);
}


