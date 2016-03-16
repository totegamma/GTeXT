//
//  loadcmap.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/22.
//
//	#このファイル:
//		cmapファイルを読み込み、辞書に書き出す。
//
module loadcmap;
import std.stdio;
import std.string;
import std.conv;
import std.format;
import std.array;
import std.utf;

uint[uint] cmap;

//関数 loadcmap
//
//CMAPを読み込み連想配列に落とす
//
//入力(ファイル)
//resources/cmap/UniJIS2004-UTF8-H.txt
//出力(グローバル)
//uint[uint] cmap
//

void loadcmap(){
	string line;
	string[] sentences;
	bool loadChar = false;
	bool loadRange = false;

	writeln("CMAPの読み込みを開始");
	writeln("CMAP: resources/cmap/UniJIS2004-UTF8-H.txt");

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
	writeln("CMAPの読み込み完了");
	writeln("要素数" ~ to!string(cmap.length) ~ "個のCMAPを読み込みました");
}
