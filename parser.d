//
//  parser.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/04.
//
//	#このファイル:
//		input.gtの構文を解析し、必要な要素を抽出し格納する。
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

module parser;

import std.stdio;
import std.string;
import std.regex;
import std.conv;
import std.array;
import std.format;
import std.utf;
import std.algorithm;

import loadcmap;
public import fontanalyzer;

int[4][string] paperSizeDictionary;

//PDFの生成に必要な要素(これを集めるのが目的)
//先に初期値を代入しておく。
string title = "noname";
string author = "anonymous";
sentence[] sentences;
int[4] paperSize = [0, 0, 595, 842]; //a4
int[4] padding = [28, 28, 28, 28]; //10mmのパディング
//int currentFontSize = 20;
uint pageWidth;
uint pageHeight;


//文章を要素ごとに分割する際、それを格納する構造体
struct sentence{
	string type;
	string content;
	string argument;
	this(string in0, string in1){
		type = in0;
		content = in1;
	}
}

struct style{
	uint fontSize;
	uint fontID;
	string fontAlign;
	string fontName;
}

style[] styleStack;	//範囲指定子が使うやつ
style[] styleList;	//自分で命名したstyleを保存するやつ

//行ごとのまとまり
class outputline{
	int nextGap;
	double lineWidth;
	uint maxFontSize;
	uint biggestFontFontID;
	string stream;
	string textAlign;
}
outputline[] outputlines;


class styleBlock{
	double x = 0;
	double y = 0;
	string content;
	style blockStyle;
	double blockWidth = 0;
}
styleBlock[] styleBlockList;


//関数 parse とその愉快な仲間たち
//
//input.gtを解析する。
//
//入力(ファイル)
//input.gt
//
//出力(グローバル)
//paperSize
//padding
//sentences
//
//コード・フロー
//
//input.gt -> sentences -> outputLines -> streamBuff

//# perseToSentences
//input.gt -> sentences
//
//sentences: コマンドごとの塊	<- コマンドを実行するために必要

//スタイルごとの塊が必要...? styleCluster
//なんなら行の高さ合わせも同時にやりたい感ある

//# encodeSentences
// sentences -> outputLines
//
//outputLines: 行ごとの塊		<- 行の高さを合わせるのに必要

//# createStream
// outputLines -> streamBuff
//streamBuff: 完成されたstream	<- これが欲しい

void parse(){

	//デバッグを素早く行うため入力ファイル名はあらかじめ記入しておいた
	string inputFile = "input.gt";

	//cmapファイルをの読み込み
	loadcmap.loadcmap();
	paperSizeDictionary = ["a4":[0,0,595,842]];		//TODO ここなんとかする

	writeln("本文の解析を開始します");

	perseToSentences(inputFile);
	//encodeSentences();
	makeStyleBlock();
	createStream();
	
}


