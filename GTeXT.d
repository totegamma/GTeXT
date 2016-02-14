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
import std.regex;
import std.format;
import std.array;
import std.utf;

uint size = 15;
const string outputFile = "output.pdf";
pdfObject[] pdfObjects;
uint[] distanceFromTop;
int[4][string] paperSizeDictionary;

uint[uint] cmap;


//PDFの生成に必要な要素(これを集めるのが目的)
string title = "noname";
string author = "anonymous";
sentence[] sentences;
int[4] paperSize = [0, 0, 595, 842]; //a4
int[4] padding = [28, 28, 28, 28]; //10mmのパディング
int fontsize = 20;

struct sentence{
	string type;
	string content;
	this(string in0, string in1){
		type = in0;
		content = in1;
	}
}


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
				return "(" ~ str ~ ")";
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


void main(){

	loadcmap();
	parser();
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
	fout.writeln("/Info 1 0 R");
	fout.writeln("/Root 2 0 R");
	fout.writeln(">>");
	fout.writeln("startxref");
	fout.writeln(to!string(size)); //相互参照テーブルまでのバイト数=全てのオブジェクトのバイト数の和
	fout.writeln("%%EOF");
}

void parser(){

	//デバッグを素早く行うため入力ファイル名はあらかじめ記入しておいた
	string inputFile = "input.gt";

	auto fin = File(inputFile,"r");

	//解析に使う変数
	string line;
	string currentmode = "normal";
	string buff;
	string precommand;
	string argument;

	bool beforeArgument = true;

	paperSizeDictionary = ["a4":[0,0,595,842]];


	while(!fin.eof){
		line = fin.readln.chomp;	//.chompで改行コードを除去
		if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				//コマンド行
				line = line[2 .. $];
				foreach(str; line){
					if(beforeArgument == true){
						if(str == '('){
							beforeArgument = false;
						}else{
							precommand ~= str;
						}
					}else{
						if(str == ')'){
							auto argDict = argumentAnalyzer(argument);
							switch(precommand){
								case "title":
									title = argDict["_default_"];
									break;
								case "author":
									author = argDict["_default_"];
									break;
								case "paperSize":
									if("_default_" in argDict){
										paperSize = paperSizeDictionary[argDict["_default_"]];
									}else{
										paperSize = [0,0,to!int(argDict["width"]),to!int(argDict["height"])];
									}
									break;
								case "padding":
									if("_default_" in argDict){
										int pad = mmTOpt(to!int(argDict["_default_"]));
										padding = [pad,pad,pad,pad];
									}else{
										padding = [mmTOpt(to!int(argDict["left"])),mmTOpt(to!int(argDict["right"])),mmTOpt(to!int(argDict["down"])),mmTOpt(to!int(argDict["up"]))];
									}
									break;
								default:
									writeln("Error! unknown precommand: " ~ precommand);
									break;
							}
							precommand = "";
							argument = "";
							beforeArgument = true;
						}else{
							argument ~= str;
						}
					}
				}
			}
		}
	}
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
												new pdfObject("name","KozMinPro6N-Regular")
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
								new pdfObject("name","KozMinPr6N-Regular")
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
								new pdfObject("name","KozMinPr6N-Regular")
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
	

