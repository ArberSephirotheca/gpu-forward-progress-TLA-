---- MODULE MCProgram ----
LOCAL INSTANCE Integers
LOCAL INSTANCE Naturals
LOCAL INSTANCE Sequences
LOCAL INSTANCE MCLayout
LOCAL INSTANCE TLC

VARIABLES liveVars


(* Helper Functions *)
Range(f) == { f[x] : x \in DOMAIN f }
Min(S) == CHOOSE s \in S : \A t \in S : s <= t

(* Variable *)
Var(varScope, varName, varValue) == [scope |-> varScope, name |-> varName, value |-> varValue]
VarExists(workgroupId, var) == \E variable \in liveVars[workgroupId] : variable.name = var.name
(* todo: resolve scope if duplicate name *)
GetVar(workgroupId, name) == CHOOSE variable \in liveVars[workgroupId]: variable.name = name
GetVal(workgroupId, name) == 
    IF name \in Nat THEN 
        name
    ELSE 
        GetVar(workgroupId, name).value

IsVar(var) ==
    /\ "scope" \in DOMAIN var 
    /\ "name" \in DOMAIN var 
    /\ "value" \in DOMAIN var


(* Binary Expr *)
LessThan(lhs, rhs) == lhs < rhs
LessThanOrEqual(lhs, rhs) == lhs <= rhs
GreaterThan(lhs, rhs) == lhs > rhs
GreaterThanOrEqual(lhs, rhs) == lhs >= rhs
Equal(lhs, rhs) == lhs = rhs
NotEqual(lhs, rhs) == lhs /= rhs

BinarOpSet == {"LessThan", "LessThanOrEqual", "GreaterThan", "GreaterThanOrEqual", "Equal", "NotEqual"}


IsString(s) == /\ Len(s) \in Nat
               /\ \A i \in DOMAIN s : s[i] \in STRING

IsBinaryExpr(expr) ==
    /\ "operator" \in DOMAIN expr
    /\ "left" \in DOMAIN expr
    /\ "right" \in DOMAIN expr
    /\ expr["operator"] \in BinarOpSet

\* Mimic Lazy evaluation
BinaryExpr(Op, lhs, rhs) == [operator |-> Op, left |-> lhs, right |-> rhs]

\* We have to delcare the recursive function before we can use it for mutual recursion
RECURSIVE ApplyBinaryExpr(_, _)

EvalExpr(workgroupId, expr) == 
    IF IsBinaryExpr(expr) THEN
        ApplyBinaryExpr(workgroupId, expr)
    ELSE
        GetVal(workgroupId, expr)

ApplyBinaryExpr(workgroupId, expr) ==
    LET lhsValue == EvalExpr(workgroupId, expr["left"])
        rhsValue == EvalExpr(workgroupId, expr["right"])
    IN
        IF expr["operator"] = "LessThan" THEN
            LessThan(lhsValue, rhsValue)
        ELSE IF expr["operator"] = "LessThanOrEqual" THEN
            LessThanOrEqual(lhsValue, rhsValue)
        ELSE IF expr["operator"] = "GreaterThan" THEN
            GreaterThan(lhsValue, rhsValue)
        ELSE IF expr["operator"] = "GreaterThanOrEqual" THEN
            GreaterThanOrEqual(lhsValue, rhsValue)
        ELSE IF expr["operator"] = "Equal" THEN
            Equal(lhsValue, rhsValue)
        ELSE IF expr["operator"] = "NotEqual" THEN
            NotEqual(lhsValue, rhsValue)
        ELSE
            FALSE


InitProgram ==
    /\  liveVars = [t \in 1..NumWorkGroups |-> {Var("shared", "lock", 0)}]
====