void perseToSentences(string inputFileName){

	//解析に使う変数
	string line;
	string currentmode = "normal";
	bool beforeArgument = true;	//TODO 変数名の改善
	string precommand;
	string argument;
	string buff;				//TODO 変数名の改善

	auto fin = File(inputFileName,"r");
	writeln("プリコマンドを解析しています。");

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
									writeln("タイトル: " ~ title);
									break;
								case "author":
									author = argDict["_default_"];
									writeln("著者: " ~ author);
									break;
								case "paperSize":
									if("_default_" in argDict){
										writeln(argDict["_default_"] ~ "の紙の大きさを辞書から取得しています");
										paperSize = paperSizeDictionary[argDict["_default_"]];
										pageWidth = to!int(paperSize[2]);
										pageHeight= to!int(paperSize[3]);
										writeln("取得成功: " ~ to!string(pageWidth) ~ "x" ~ to!string(pageHeight));
									}else{
										pageWidth = to!int(argDict["width"]);
										pageHeight=to!int(argDict["height"]);
										writeln("ページサイズを手動で指定します(" ~ to!string(pageWidth) ~ "x" ~ to!string(pageHeight) ~ ")");
										paperSize = [0, 0, pageWidth, pageHeight];
									}
									break;
								case "padding":
									if("_default_" in argDict){
										int pad = to!int(argDict["_default_"]);
										padding = [pad,pad,pad,pad];
									}else{
										padding = [to!int(argDict["up"]),to!int(argDict["down"]),to!int(argDict["left"]),to!int(argDict["right"])];
									}
									writeln("パディングを設定します"
											~	"(天:" ~ to!string(padding[0])
											~ "mm 地:" ~ to!string(padding[1])
											~ "mm 左:" ~ to!string(padding[2])
											~ "mm 右:" ~ to!string(padding[3])
											~ "mm)");
									break;
								default:
									writeln("Error! 存在しないプリコマンド" ~ precommand);
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

	writeln("本文を解析しています");

	//ファイル読み込みのシーカーを頭に戻す
	fin.rewind();

	while(!fin.eof){ //一行ずつ読む
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
		}else if(line.length >= 2){ //プリコマンド行は無視する
			if(line[0 .. 2] == "#!"){
				continue;
			}
		}

		//1文字ずつ処理する
		foreach(str;line){
			switch(currentmode){
				case "normal":
					switch(str){
						case '#':
							if(buff != ""){
								sentences ~= sentence("normal",buff);
								buff = "";
							}
							currentmode = "command";
							break;
						case '[':
							if(buff != ""){
								sentences ~= sentence("normal",buff);
								buff = "";
							}
							currentmode = "math";
							break;
						case '{':
							sentences ~= sentence("normal",buff);
							buff = "";
							sentences ~= sentence("command","beginRange");
							break;
						case '}':
							sentences ~= sentence("normal",buff);
							buff = "";
							sentences ~= sentence("command","endRange");
							break;
						default:
							buff ~= str;
							break;
					}
					break;
				case "command":
					switch(str){
						case '[':
							sentences ~= sentence("command",buff);
							buff = "";
							currentmode = "math";
							break;
						case ' ':
							sentences ~= sentence("command",buff);
							buff = "";
							currentmode = "normal";
							break;
						case '(':
							sentences ~= sentence("command",buff);
							buff = "";
							currentmode = "argument";
							break;
						default:
							buff ~= str;
							break;
					}
					break;
				case "math":
					switch(str){
						case ']':
							sentences ~= sentence("math",buff);
							buff = "";
							currentmode = "normal";
							break;
						default:
							buff ~= str;
							break;
					}
					break;
				case "argument":
					switch(str){
						case ')':
							sentences[$-1].argument = buff;
							buff = "";
							currentmode = "normal";
							break;
						default:
							buff ~= str;
							break;
					}
					break;
				default:
					break;
			}
		}
		if(currentmode == "command"){	//Commandの入力は行末でも区切りになる
			sentences ~= sentence("command",buff);
			buff = "";
			currentmode = "normal";
		}
	}
	if(buff != "")sentences ~= sentence(currentmode,buff);
}

