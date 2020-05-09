/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.parser.antlr;

import org.antlr.runtime.Token;
import org.antlr.runtime.TokenSource;
import org.eclipse.xtext.parser.antlr.AbstractIndentationTokenSource;
import org.iot.codegenerator.parser.antlr.internal.InternalCodeGeneratorParser;

public class CodeGeneratorTokenSource extends AbstractIndentationTokenSource {

	public CodeGeneratorTokenSource(TokenSource delegate) {
		super(delegate);
	}

	@Override
	protected boolean shouldSplitTokenImpl(Token token) {
		// TODO Review assumption
		return token.getType() == InternalCodeGeneratorParser.RULE_WS;
	}

	@Override
	protected int getBeginTokenType() {
		// TODO Review assumption
		return InternalCodeGeneratorParser.RULE_BEGIN;
	}

	@Override
	protected int getEndTokenType() {
		// TODO Review assumption
		return InternalCodeGeneratorParser.RULE_END;
	}

}
