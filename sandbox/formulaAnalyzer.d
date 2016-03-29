import std.stdio;
import core.vararg;
import std.string;
import std.conv;


class mathObj{
	string type;
	real value;
	string formula;
	string operator;
	string valuable;

	mathObj leftValue;
	mathObj rightValue;

	this(string in0,...){
		type = in0;
		switch(type){
			case "formula":
				formula= va_arg!string(_argptr);
				break;
			case "value":
				value = va_arg!real(_argptr);
				break;
			case "operator":
				operator = va_arg!string(_argptr);
				break;
			case "valuable":
				valuable = va_arg!string(_argptr);
			default:
				break;
		}
	}

	void parse(){
		if(formula.length == 1){
			type = "value";
			value = to!real(formula);
			return;
		}
		// +
		auto opeIndex = indexOf(formula, '+');
		if(opeIndex != -1){
			type = "operator";
			operator = "+";
			leftValue = new mathObj("formula",formula[0..opeIndex]);
			leftValue.parse;
			rightValue = new mathObj("formula", formula[opeIndex+1..$]);
			rightValue.parse;
			return;
		}
		
		// -
		opeIndex = indexOf(formula, '-');
		if(opeIndex != -1){
			type = "operator";
			operator = "-";
			leftValue = new mathObj("formula",formula[0..opeIndex]);
			leftValue.parse;
			rightValue = new mathObj("formula", formula[opeIndex+1..$]);
			rightValue.parse;
			return;
		}
		// *
		opeIndex = indexOf(formula, '*');
		if(opeIndex != -1){
			type = "operator";
			operator = "*";
			leftValue = new mathObj("formula",formula[0..opeIndex]);
			leftValue.parse;
			rightValue = new mathObj("formula", formula[opeIndex+1..$]);
			rightValue.parse;
			return;
		}
		// /
		opeIndex = indexOf(formula, '/');
		if(opeIndex != -1){
			type = "operator";
			operator = "/";
			leftValue = new mathObj("formula",formula[0..opeIndex]);
			leftValue.parse;
			rightValue = new mathObj("formula", formula[opeIndex+1..$]);
			rightValue.parse;
			return;
		}
		writeln("wtf: " ~ formula);
	}

	real calculate(){
		switch(type){
			case "formula":
				writeln("wtf");
				break;
			case "value":
				return value;
				break;
			case "operator":
				switch(operator){
					case "+":
						return leftValue.calculate() + rightValue.calculate();
						break;
					case "-":
						return leftValue.calculate() - rightValue.calculate();
						break;
					case "*":
						return leftValue.calculate() * rightValue.calculate();
						break;
					case "/":
						return leftValue.calculate() / rightValue.calculate();
						break;
					default:
						break;
				}
				break;
			case "valuable":
			default:
				break;
		}
		return 0;
	}

}

void main(){
	string input = "6*9*2+3*4";
	mathObj testObj = new mathObj("formula", input);
	testObj.parse;
	writeln(testObj.calculate);
}