void makeStyleBlock(){

	styleBlock newStyleBlock = new styleBlock;
	double currentY = pageHeight - padding[3];
	style currentStyle = style(15,0,"left");
	styleBlock[] styleBlockByLine;
	
	double leftSpace = paperSize[2] - padding[0] - padding[1];

	void renewStyleBlock(){
		if(newStyleBlock.content == "")return;
		newStyleBlock.blockStyle = currentStyle;
		//現存のstyleBlockをLineに流し込み新しくする
		styleBlockByLine ~= newStyleBlock;
		newStyleBlock = new styleBlock;
	}

	void lineFeed(){

		renewStyleBlock();

		uint maxFontID;
		int maxFontSize;

		//その行のフォントサイズの最大値を求める
		foreach(elem; styleBlockByLine){
			if(elem.blockStyle.fontSize > maxFontSize){
				maxFontID = elem.blockStyle.fontID;
				maxFontSize = elem.blockStyle.fontSize;
			}
		}

		//シーカーをフォントサイズ分だけ下げる
		currentY -= maxFontSize + fonts[maxFontID].lineGap/fonts[maxFontID].unitsPerEm + 5;

		styleBlock[] leftAlignBlock;
		styleBlock[] centerAlignBlock;
		double centerAlignBlockWidth = 0;
		styleBlock[] rightAlignBlock;
		double rightAlignBlockWidth = 0;

		//寄せる位置ごとに分ける
		foreach(elem; styleBlockByLine){
			switch(elem.blockStyle.fontAlign){
				case "left":
					leftAlignBlock ~= elem;
					break;
				case "center":
					centerAlignBlock ~= elem;
					centerAlignBlockWidth += elem.blockWidth;
					break;
				case "right":
					rightAlignBlock ~= elem;
					rightAlignBlockWidth += elem.blockWidth;
					break;
				default:
					writeln("このメッセージは出ないはずだよ");
					break;
			}
		}

		//求めた位置をstyleBlockに登録する
		//左寄せ
		double currentX = padding[2];
		foreach(elem; leftAlignBlock){
			elem.x = currentX;
			elem.y = currentY;
			currentX += elem.blockWidth;
		}

		//中央寄せ
		currentX = (pageWidth - centerAlignBlockWidth)/2;
		foreach(elem; centerAlignBlock){
			elem.x = currentX;
			elem.y = currentY;
			currentX += elem.blockWidth;
		}

		//右寄せ
		currentX = pageWidth - rightAlignBlockWidth- padding[3];
		foreach(elem; rightAlignBlock){
			elem.x = currentX;
			elem.y = currentY;
			currentX += elem.blockWidth;
		}

		styleBlockList ~= styleBlockByLine;
		styleBlockByLine = null;
		leftSpace = paperSize[2] - padding[0] - padding[1];

	}


	foreach(elem; sentences){
		switch(elem.type){
			case "normal":
				foreach(str; array(elem.content)){ //1文字づつ取り出す

					//文字幅を取得する一連の†流れ†
					string cid = string2cid(to!string(str));
					uint ciduint = to!uint(cid,16);
					uint advanceWidth = getAdvanceWidth(to!string(str),currentStyle.fontID);
					newStyleBlock.blockWidth += to!double(currentStyle.fontSize)*to!double(advanceWidth)/to!double(fonts[currentStyle.fontID].unitsPerEm);

					if(leftSpace - to!double(currentStyle.fontSize)*to!double(advanceWidth)/to!double(fonts[currentStyle.fontID].unitsPerEm) < 0){
						lineFeed();
						leftSpace = paperSize[2] - padding[0] - padding[1];
					}

					leftSpace -= to!double(currentStyle.fontSize)*to!double(advanceWidth)/to!double(fonts[currentStyle.fontID].unitsPerEm);
					
					//styleBlockに文字を追加
					newStyleBlock.content ~= cid;

					bool flag = true;;
					foreach(a;fonts[currentStyle.fontID].widthCidMapping){
						if(a.cid == ciduint){
							flag = false;
							break;
						}
					}
					if(flag == true){
						fonts[currentStyle.fontID].widthCidMapping ~= widthCidStruct(ciduint,advanceWidth);
					}
				}
				break;
			case "math":
				break;
			case "command":
				switch(elem.content){
					case "beginRange":
						styleStack ~= currentStyle;
						break;

					case "endRange":
						renewStyleBlock();
						currentStyle = styleStack.back;
						styleStack.popBack();
						break;

					case "br":
						lineFeed();
						break;

					case "pi":
						break;

					case "setFontSize":
						renewStyleBlock();
						auto argDict = argumentAnalyzer(elem.argument);
						currentStyle.fontSize = to!int(argDict["_default_"]);
						break;

					case "setFont":
						renewStyleBlock();
						auto argDict = argumentAnalyzer(elem.argument);
						string newFontName = to!string(argDict["_default_"]);

						//フォントがすでに登録されているか確認
						bool alreadyRegistered = false;
						foreach(uint i, font; fonts){
							if(font.fontName == newFontName){
								currentStyle.fontID = i;
								alreadyRegistered = true;
								break;
							}
						}

						//未録フォントなら追加する
						if(alreadyRegistered == false){
							addNewFont(newFontName, "CID");
							currentStyle.fontID = to!uint(fonts.length-1);
						}
						break;

					case "setAlign":
						renewStyleBlock();
						auto argDict = argumentAnalyzer(elem.argument);
						string newAlign= to!string(argDict["_default_"]);
						if(currentStyle.fontAlign == "left" && newAlign == "center"){
							leftSpace -= (paperSize[2] + padding[0] + padding[1])/2;
						}else if(currentStyle.fontAlign == "center" && newAlign == "right"){
						}else if(currentStyle.fontAlign == "left" && newAlign == "right"){
						}else{
							//改行
							lineFeed();
						}
							currentStyle.fontAlign = newAlign;
						break;

					default:
						break;
				}
				break;
			default:
				break;
		}
	}
	lineFeed();
}

string streamBuff;

void createStream(){

	streamBuff ~= "BT\n";
	
	foreach(elem; styleBlockList){
		streamBuff ~= "/F" ~ to!string(elem.blockStyle.fontID) ~ " " ~ to!string(elem.blockStyle.fontSize)
					~ " Tf 1. 0. 0. 1. " ~ to!string(elem.x) ~ ". " ~ to!string(elem.y) ~ ". Tm <" ~ elem.content ~ "> Tj\n";
	}

	streamBuff ~= "ET\n";

	writeln("cidフォントの文字幅辞書を作っています。");
	
	foreach(font;fonts){
		sort!("a.cid < b.cid")(font.widthCidMapping);
		foreach(a; font.widthCidMapping){
			if(a.width==1000)continue;
			font.W ~= a.cid;
			font.W ~= a.cid;
			font.W ~= a.width;
		}
	}
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

//関数 string2cid
//
//文字1文字を受け取り、cmap[]を参照することでその文字に対するCIDを取得する。
//
//入力(引数)
//string in0		文字1文字
//出力(戻り値)
//string CID
//
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
	output ~= rightJustify(writer.data,4,'0');
	writer = appender!string();
	}
	return output;
}
