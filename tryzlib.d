import std.stdio;
import std.zlib;
import std.conv;

void main(){
	encode();
}

void decode(){
	string line;
	bool instream;
	string buff;
	string[] streams;

	auto fin = File("import.pdf","r");
	while(!fin.eof){
		line = fin.readln;
		if(instream == true){
			if(line == "endstream\n"){
				instream = false;
				streams ~= buff;
				buff = "";
			}else{
				buff ~= line;
			}
		}else{
			if(line == "stream\n"){
				instream = true;
			}
		}
	}

	foreach(i,elem ; streams){
		auto fout = File("streamOutput/output" ~ to!string(i) ~ ".txt","w");
		fout.write(to!string(uncompress(elem)));
	}


}

void encode(){
	string input = "boboboo";
	write(to!string(compress(input)));
}
