# 
# Copyright 2013 Jeff Bush
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

import sys

class CodeGenerator:
	def __init__(self, filename):
		self.operandStack = []
		self.freeRegisters = [ x for x in range(3, -1, -1) ]
		self.outputFile = open(filename, 'w')
		self.numInstructions = 0

	def pushConstant(self, value):
		self.operandStack += [ ('const', value) ]

	def pushVariableRef(self, index):
		self.operandStack += [ ('freg', index ) ]

	def doOp(self, operation):
		type2, op2 = self.operandStack.pop()
		type1, op1 = self.operandStack.pop()
		if type1 == 'const':
			# If the first operator is a constant, copy it into a register
			tmpReg = self._allocateTemporary()
			self._emitInstruction(8, tmpReg, 0, 0, 1, op1)
			type1 = 'reg'
			op1 = tmpReg

		# Free up temporary registers, allocate a result reg
		if type2 == 'reg': self._freeTemporary(op2)
		if type1 == 'reg': self._freeTemporary(op1)
		resultReg = self._allocateTemporary()
		self.operandStack += [ ('reg', resultReg)]
		if type2 == 'const':
			self._emitInstruction(operation, resultReg, op1, 0, 1, op2)
		else:
			self._emitInstruction(operation, resultReg, op1, op2, 0, 0)

	def saveResult(self):
		# Emit an instruction to move into the result register (7)
		type, op = self.operandStack.pop()
		if type == 'reg' or type == 'freg':
			self._emitInstruction(0, 7, op, op, 0, 0)
		elif type == 'const':
			self._emitInstruction(8, 7, 0, 0, 1, op)	# Constant
		else:
			raise Exception('internal error: bad type on operand stack')

		# Pad the remaining instructions with NOPs.
		for i in range(self.numInstructions, 16):
			self.outputFile.write('0000000000000\n')

		self.outputFile.close()

	def _emitInstruction(self, opcode, dest, srca, srcb, isConst, constVal):
		self.numInstructions += 1
		if self.numInstructions == 16:
			raise Exception('formula too complex: exceeded instruction memory')
			
		self.outputFile.write('%013x\n' % ((dest << 43) | (srca << 40) | (srcb << 37) | (opcode << 33) | (isConst << 32) | constVal))

		# Pretty print operation
		pretty = [ 'and', 'xor', 'or', 'add', 'sub', 'mul', 'shl', 'shr', 'mov',
			'eq', 'neq', 'gt', 'gte', 'lt', 'lte' ]
		if isConst:
			print '%s r%d, r%d, #%d' % (pretty[opcode], dest, srca, constVal)
		else:
			print '%s r%d, r%d, r%d' % (pretty[opcode], dest, srca, srcb)

	def _allocateTemporary(self):
		if len(self.freeRegisters) == 0:
			raise Exception('formula too complex: out of registers')
		else:
			return self.freeRegisters.pop()
		
	def _freeTemporary(self, val):
		self.freeRegisters += [ val ]

class Scanner:
	def __init__(self, stream):
		self.pushBackChar = None
		self.pushBackToken = False
		self.lastToken = None
		self.stream = stream

	def pushBack(self):
		self.pushBackToken = True

	MULTIBYTE_TOKENS = {
		'>' : [ '=', '>' ],
		'<' : [ '=', '<' ],
		'=' : [ '=' ],
		'!' : [ '=' ],
	}

	def nextToken(self):
		if self.pushBackToken:
			self.pushBackToken = False
			return self.lastToken
	
		# Consume whitespace
		ch = self._nextChar()
		while ch.isspace():
			ch = self._nextChar()
	
		# Get next token
		if ch == '':
			# End of string
			self.lastToken = None
		elif ch.isdigit():
			lookahead = self._nextChar()
			if lookahead == '':
				self.lastToken = None
			elif ch == '0' and lookahead == 'x':
				# Parse a hexadecimal number
				number = 0
				while True:
					ch = self._nextChar()
					if ch >= 'A' and ch <= 'F':
						number = (number * 16) + (ord(ch) - ord('A') + 10)
					elif ch >= 'a' and ch <= 'f':
						number = (number * 16) + (ord(ch) - ord('a') + 10)
					elif ch.isdigit():
						number = (number * 16) + (ord(ch) - ord('0'))
					else:
						self._pushBackChar(ch)
						break

				self.lastToken = number
			else:
				# Parse a decimal number
				self._pushBackChar(lookahead)
				number = 0
				while ch.isdigit():
					number = (number * 10) + (ord(ch) - ord('0'))
					ch = self._nextChar()

				self._pushBackChar(ch)
				self.lastToken = number
		elif ch in self.MULTIBYTE_TOKENS:
			secondchars = self.MULTIBYTE_TOKENS[ch]
			lookahead = self._nextChar()
			if lookahead in secondchars:
				self.lastToken = ch + lookahead
			else:
				self._pushBackChar(lookahead)
				self.lastToken = ch
		elif ch.isalpha():
			strval = ch
			while True:
				ch = self._nextChar()
				if ch.isalnum():
					strval += ch
				else:
					self._pushBackChar(ch)
					break
					
			self.lastToken = strval
		else:
			# Single character symbolic token
			self.lastToken = ch
			
		return self.lastToken

	def _nextChar(self):
		if self.pushBackChar:
			ch = self.pushBackChar
			self.pushBackChar = None
			return ch
		else:
			return self.stream.read(1)

	def _pushBackChar(self, ch):
		self.pushBackChar = ch

