import std.stdio;
import std.format;
import std.array;
import std.conv;

void main(){
	const string fontPath = "../resources/fonts/xits-math.otf";

	int numOfTable = array2uint(trim(4,2,fontPath));
	uint numberOfHMetrics;
	for(int i; i<numOfTable; i++){
		string tag		= array2string(trim(12 +16*i, 4,fontPath));
		uint checkSum	= array2uint(trim(16 +16*i, 4,fontPath));
		uint offset		= array2uint(trim(20 +16*i, 4,fontPath));
		uint dataLength = array2uint(trim(24 +16*i, 4,fontPath));
		switch(tag){
			case "MATH":
				writeln("hi");
				break;
			default:
				break;
		}
	}
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


