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
import core.vararg;
import std.conv;
import std.string;

uint size = 15;
const string outputFile = "output.pdf";
pdfObject[] pdfObjects;
uint[] distanceFromTop;

//pdfを表現する構造体の定義
class pdfObject{
	string type;

	pdfObject key;
	pdfObject value;

	pdfObject[] dictionary;

	pdfObject[] array;

	string stream;

	int number;

	string name;

	string str;

	pdfObject[] object;

	uint refer;


	this(string in0,...){
		type = in0;
		switch(type){
			case "recoad":
				key = va_arg!pdfObject(_argptr);
				value = va_arg!pdfObject(_argptr);
				break;
			case "dictionary":
				dictionary = va_arg!(pdfObject[])(_argptr);
				break;
			case "array":
				array = va_arg!(pdfObject[])(_argptr);
				break;
			case "stream":
				stream = va_arg!string(_argptr);
				break;
			case "number":
				number = va_arg!int(_argptr);
				break;
			case "name":
				name = va_arg!string(_argptr);
				break;
			case "str":
				str = va_arg!string(_argptr);
				break;
			case "object":
				object = va_arg!(pdfObject[])(_argptr);
				break;
			case "refer":
				refer = va_arg!uint(_argptr);
				break;
			case "null":
				break;
			default:
				writeln("error!");
				break;
		}
	}

	string outputText(){
		switch(type){
			case "recoad":
				return key.outputText() ~ " " ~ value.outputText();
				break;
			case "dictionary":
				string outputstr = "<<\n";
				foreach(obj;dictionary){
					outputstr ~= obj.outputText() ~ "\n";
				}
				outputstr ~= ">>\n";
				return outputstr;
				break;
			case "array":
				string outputstr = "[ ";
				foreach(obj;array){
					outputstr ~= obj.outputText() ~ " ";
				}
				outputstr ~= "]";
				return outputstr;
				break;
			case "stream":
				return "stream\n" ~ stream ~ "endstream\n";
				break;
			case "number":
				return to!string(number);
				break;
			case "name":
				return "/" ~ name;
				break;
			case "str":
				return "<" ~ str ~ ">";
				break;
			case "object":
				string outputstr;
				foreach(obj;object[]){
					outputstr ~= obj.outputText();
				}
				size += outputstr.length;
				return outputstr;
				break;
			case "refer":
				return to!string(refer) ~ " 0 R";
				break;
			case "null":
				return "";
				break;
			default:
				break;
		}
		return "error:" ~ type;
	}
	
}

void makePDFobjects(){

	//デバッグを素早く行うため入力ファイル名はあらかじめ記入しておいた
	string inputFile = "input.gt";

	auto fin = File(inputFile,"r");

	//PDFのメタ情報を格納する変数
	string title;
	string author;

	string line;
	string[] command;

	bool mathMode = false;
	bool subcommandMode = false;

	string subcommand;

	while(!fin.eof){
		line = fin.readln.chomp;	//.chompで改行コードを除去
		if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				//コマンド行
				line = line[2 .. $];
				command = line.split(" ");
				switch(command[0]){
					case "title":
						title = command[1];
						break;
					case "author":
						author = command[1];
						break;
					default:
				}
			}
		}
	}


	//テスト用にPDFのオブジェクトを手動で追加した
	//0 0 objは空(プログラムの簡易化のために下駄を履かせた)
	pdfObjects ~= new pdfObject("null");

	//1 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Pages"),
								new pdfObject("refer",2)
							),
							new pdfObject("recoad",
								new pdfObject("name","Type"),
								new pdfObject("name","Catalog")
							)
						])
					]);

	//2 0 obj
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

	//3 0 obj
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
												new pdfObject("name","Times-Roman")
											),
											new pdfObject("recoad",
												new pdfObject("name","Subtype"),
												new pdfObject("name","Type1")
											)
										])
									)
								])
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
								new pdfObject("refer",2)
							),
							new pdfObject("recoad",
								new pdfObject("name","Resources"),
								new pdfObject("refer",3)
							),
							new pdfObject("recoad",
								new pdfObject("name","MediaBox"),
								new pdfObject("array",[
									new pdfObject("number",0),
									new pdfObject("number",0),
									new pdfObject("number",595),
									new pdfObject("number",842)
								])
							),
							new pdfObject("recoad",
								new pdfObject("name","Contents"),
								new pdfObject("refer",5)
							)
						])
					]);

	//ファイル読み込みのシーカーを頭に戻す
	fin.rewind();
	string content =	"1. 0. 0. 1. 50. 720. cm\n"
						~ "BT\n"
						~ "/F0 36 Tf\n"
						~ "(";


		;
	while(!fin.eof){
		line = fin.readln.chomp;
		//コマンド行もしくは空行であればスキップ
		if(line.length == 0){
			//空行はパラグラフ変更である
			content ~= "\n";
			continue;
		}else if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				continue;
			}
		}
		content ~= line;
	}

	content		~= ") Tj \n"
				~ "ET\n";

	//5 0 obj
	pdfObjects ~=	new pdfObject("object",[
						new pdfObject("dictionary",[
							new pdfObject("recoad",
								new pdfObject("name","Length"),
								new pdfObject("number",content.length)
							)
						]),
						new pdfObject("stream",content)
					]);



}


void main(){

	makePDFobjects();
	//PDF書き出し
	outputpdf();
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
	fout.writeln("/Root 1 0 R");
	fout.writeln(">>");
	fout.writeln("startxref");
	fout.writeln(to!string(size)); //相互参照テーブルまでのバイト数=全てのオブジェクトのバイト数の和
	fout.writeln("%%EOF");
}

