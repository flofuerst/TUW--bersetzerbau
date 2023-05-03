#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "types.h"

char* errorMessage = NULL;

void exitIfError(int statusCode) {
    if (statusCode == 0) {
        return;
    }

    if (errorMessage == NULL) {
        fprintf(stderr, "error: %d\n", statusCode);
    } else {
        fprintf(stderr, "error: %d: %s\n", statusCode, errorMessage);
    }

    exit(3);
}

/**
 * @brief Find a variable with the given name and check if the primitive types are identical
 * @return int error code if a variable with the given name was found and the types 
 *         are different, success code otherwise
 */
int varExistsWithType(Scope *scope, char *name, PrimitiveType primType)
{
    //Copy pointer to first element for list traversal
	Types *types = scope->types;

    bool missing = true;
	while (types != NULL) {
		if (strcmp(types->item->name, name) == 0) {
            missing = false;

            if (types->item->primType != primType) {
                return ERR_VARIABLE_WRONG_PRIMTYPE;
            }
		}
		types = types->next;
	}

    return missing ? ERR_VARIABLE_UNDEFINED : 0;
}

static int compareParameters(Types *t1, Types *t2)
{
	while (t1 != NULL && t2 != NULL) {
		if (comparePrimitiveType(t1->item->primType, t2->item->primType) != 0) {
			return ERR_PARAMETERS_DIFFERENT_PRIMTYPE;
		}
		t1 = t1->next;
		t2 = t2->next;
	}


    //Check if one of the lists still has elements
	if (t1 != t2) {
		return ERR_PARAMETERS_DIFFERENT_LENGTH;
	}
}

/**
 * @brief Checks if a method has an accompanying selector and if the implementation is valid
 */
int implHasSelector(Scope *scope, Type *type, Types *pars)
{	
    //Check for self/this parameter (First param which must be of type object)
	if (pars != NULL) {
		if (pars->item->primType != OBJECT_VAR) {
            return ERR_METHOD_SELF_PARAM_MISSING;
		}
	} else {
        return ERR_METHOD_NO_PARAMS;
    }

    Selectors *selectors = scope->selectors;
    //Search selector for implementation
	while (selectors != NULL) {
		if (strcmp(type->name, selectors->item->type->name) == 0) {
			if (type->primType != selectors->item->type->primType) {
                return ERR_METHOD_SELECTOR_RETURNTYPE_MISMATCH;
			}
			return compareParameters(selectors->item->parameters, pars);
		}

		selectors = selectors->next;
	}
	
    return ERR_METHOD_MISSING_SELECTOR;
}

PrimitiveType getCorrespondingSelectorPrimType(PrimitiveType primType)
{
	switch (primType) {
		case INT_VAR:
			return INT_SELECTOR;
		case OBJECT_VAR:
			return OBJECT_SELECTOR;
		default:
			assert(0);
	}
}

PrimitiveType getCorrespondingVariablePrimType(PrimitiveType primType)
{
	switch (primType) {
		case INT_SELECTOR:
			return INT_VAR;
		case OBJECT_SELECTOR:
			return OBJECT_VAR;
		default:
			assert(0);
	}
}


/**
 * @brief Checks it the given types are of the same primitive types
 * @return int 0 if they are equal, 1 otherwise
 */
int comparePrimitiveType(PrimitiveType t1, PrimitiveType t2) {
    switch (t1) {
        case CLAZZ:
            return t2 == CLAZZ ? 0 : 1;
        case INT_VAR:
        case INT_SELECTOR:
            return t2 == INT_VAR || t2 == INT_SELECTOR ? 0 : 1;
        case OBJECT_VAR:
        case OBJECT_SELECTOR:
            return t2 == OBJECT_VAR || t2 == OBJECT_SELECTOR ? 0 : 1;
        default:
            assert(0);
    }
}

int compareReturnTypes(PrimitiveType t1, PrimitiveType t2) {
	if (comparePrimitiveType(t1, t2) != 0) {
		return ERR_METHOD_INVALID_RETURNTYPE;
	}
	
	return 0;
}

int compareVariableAssignmentTypes(PrimitiveType t1, PrimitiveType t2) {
	if (comparePrimitiveType(t1, t2) != 0) {
		return ERR_VARIABLE_ASSIGNMENT_TYPE_MISMATCH;
	}
	
	return 0;
}

int compareTypesForHash(PrimitiveType t1, PrimitiveType t2) {
	if (comparePrimitiveType(t1, t2) != 0) {
		return ERR_HASH_EXPR_TYPE_MISMATCH;
	}
	
	return 0;
}

int checkConditionType(PrimitiveType primType) {
	if (primType != INT_VAR) {
		return ERR_CONDITIONAL_EXPR_NOT_INT;
	}

	return 0;
}

int checkTermType(PrimitiveType primType) {
	if (primType != INT_VAR) {
		return ERR_TERM_TYPE_NOT_INT;
	}

	return 0;
}

int checkSelfParameter(PrimitiveType primType) {
	if (primType != OBJECT_VAR) {
		return ERR_TERM_TYPE_NOT_OBJECT;
	}

	return 0;
}