//--------------------------------------------------------------



	//ファイル読み込みのシーカーを頭に戻す
	fin.rewind();

	while(!fin.eof){
		line = fin.readln.chomp;
		//コマンド行もしくは空行であればスキップ
		if(line.length == 0){
			//空行はパラグラフ変更である
			if(buff != ""){
				sentences ~= sentence("normal",buff);
				buff = "";
			}
			sentences ~= sentence("command","newparagraph");
			continue;
		}else if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				continue;
			}
		}

		//1文字ずつ処理する
		foreach(str;line){
			switch(currentmode){
				case "normal":
					if(str == '#'){
						if(buff != ""){
							sentences ~= sentence("normal",buff);
							buff = "";
						}
						currentmode = "command";
					}else if(str == '['){
						if(buff != ""){
							sentences ~= sentence("normal",buff);
							buff = "";
						}
						currentmode = "math";
					}else{
						buff ~= str;
					}
					break;
				case "command":
					if(str == '['){
						sentences ~= sentence("command",buff);
						buff = "";
						currentmode = "math";
					}else if(str == ' '){
						sentences ~= sentence("command",buff);
						buff = " ";
						currentmode = "normal";
					}else{
						buff ~= str;
					}
					break;
				case "math":
					if(str == ']'){
						sentences ~= sentence("math",buff);
						buff = "";
						currentmode = "normal";
					}else{
						buff ~= str;
					}
					break;
				default:
					break;
			}
		}
		if(currentmode == "command"){
			sentences ~= sentence("command",buff);
			buff = "";
			currentmode = "normal";
		}
	}
	if(buff != "")sentences ~= sentence(currentmode,buff);
	buff = "";
	currentmode = "normal";

	string streamBuff;

	streamBuff ~= "1. 0. 0. 1. " ~ to!string(padding[0]) ~ ". " ~ to!string(paperSize[3] - padding[3] - fontsize) ~ ". cm\n";
	streamBuff ~= "BT\n";
	streamBuff ~= "/F0 " ~ to!string(fontsize) ~ " Tf\n";
	streamBuff ~= to!string(fontsize + 4) ~ " TL\n";

	string stringbuff;
	uint width;
	foreach(elem;sentences){
		if(elem.type == "normal"){
			foreach(str;array(elem.content)){
				width += fontsize;
				if(width > paperSize[2] - padding[0] - padding[1]){
					streamBuff ~= "<" ~ string2cid(stringbuff) ~ "> Tj T*\n";
					stringbuff = "";
					width = 0;
					stringbuff ~= str;
				}else{
					stringbuff ~= str;
				}
			}
			

		}else if(elem.type == "command"){
			switch(elem.content){
				case "newparagraph":
					streamBuff ~= "<" ~ string2cid(stringbuff) ~ "> Tj T*\n";
					stringbuff = "";
					width = 0;
					break;
				case "pi":
					stringbuff ~= "π";
				default:
					break;
			}
		}
	}

	streamBuff ~= "ET\n";

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

string string2cid(string in0){
	if(in0 == ""){
		return "";
	}
	auto writer = appender!string();
	string output;
	foreach(c; array(in0)) {
		foreach(b; [c].toUTF8) {
			formattedWrite(writer,"%x",b);
		}
	uint unicode = to!uint(writer.data,16);
	writer = appender!string();
	formattedWrite(writer,"%x",cmap[unicode]);
	//writeln(rightJustify(writer.data,4,'0'));
	output ~= rightJustify(writer.data,4,'0');
	writer = appender!string();
	}
	return output;
}

void loadcmap(){
	string line;
	string[] sentences;
	bool loadChar = false;
	bool loadRange = false;

	auto fin = File("resources/cmap/UniJIS2004-UTF8-H.txt","r");
	while(!fin.eof){
		line = fin.readln.chomp;
		if(loadChar == false && loadRange == false){
			if(indexOf(line,"begincidchar") != -1){
				loadChar = true;
			}else if(indexOf(line, "begincidrange") != -1){
				loadRange = true;
			}
		}else if(loadChar == true){
			if(line == "endcidchar"){
				loadChar = false;
				continue;
			}
			sentences = split(line," ");
			string uni = sentences[0][1..$-1];
			string cid = sentences[1];
			cmap[to!uint(uni,16)] = to!uint(cid);
		}else if(loadRange == true){
			if(line == "endcidrange"){
				loadRange = false;
				continue;
			}
			sentences = split(line," ");
			string rangeStartStr = sentences[0][1..$-1];
			string rangeEndStr = sentences[1][1..$-1];
			uint rangeStart = parse!uint(rangeStartStr,16);
			uint rangeEnd = parse!uint(rangeEndStr,16);
			uint cidStart = parse!uint(sentences[2]);
			for(; rangeStart <= rangeEnd; rangeStart++){
				cmap[rangeStart] = cidStart;
				cidStart ++;
			}
		}
	}
}
