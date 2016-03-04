//
//  pdfObjectClass.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/22.
//
//	#このファイル:
//		pdfの構造を表す構造体としてのclass。
//
module pdfObjectClass;
import std.stdio;
import core.vararg;
import std.conv;

uint size = 15;
pdfObject[] pdfObjects;

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
	string objectType;

	string refer;

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
				objectType = va_arg!string(_argptr);
				object = va_arg!(pdfObject[])(_argptr);
				break;
			case "refer":
				refer = va_arg!string(_argptr);
				break;
			case "refarray":
				refer = va_arg!string(_argptr);
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
				return to!string(getObjID(refer)[0]) ~ " 0 R";
				break;
			case "refarray":
				string outputstr = "[ ";
				uint[] idList = getObjID(refer);
				foreach(id;idList){
					outputstr ~= to!string(id) ~ " 0 R ";
				}
				outputstr ~= "]";
				return outputstr;
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

uint[] getObjID(string in0){
	uint idList[];
	foreach(uint i, obj; pdfObjects){
		if(obj.objectType == in0){
			idList ~= i;
		}
	}
	return idList;
}

void debugger(){
}