Scope *createScope()
{
	Scope *scope = malloc(sizeof(Scope));	

    //Initialize pointer to first element
	scope->types = NULL;
	scope->selectors = NULL;
	
	return scope;
}

bool containsTypeWithName(Types *types, char *name) {
	if (name == NULL) {
		return false;
	}

	while (types != NULL) {
		if (strcmp(types->item->name, name) == 0) {
			return true;
		}

		types = types->next;
	}

	return false;
}

int appendType(Types **result, Types *types, Type *type) {
    //If the given value to append is null, do nothing
	if (type == NULL) {
		*result = types;
	}

	if (containsTypeWithName(types, type->name)) {
        return ERR_TYPE_ALREADY_EXISTS;
	}

	*result = malloc(sizeof(struct Types));

	(*result)->item = type;
	(*result)->next = types;

	return 0;
}

Types *appendTypeWithoutCheck(Types *types, Type *type) {
    //If the given value to append is null, do nothing
	if (type == NULL) {
		return types;
	}

	Types *result = malloc(sizeof(struct Types));

	result->item = type;
	result->next = types;

	return result;
}



int appendSelector(Selectors **result, Selectors *selectors, Selector *selector) {
    //If the given value to append is null, do nothing
	if (selector == NULL) {
		*result = selectors;
		return 0;
	}

	*result = malloc(sizeof(struct Selectors));

	(*result)->item = selector;
	(*result)->next = selectors;

	return 0;
}

Type *createType(char *name, PrimitiveType primType)
{
	Type *output = malloc(sizeof(struct Type));

	output->name = name;
	output->primType = primType;

	return output;
}

Selector *createSelector(char *name, PrimitiveType primType, Types *parameters)
{
	Selector *output = malloc(sizeof(struct Selector));

	output->type = createType(name, primType);
	output->parameters = parameters;

	return output;
}

int appendTypeToScope(Scope **result, Scope *scope, Type *type) {
	if (type == NULL) {
		*result = scope;
		return 0;
	}

	*result = createScope();
	(*result)->selectors = scope->selectors;

	return appendType(&((*result)->types), scope->types, type);
}

int appendSelectorToScope(Scope **result, Scope *scope, Selector *selector) {
    if (selector == NULL) {
		*result = scope;
		return 0;
	}

    *result = createScope();

    int status = appendType(&((*result)->types), scope->types, selector->type);
    if (status == 0) {
        appendSelector(&((*result)->selectors), scope->selectors, selector);
    }
    return status;
}



int searchPrimTypeOfVar(PrimitiveType *result, struct Scope *scope, char *name)
{
	Types *types = scope->types;

	while (types != NULL) {
		if (strcmp(types->item->name, name) == 0) {
			if (types->item->primType != INT_VAR &&
				types->item->primType != OBJECT_VAR) {
                
                errorMessage = malloc(strlen("'' is not a variable\n")+strlen(name)+1);
                sprintf(errorMessage, "'%s' is not a variable\n", name);
				return ERR_TYPE_NOT_VARIABLE;
			}

			*result = types->item->primType;
			return 0;
		}

		types = types->next;
	}

    errorMessage = malloc(strlen("cannot get variable with name ''\n")+strlen(name)+1);
    sprintf(errorMessage, "cannot get variable with name '%s'\n", name);
    return ERR_VARIABLE_NOT_FOUND;
}


static int searchSelectorWithParams(Scope *scope, char *name, Types *params)
{
	Selectors *selectors = scope->selectors;

	while (selectors != NULL) {
		if (strcmp(selectors->item->type->name, name) == 0) {
			return compareParameters(selectors->item->parameters, params);
		}

		selectors = selectors->next;
	}

	return ERR_SELECTOR_NOT_FOUND;
}


int getSelectorPrimTypeWithParams(PrimitiveType *result, struct Scope *scope, char *name, Types *params)
{
	Types *types = scope->types;

	while (types != NULL) {
		if (strcmp(types->item->name, name) == 0) {
			if (types->item->primType != INT_SELECTOR &&
				types->item->primType != OBJECT_SELECTOR) {

                errorMessage = malloc(strlen("' is not a callable\n")+strlen(name)+1);
                sprintf(errorMessage, "'%s' is not a callable\n", name);
                return ERR_TYPE_NOT_CALLABLE;
			}
			
            //Check if a selector exists with the given params
			int status = searchSelectorWithParams(scope, name, params);
            if (status != 0)
                return status;
			
			switch(types->item->primType) {
				case INT_SELECTOR:
					*result = INT_VAR;
					break;
				case OBJECT_SELECTOR:
					*result = OBJECT_VAR;
					break;
				default:
					assert(0);
			}
            return 0;
		}

		types = types->next;
	}

    errorMessage = malloc(strlen("cannot get method with name ''\n")+strlen(name)+1);
    sprintf(errorMessage, "cannot get method with name '%s'\n", name);
    return ERR_TYPE_NOT_CALLABLE;
}

