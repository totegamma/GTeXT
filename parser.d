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


void main(){

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
			continue;
		}else if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				continue;
			}
		}

		//1文字ずつ処理する
		foreach(str;line){
			if(subcommandMode == true){
				if(match(to!string(str),r"[a-z]|[A-Z]")){
					subcommand ~= str;
				}else{
					write("!subcommand: " ~ subcommand ~ "!");
					subcommand = "";
					subcommandMode = false;

					if(str == '['){
						if(mathMode == true){
							writeln("error! \"[\"in[]");
						}else{
							write("!mathModein!");
							mathMode = true;
						}
					}
				}
			}else{
				switch(str){
					case '[':
						if(mathMode == true){
							writeln("error! \"[\"in[]");
						}else{
							write("!mathModein!");
							mathMode = true;
						}
						break;
					case ']':
						if(mathMode == true){
							mathMode = false;
							write("!mathModeout!");
						}else{
							writeln("error! \"[\"in[]");

						}
						break;
					case '#':
						subcommandMode = true;
						break;
					default:
						write(str);
				}
			}
		}
		write("\n");
	}


}
