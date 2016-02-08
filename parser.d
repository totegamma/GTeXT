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
//		1.入力ファイルからコマンド行だけを抽出し処理。この際本文は無視する。
//		2.入力ファイルから本文だけを抽出。この際コマンド行は無視する。
//		3.本文から数式を抽出(数式は"[]"内に記述)。
//		4.本文からサブコマンドを抽出。
//
//	#なぜコマンドと本文で実行タイミングを分けるのか
//		A.コマンド行では本文をPDFに変換するのに必要な情報(例えば用紙サイズやフォントなど)を指定するため、
//			先に全てのコマンド行を捜査するため。
//


import std.stdio;
import std.string;
import std.regex;
import std.conv;

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

	//PDFのメタ情報を格納する変数
	string title;
	string author;

	string line;
	string[] command;

	string currentmode = "normal";
	string buff;

	bool mathMode = false;
	bool subcommandMode = false;

	string subcommand;

	sentence[] sentences;

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

	//デバッグのため出力
	writeln("title: " ~ title);
	writeln("author: " ~ author);

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
			write(str);
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

	writeln("--[result]----");
	writeln(sentences.length);
	foreach(elem;sentences){
		writeln(elem.type ~ ": " ~ elem.content);
	}


}
