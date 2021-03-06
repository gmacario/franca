package org.franca.tools.contracts.tracevalidator.tests

import java.util.List
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipselabs.xtext.utils.unittesting.XtextTest
import org.franca.core.dsl.FrancaPersistenceManager
import org.franca.core.franca.FContract
import org.franca.core.franca.FEventOnIf
import org.franca.tools.contracts.tracevalidator.TraceValidator

import static org.franca.tools.contracts.tracevalidator.tests.TraceBuilder.*
import static org.junit.Assert.*
import org.franca.core.franca.FInterface

class ValidatorTestBase extends XtextTest {

	@Inject
	FrancaPersistenceManager fidlLoader
	
	var FContract contract = null

	def protected loadModel(String fidl) {
		val root = URI::createURI("classpath:/")
		val loc = URI::createFileURI("testcases/" + fidl)
		val fmodel = fidlLoader.loadModel(loc, root)
		
		assertEquals(1, fmodel.interfaces.size)
		val i = fmodel.interfaces.get(0)
		contract = i.contract
		
		i
	}	

	def protected check((List<FEventOnIf>)=>void traceFunc) {
		TraceValidator::isValidTracePure(contract, buildTrace(traceFunc))
	}

	def protected getState(String stateName) {
		contract.stateGraph.states.findFirst[name==stateName]
	}

	def protected static getMethod(FInterface api, String methodName) {
		api.methods.findFirst[name==methodName]
	}
}

