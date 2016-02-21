import std.stdio;
import std.array;
import std.utf;
import std.format;
import std.format;

void main(){
	string bo = "消えろ！消えろ！つかの間の灯火！Life's but a walking shadow, a poor player.";
	auto writer = appender!string();
	foreach(c; array(bo)) {
		foreach(b; [c].toUTF16) {
			formattedWrite(writer,"%04x ",b);
		}
	}
	writeln(writer.data);
}
