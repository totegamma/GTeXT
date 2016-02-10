//
//  parser.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/04.
//
//	#このファイル:
//		パーサーだけをじっくり作るために試験的に別のファイルに記述している。
//		完成したら本体とマージする予定
//
//	#コードの流れ:
//		1.入力ファイルからプリコマンド行だけを抽出し処理。この際本文は無視する。
//		2.入力ファイルから本文だけを抽出。この際プリコマンド行は無視する。
//		3.本文から数式を抽出(数式は"[]"内に記述)。
//		4.本文からコマンドを抽出。
//
//	#なぜプリコマンドと本文で解析の実行タイミングを分けるのか
//		A.プリコマンド行では本文をPDFに変換するのに必要な情報(例えば用紙サイズやフォントなど)を指定するため、
//			先に全てのプリコマンド行を捜査するため。
//


import std.stdio;
import std.string;
import std.regex;
import std.conv;

int[4][string] paperSizeDictionary;



struct sentence{
	string type;
	string content;
	this(string in0, string in1){
		type = in0;
		content = in1;
	}
}

void main(){

	//デバッグを素早く行うため入力ファイル名はあらかじめ記入しておいた
	string inputFile = "input.gt";

	auto fin = File(inputFile,"r");

	//PDFの生成に必要な要素(これを集めるのが目的)
	string title = "noname";
	string author = "anonymous";
	sentence[] sentences;
	int[4] paperSize = [0, 0, 595, 842]; //a4
	int[4] padding = [28, 28, 28, 28]; //10mmのパディング
	int fontsize = 20;


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
									writeln(argDict);
									if("_default_" in argDict){
										paperSize = paperSizeDictionary[argDict["_default_"]];
									}else{
										paperSize = [0,0,to!int(argDict["width"]),to!int(argDict["height"])];
									}
									break;
								case "padding":
									if("_default_" in argDict){
										int pad = to!int(argDict["_default_"]);
										padding = [pad,pad,pad,pad];
									}else{
										padding = [to!int(argDict["left"]),to!int(argDict["right"]),to!int(argDict["down"]),to!int(argDict["up"])];
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

	//デバッグのため出力
	writeln("title: " ~ title);
	writeln("author: " ~ author);
	writeln(paperSize);
	writeln(padding);

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
						buff = "";
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

	writeln("---[result]----");
	writeln(sentences.length);
	foreach(elem;sentences){
		writeln(elem.type ~ ": " ~ elem.content);
	}

	writeln("---[stream]---");
	writeln("1. 0. 0. 1. " ~ to!string(padding[0]) ~ ". " ~ to!string(paperSize[3] - padding[3] - fontsize) ~ ". cm");
	writeln("BT");
	writeln("/F0 " ~ to!string(fontsize) ~ " Tf");
	writeln( to!string(fontsize + 4) ~ " TL");

	string stringbuff;
	foreach(elem;sentences){
		if(elem.type == "normal"){
			stringbuff ~= elem.content;
		}else if(elem.type == "command" && elem.content == "newparagraph"){
			writeln("(" ~ stringbuff ~ ") Tj T*");
			stringbuff = "";
		}
	}

	writeln("ET");

}


string[string] argumentAnalyzer(string in0){

	if(indexOf(in0,",") == -1){
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