class Parser:
	def __init__(self, inputStream, generator):
		self.scanner = Scanner(inputStream)
		self.generator = generator

	def parse(self):
		self._parseExpression()
		self.generator.saveResult()

	def _parseExpression(self):	
		self._parseUnaryExpression()
		self._parseInfixExpression(0)

	BUILTIN_VARS = {
		'x' : 4,
		'ix' : 4,
		'y' : 5,
		'iy' : 5,
		'f' : 6
	}

	def _parsePrimaryExpression(self):
		tok = self.scanner.nextToken()
		if tok == '(':
			self._parseExpression()
			tok = self.scanner.nextToken()
			if tok != ')':
				raise Exception('parse error: expected )')
		elif isinstance(tok, int) or isinstance(tok, long):
			self.generator.pushConstant(tok)
		elif tok in self.BUILTIN_VARS:
			self.generator.pushVariableRef(self.BUILTIN_VARS[tok])
		else:
			raise Exception('unexpected: ' + str(tok))

	def _parseUnaryExpression(self):
		lookahead = self.scanner.nextToken()
		if lookahead == '-':
			self.generator.pushConstant(0)
			self._parseUnaryExpression()
			self.generator.doOp(4)	# Subtract
		elif lookahead == '~':
			self._parseUnaryExpression()
			self.generator.pushConstant(0xffffffff)
			self.generator.doOp(1)	# Exclusive Or
		elif lookahead == '!':
			self._parseUnaryExpression()
			self.generator.pushConstant(0)
			self.generator.doOp(9)	# Equal to
		else:
			self.scanner.pushBack()
			self._parsePrimaryExpression()

	# Operator lookup table
	# (precedence, opcode)
	OPERATORS = {
		'|' : ( 1, 2 ),
		'^' : ( 2, 1 ),
		'&' : ( 3, 0 ),
		'==' : ( 4, 9 ),
		'!=' : ( 4, 10 ),
		'>' : ( 5, 11 ),
		'<' : ( 5, 13 ),
		'>=' : ( 5, 12 ),
		'<=' : ( 5, 14 ),
		'<<' : ( 6, 6 ),
		'>>' : ( 6, 7 ),
		'+' : ( 7, 3 ),
		'-' : ( 7, 4 ),
		'*' : ( 8, 5 ),
#		'/' : ( 9, -1 )
	}

	# https://en.wikipedia.org/wiki/Operator-precedence_parser#Precedence_climbing_method
	def _parseInfixExpression(self, minPrecedence):
		while True:
			outerOp = self.scanner.nextToken()
			if outerOp not in self.OPERATORS:
				self.scanner.pushBack()
				break
			
			outerPrecedence, outerOpcode = self.OPERATORS[outerOp]
			if outerPrecedence < minPrecedence:
				self.scanner.pushBack()
				break

			self._parseUnaryExpression()
			while True:
				lookahead = self.scanner.nextToken()			
				self.scanner.pushBack()
				if lookahead not in self.OPERATORS:
					break
					
				innerPrecedence, _ignore = self.OPERATORS[lookahead]
				if innerPrecedence <= outerPrecedence:
					break
					
				self._parseInfixExpression(innerPrecedence)

			self.generator.doOp(outerOpcode)

p = Parser(sys.stdin, CodeGenerator('microcode.hex'))
p.parse()

