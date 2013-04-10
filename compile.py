import sys

class Scanner:
	def __init__(self, stream):
		self.pushBackChar = None
		self.pushBackToken = False
		self.lastToken = None
		self.stream = stream

	def pushBack(self):
		self.pushBackToken = True

	def nextToken(self):
		if self.pushBackToken:
			self.pushBackToken = False
			return self.lastToken
	
		# Consume whitespace
		ch = self._nextChar()
		while ch.isspace():
			ch = self._nextChar()
	
		# Consume a token	
		if ch == '':
			# End of string
			self.lastToken = None
		elif ch.isdigit():
			lookahead = self._nextChar()
			if lookahead == '':
				self.lastToken = None
			elif lookahead == 'x':
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
		elif ch == '<':
			lookahead = self._nextChar()
			if lookahead == '<':
				self.lastToken = '<<'
			else:
				self._pushBackChar()
				self.lastToken = '<'
		elif ch == '>':
			lookahead = self._nextChar()
			if lookahead == '>':
				self.lastToken = '>>'
			else:
				self._pushBackChar()
				self.lastToken = '>'
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

class CodeGenerator:
	def __init__(self, filename):
		self.operandStack = []
		self.freeRegisters = [ x for x in range(7, -1, -1) ]
		self.outputFile = open(filename, 'w')
		self.numInstructions = 0

	def pushConstant(self, value):
		self.operandStack += [ ('const', value) ]

	BUILTIN_VARS = {
		'x' : 8,
		'ix' : 8,
		'y' : 9,
		'iy' : 9,
		'f' : 10
	}

	def pushVariableRef(self, value):
		if value in self.BUILTIN_VARS:
			self.operandStack += [ ('freg', self.BUILTIN_VARS[value]) ]
		else:
			raise Exception('unknown variable ' + value)

	def _emitMicroInstruction(self, opcode, dest, srca, srcb, isConst, constVal):
		self.numInstructions += 1
		self.outputFile.write('%013x\n' % ((dest << 45) | (srca << 41) | (srcb << 37) | (opcode << 33) | (isConst << 32) | constVal))

		# Pretty print operation
		pretty = [ 'and', 'xor', 'or', 'add', 'sub', 'mul', 'shl', 'shr', 'mov' ]
		if isConst:
			print '%s r%d, r%d, #%d' % (pretty[opcode], dest, srca, constVal)
		else:
			print '%s r%d, r%d, r%d' % (pretty[opcode], dest, srca, srcb)

	OPERATORS = {
		'&' : 0,
		'^' : 1,
		'|' : 2,
		'+' : 3,
		'-' : 4,
		'*' : 5,
		'<<' : 6,
		'>>' : 7
	}

	def doOp(self, operation):
		type2, op2 = self.operandStack.pop()
		type1, op1 = self.operandStack.pop()

		if type1 == 'const':
			# If the first operator is a constant, copy it into a register
			tmpReg = self._allocateTemporary()
			self._emitMicroInstruction(8, tmpReg, 0, 0, 1, op1)
			type1 = 'reg'
			op1 = tmpReg

		# Free up temporary registers, allocate a result reg
		if type2 == 'reg': self._freeTemporary(op2)
		if type1 == 'reg': self._freeTemporary(op1)
		resultReg = self._allocateTemporary()
		self.operandStack += [ ('reg', resultReg)]
		if type2 == 'const':
			self._emitMicroInstruction(self.OPERATORS[operation], resultReg, op1, 0, 1, op2)
		else:
			self._emitMicroInstruction(self.OPERATORS[operation], resultReg, op1, op2, 0, 0)

	def saveResult(self):
		# Emit an instruction to move into the result register
		type, op = self.operandStack.pop()
		if type == 'reg' or type == 'freg':
			self._emitMicroInstruction(0, 11, op, op, 0, 0)
		elif type == 'const':
			self._emitMicroInstruction(8, 11, 0, 0, 1, op)	# Constant
		else:
			raise Exception('internal error: bad type on operand stack')

		for i in range(self.numInstructions, 64):
			self.outputFile.write('0000000000000\n')

		self.outputFile.close()

	def _allocateTemporary(self):
		return self.freeRegisters.pop()
		
	def _freeTemporary(self, val):
		self.freeRegisters += [ val ]

class Parser:
	def __init__(self, outputFile):
		self.scanner = Scanner(sys.stdin)
		self.generator = CodeGenerator(outputFile)

	def parse(self):
		self._parseExpression()
		self.generator.saveResult()

	def _parseExpression(self):	
		self._parsePrimaryExpression()
		self._parseInfixExpression(0)

	def _parsePrimaryExpression(self):
		tok = self.scanner.nextToken()
		if tok == '(':
			self._parseExpression()
			tok = self.scanner.nextToken()
			if tok != ')':
				raise Exception('parse error: expected )')
		elif isinstance(tok, int) or isinstance(tok, long):
			self.generator.pushConstant(tok)
		else:
			self.generator.pushVariableRef(tok)

	# Operators with their precedence numbers
	OP_PRECEDENCE = {
		'|' : 1,
		'^' : 2,
		'&' : 3,
		'>>' : 4,
		'<<' : 4,
		'+' : 5,
		'-' : 6,
		'*' : 7,
#		'/' : 7,
	}

	def _parseInfixExpression(self, minPrecedence):
		while True:	# Reduce loop
			outerOp = self.scanner.nextToken()
			if outerOp == None:
				break

			if outerOp not in self.OP_PRECEDENCE:
				self.scanner.pushBack()
				break
			
			outerPrecedence = self.OP_PRECEDENCE[outerOp]
			if outerPrecedence < minPrecedence:
				self.scanner.pushBack()
				break

			self._parsePrimaryExpression()
			while True:	# Shift loop
				lookahead = self.scanner.nextToken()			
				if lookahead == None:
				 	break
				 
				self.scanner.pushBack()
				if lookahead not in self.OP_PRECEDENCE:
					break
					
				innerPrecedence = self.OP_PRECEDENCE[lookahead]
				if innerPrecedence <= outerPrecedence:
					break
					
				self._parseInfixExpression(innerPrecedence)

			self.generator.doOp(outerOp)

p = Parser('microcode.hex')
p.parse()

