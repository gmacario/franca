/*******************************************************************************
 * Copyright (c) 2012 itemis AG (http://www.itemis.de).
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.franca.core

import java.util.List
import java.util.Map
import java.util.Queue
import java.util.Set
import org.eclipse.core.runtime.CoreException
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FContract
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FEventOnIf
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModel
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FStateGraph
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FUnionType
import org.franca.core.franca.Import

import static extension org.franca.core.FrancaModelExtensions.*
import org.franca.core.franca.FConstantDef

class FrancaModelExtensions {
	
	def static getModel (EObject obj) {
		getParentObject(obj, typeof(FModel))
	}
	
	def static getTypeCollection (EObject obj) {
		getParentObject(obj, typeof(FTypeCollection))
	}
	
	def static getInterface (EObject obj) {
		getParentObject(obj, typeof(FInterface))
	}
	
	def static getStateGraph (EObject obj) {
		getParentObject(obj, typeof(FStateGraph))
	}
	
	def static getContract (EObject obj) {
		getParentObject(obj, typeof(FContract))
	}
	
	def private static <T extends EObject> getParentObject (EObject it, Class<T> clazz) {
		var x = it
		
		do {
			x = x.eContainer
			if (clazz.isInstance(x))
				return x as T
		} while (x!=null)
		
		return null
	}
	
	def static getTriggeringMethod(FEventOnIf event) {
		var FMethod result = null
		if (event != null) {
			/*if (result == null)*/ result = event.call
			if (result == null) result = event.error
			if (result == null) result = event.respond
		}
		return result;
	}
	
	def static dispatch Set<FType> getInheritationSet(Void i) {
		return emptySet
	}
	
	def static dispatch Set<FType> getInheritationSet(FType t) {
		return #{t}
	}
	
	def static Set<FInterface> getInterfaceInheritationSet(FInterface i) {
		if (i == null) return #{};
		val result = newHashSet
		result += #{i}
		result += i.base.interfaceInheritationSet
		result
	}
	
	def static dispatch Set<FType> getInheritationSet(FStructType s) {
		if (s == null) return #{};
		val Set<FType> result = newHashSet
		result += #{s}
		result += s.base.inheritationSet
		result
	}
	
	def static dispatch Set<FType> getInheritationSet(FUnionType u) {
		if (u == null) return #{};
		val Set<FType> result = newHashSet
		result += #{u}
		result += u.base.inheritationSet
		result
	}
	
	def static dispatch Set<FType> getInheritationSet(FEnumerationType e) {
		if (e == null) return #{};
		val Set<FType> result = newHashSet
		result += #{e}
		result += e.base.inheritationSet
		result
	}
	
	def static dispatch Iterable<? extends FModelElement> getAllElements(FInterface i) {
		i.interfaceInheritationSet.map[
			attributes + methods + broadcasts + types + constants
		].flatten
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FTypeCollection c) {
		c.types
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FArrayType a) {
		a.elementType.derived.getAllElements
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FStructType s) {
		s.inheritationSet.map[(it as FStructType).elements].flatten
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FEnumerationType e) {
		e.inheritationSet.map[(it as FEnumerationType).enumerators].flatten
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FTypeDef td) {
		td.actualType.derived.getAllElements
	}

	def static dispatch Iterable<? extends FModelElement> getAllElements(FUnionType u) {
		u.inheritationSet.map[(it as FUnionType).elements].flatten
	}

	def static protected dispatch Iterable<? extends FModelElement> getAllElements(Object e) {
		throw new IllegalStateException("Unhandled parameter types: getAllElements not yet implemented for" + e)
	}

	def static protected dispatch Iterable<? extends FModelElement> getAllElements(Void e) {
		<FModelElement>emptyList
	}


	/**
	 * Get all non-anonymous type collections of a model.
	 */
	 def static getNamedTypedCollections (FModel model) {
	 	model.typeCollections.filter[name!=null && !name.empty]
	 }


	/**
	 * Get all FModels which are imported by current model (transitively).
	 */
	def static getAllImportedModels (FModel model) {
		val rset = model.eResource.resourceSet
		val Set<Resource> visited = newHashSet
		val Queue<Resource> todo = newLinkedList(model.eResource)
		val Map<Resource, Set<Import>> importedVia = newHashMap
		val List<FModel> imported = newArrayList
		while (! todo.empty) {
			val r = todo.poll
			if (! visited.contains(r)) {
				visited.add(r)
				
				val m = r.getFModel
				if (m!=null) {
					// add imported models to queue
					for(imp : m.imports) {
						val uri = imp.importURI
						val importURI = URI::createURI(uri)
						val resolvedURI = importURI.resolve(m.eResource.URI);
						try {
							val res = rset.getResource(resolvedURI, true)
							todo.add(res)
							
							// remember imported model
							if (! visited.contains(res)) {
								val importedModel = res.getFModel
								if (importedModel!=null)
									imported.add(importedModel)
	
								// remember top-level import statement which lead to this import
								if (! importedVia.containsKey(res))
									importedVia.put(res, newHashSet)
								if (m==model) {
									importedVia.get(res).add(imp)
								} else {
									val via = importedVia.get(r)
									importedVia.get(res).addAll(via)
								}
							}
						} catch (CoreException ex) {
							// problem when loading the resource, ignore
							println("WARNING: imported resource '" +
								resolvedURI.toString + "' could not be loaded."
							)
						}
					}
				}
			}
		}
		new ImportedModelInfo(imported, importedVia)
	}

	def private static getFModel (Resource res) {
		if (res.contents==null || res.contents.empty) {
			null
		} else {
			val obj = res.contents.get(0)
			if (obj instanceof FModel) {
				obj as FModel
			} else {
				null
			}
		}					
	}

}

@Data
class ImportedModelInfo {
	Iterable<FModel> importedModels
	Map<Resource, Set<Import>> importVia
	
	def getViaString (Resource res) {
		val via = importVia.get(res)
		via.join(', ', ["'" + importURI + "'"])
	}
}
