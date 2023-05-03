#ifndef _SYMB_H
#define _SYMB_H

#include <stdbool.h>

typedef enum Error {
    ERR_VARIABLE_UNDEFINED = 10,
    ERR_VARIABLE_WRONG_PRIMTYPE,

    ERR_PARAMETERS_DIFFERENT_LENGTH,
    ERR_PARAMETERS_DIFFERENT_PRIMTYPE,

    // First parameter must be object of a method implementation
    ERR_METHOD_SELF_PARAM_MISSING,
    // A method contains no params
    ERR_METHOD_NO_PARAMS,
    // The return type declared in the selector is different than in the implementation
    ERR_METHOD_SELECTOR_RETURNTYPE_MISMATCH,
    // A method has no selector
    ERR_METHOD_MISSING_SELECTOR,
    // It was tried to access a method which doesnt exist
    ERR_METHOD_UNDEFINED,
    // A type with the same name already exists in the scope
    ERR_TYPE_ALREADY_EXISTS,
    // A method tried to return an invalid primitive type
    ERR_METHOD_INVALID_RETURNTYPE,

    // ERRMSG
    ERR_TYPE_NOT_VARIABLE,
    // ERRMSG
    ERR_VARIABLE_NOT_FOUND,
    ERR_VARIABLE_ASSIGNMENT_TYPE_MISMATCH,
    //No selector with the given name was found
    ERR_SELECTOR_NOT_FOUND,
    ERR_TYPE_NOT_CALLABLE,

    ERR_CONDITIONAL_EXPR_NOT_INT,

    // A term which is part of an arithmetic expression is not of type int
    ERR_TERM_TYPE_NOT_INT,
    // A term which is used as the self parameter for a method is not of type object
    ERR_TERM_TYPE_NOT_OBJECT,
    ERR_HASH_EXPR_TYPE_MISMATCH,

} Error;

typedef enum PrimitiveType {
	CLAZZ,

    //Variable of type int
	INT_VAR,
    //Selector with return type int
    INT_SELECTOR,

    //Variable of type object
	OBJECT_VAR,
    //Selector with return type object
	OBJECT_SELECTOR,
} PrimitiveType;

/**
 * @brief Defines a type in the scope with a given primitive type
 */
typedef struct Type {
	char *name;
	PrimitiveType primType;
} Type;

/**
 * @brief Linked-List of type definitions
 * 
 */
typedef struct Types {
	Type *item;
	struct Types *next;
} Types;

/**
 * @brief Defines a selector, with a pointer to the accompanying name
 *        and a list of parameters
 */
typedef struct Selector {
	Type *type;
	Types *parameters;
} Selector;

/**
 * @brief Linked-List of Selector instances
 * 
 */
typedef struct Selectors {
	Selector *item;
	struct Selectors *next;
} Selectors;

typedef struct Scope {
	Types *types;
	Selectors *selectors;
} Scope;

void exitIfError(int statusCode);

int varExistsWithType(Scope *scope, char *name, PrimitiveType primType);

//int typeEquals(Type t1, Type t2);

int implHasSelector(Scope *scope, Type *type, Types *types);

PrimitiveType getCorrespondingSelectorPrimType(PrimitiveType primType);


int comparePrimitiveType(PrimitiveType t1, PrimitiveType t2);

int compareReturnTypes(PrimitiveType t1, PrimitiveType t2);

int compareVariableAssignmentTypes(PrimitiveType t1, PrimitiveType t2);

int compareTypesForHash(PrimitiveType t1, PrimitiveType t2);

int checkConditionType(PrimitiveType primType);

int checkTermType(PrimitiveType primType);

int checkSelfParameter(PrimitiveType primType);


bool containsTypeWithName(Types *types, char *string);

int searchPrimTypeOfVar(PrimitiveType *result, Scope *scope, char *name);

int getSelectorPrimTypeWithParams(PrimitiveType *result, Scope *scope, char *name, Types *params);

Scope *createScope();

Types *appendTypeWithoutCheck(Types *types, Type *type);

int appendType(Types **result, Types *types, Type *type);

int appendSelector(Selectors **result, Selectors *selectors, Selector *selector);

Type *createType(char *name, PrimitiveType primType);

Selector *createSelector(char *name, PrimitiveType primType, Types *parameters);

int appendTypeToScope(Scope **result, Scope *scope, Type *type);

int appendSelectorToScope(Scope **result, Scope *scope, Selector *selector);

PrimitiveType getCorrespondingVariablePrimType(PrimitiveType primType);

#endif