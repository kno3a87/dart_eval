import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import '../../../dart_eval.dart';
import 'builtins.dart';
import 'errors.dart';
import 'offset_tracker.dart';

class Variable {
  Variable(this.scopeFrameOffset, this.type,
      {this.methodOffset, this.methodReturnType, this.boxed = true});

  factory Variable.alloc(CompilerContext ctx, TypeRef type,
      {DeferredOrOffset? methodOffset, ReturnType? methodReturnType, bool boxed = true}) {
    ctx.allocNest.last++;
    return Variable(ctx.scopeFrameOffset++, type,
        methodOffset: methodOffset, methodReturnType: methodReturnType, boxed: boxed);
  }

  final int scopeFrameOffset;
  final TypeRef type;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool boxed;

  String? name;
  int? frameIndex;

  Variable boxIfNeeded(CompilerContext ctx) {
    if (boxed) {
      return this;
    }
    if (type != intType) {
      throw CompileError('Can only box ints for now');
    }
    ctx.pushOp(BoxInt.make(scopeFrameOffset), BoxInt.LEN);
    final V2 = Variable.alloc(ctx, intType, boxed: true)
      ..name = name
      ..frameIndex = frameIndex;
    if (name != null) {
      ctx.locals[frameIndex!][name!] = V2;
    }
    return V2;
  }

  Variable unboxIfNeeded(CompilerContext ctx) {
    if (!boxed) {
      return this;
    }
    ctx.pushOp(Unbox.make(scopeFrameOffset), Unbox.LEN);
    final uV = Variable.alloc(ctx, type, boxed: false)
      ..name = name
      ..frameIndex = frameIndex;
    if (name != null) {
      ctx.locals[frameIndex!][name!] = uV;
    }
    return uV;
  }

  @override
  String toString() {
    return 'Variable{"$name" at L$scopeFrameOffset, $type, '
        '${methodOffset == null ? '' : 'method: $methodReturnType $methodOffset, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[$frameIndex]}';
  }
}

class PossiblyValuedParameter {
  PossiblyValuedParameter(this.parameter, this.V);

  NormalFormalParameter parameter;
  Variable? V;
}
