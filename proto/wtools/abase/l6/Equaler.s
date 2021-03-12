( function _Equaler_s_()
{

'use strict';

/**
 * Collection of cross-platform routines to compare two complex structures. The module can answer questions: are two structures equivalent? are them identical? what is the difference between each other? Use the module avoid manually work and cherry picking.
  @module Tools/base/Equaler
  @extends Tools
*/

/**
 * Collection of light-weight routines to traverse complex data structure.
 * @namespace Tools.Equaler
 * @module Tools/base/Looker
 */

/**
 * Collection of light-weight routines to traverse complex data structure.
 * @namespace Tools.equaler
 * @module Tools/base/Looker
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../wtools/Tools.s' );

  _.include( 'wLooker' );
  _.include( 'wSelector' );

}

let _global = _global_;
let _ = _global_.wTools;
let Parent = _.looker.Looker;
let _ObjectToString = Object.prototype.toString;

_.equaler = _.equaler || Object.create( _.looker );

_.assert( !!_realGlobal_ );
_.assert( !!_.look );
_.assert( !!_.select );

// --
// relations
// --

let Prime = Object.create( null );

Prime.src = null;
Prime.src2 = null;
Prime.containing = 0;
Prime.strict = 1;
Prime.revisiting = 1;
Prime.strictTyping = null;
Prime.strictNumbering = null;
Prime.strictCycling = null;
Prime.strictString = null;
Prime.strictContainer = null;
Prime.withImplicit = null;
Prime.withCountable = 'countable';
Prime.accuracy = 1e-7;
Prime.recursive = Infinity;
Prime.onNumbersAreEqual = null;
Prime.onStringsAreEqual = null;
Prime.onStringPreprocess = null;
Prime.iterableEval = null;

// --
// routines
// --

/**
  * Deep comparsion of two entities. Uses recursive comparsion for objects, arrays and array-like objects.
  * Returns string refering to first found difference or false if entities are sames.
  *
  * @param {*} src - Entity for comparison.
  * @param {*} src2 - Entity for comparison.
  * @param {wTools~entityEqualOptions} o - Comparsion options {@link wTools~entityEqualOptions}.
  * @returns {boolean} result - Returns false for same entities or difference as a string.
  *
  * @example
  * //returns
  * //"at :
  * //src1 :
  * //1
  * //src2 :
  * //1 "
  * _.entityDiff( '1', 1 );
  *
  * @example
  * //returns
  * //"at : .2
  * //src1 :
  * //3
  * //src2 :
  * //4
  * //difference :
  * //*"
  * _.entityDiff( [ 1, 2, 3 ], [ 1, 2, 4 ] );
  *
  * @function entityDiff
  * @throws {exception} If( arguments.length ) is not equal 2 or 3.
  * @throws {exception} If( o ) is not a Object.
  * @throws {exception} If( o ) is extended by unknown property.
  * @namespace Tools
 * @module Tools/base/Equaler
  */

function entityDiff( src, src2, opts )
{

  opts = opts || Object.create( null );
  _.assert( arguments.length === 2 || arguments.length === 3, 'Expects two or three arguments' );
  let equal = _.equaler._equal( src, src2, opts );

  if( equal )
  return false;

  let it = opts;
  _.assert( it.lastPath !== undefined );

  let result = _.entityDiffExplanation
  ({
    srcs : [ src, src2 ],
    path : it.lastPath,
  });

  return result;
}

//

function entityDiffExplanation( o )
{
  let result = '';
  let isDiffProto = false;

  o = _.routineOptions( entityDiffExplanation, arguments );
  _.assert( _.arrayIs( o.srcs ) );
  _.assert( o.srcs.length === 2 );
  _.assert( arguments.length === 1 );

  if( o.onStringPreprocess === null )
  if( o.strictString )
  o.onStringPreprocess = stringsPreprocessNo;
  else
  o.onStringPreprocess = stringsPreprocessLose;

  if( o.path )
  {

    let src0 = _.select( o.srcs[ 0 ], o.path );
    let src1 = _.select( o.srcs[ 1 ], o.path );

    if( _.aux.is( src0 ) && _.aux.is( src1 ) ) /* yyy */
    {
      o.srcs[ 0 ] = src0;
      o.srcs[ 1 ] = src1;
    }
    else
    {
      let dir = _.strSplit( o.path, '/' )
      .slice( 0, -1 )
      .join( '' );

      if( !dir )
      dir = '/';
      o.srcs[ 0 ] = _.select( o.srcs[ 0 ], dir );
      o.srcs[ 1 ] = _.select( o.srcs[ 1 ], dir );
    }

    if( o.path !== '/' )
    result += 'at ' + o.path + '\n';

  }

  if( _.strIs( o.srcs[ 0 ] ) )
  o.srcs[ 0 ] = o.onStringPreprocess( o.srcs[ 0 ] );
  if( _.strIs( o.srcs[ 1 ] ) )
  o.srcs[ 1 ] = o.onStringPreprocess( o.srcs[ 1 ] );

  if( _.aux.is( o.srcs[ 0 ] ) && _.aux.is( o.srcs[ 1 ] ) )
  {
    let protoGot = Object.getPrototypeOf( o.srcs[ 0 ] );
    let protoExpected = Object.getPrototypeOf( o.srcs[ 1 ] );
    let srcOwn0 = _.property.onlyOwn( o.srcs[ 0 ] );
    let srcOwn1 = _.property.onlyOwn( o.srcs[ 1 ] );

    let common = _.filter_( null, srcOwn0, ( e, k ) => _.entityIdentical( e, srcOwn1[ k ] ) ? e : undefined );
    o.srcs[ 0 ] = _.mapBut( srcOwn0, common );
    o.srcs[ 1 ] = _.mapBut( srcOwn1, common );

    if( _.mapIsEmpty( o.srcs[ 0 ] ) && _.mapIsEmpty( o.srcs[ 1 ] ) )
    {
      if( !isEquivalentProto( protoGot, protoExpected ) )
      {
        isDiffProto = true;
        if( protoGot === null )
        {
          o.srcs[ 1 ] = '__proto__';
          o.srcs[ 0 ] = '__proto__ = null';
        }
        else if( protoExpected === null )
        {
          o.srcs[ 0 ] = '__proto__';
          o.srcs[ 1 ] = '__proto__ = null';
        }
        else
        {
          o.srcs[ 0 ] = '__proto__';
          o.srcs[ 1 ] = '__proto__';
        }
      }
    }
  }

  o.srcs[ 0 ] = _.entity.exportString( o.srcs[ 0 ], { levels : o.levels, keyWrapper : '\'' } );
  o.srcs[ 1 ] = _.entity.exportString( o.srcs[ 1 ], { levels : o.levels, keyWrapper : '\'' } );

  o.srcs[ 0 ] = '  ' + _.strLinesIndentation( o.srcs[ 0 ], '  ' );
  o.srcs[ 1 ] = '  ' + _.strLinesIndentation( o.srcs[ 1 ], '  ' );

  result += _.entity.exportStringSimple( o.name1 + ' :\n' + o.srcs[ 0 ] + '\n' + o.name2 + ' :\n' + o.srcs[ 1 ] );

  /* */

  let strDiff = false;

  if( !isDiffProto )
  strDiff = _.strDifference( o.srcs[ 0 ], o.srcs[ 1 ] );

  if( strDiff !== false )
  {
    result += ( '\n' + o.differenceName + ' :\n' + strDiff );
  }

  /* */

  if( o.accuracy !== null )
  result += '\n' + o.accuracyName + ' ' + o.accuracy + '\n';

  return result;

  /* */

  function stringsPreprocessLose( str )
  {
    return _.strLinesStrip( str );
  }

  /* */

  function stringsPreprocessNo( str )
  {
    return str;
  }

  /* */

  function isEquivalentProto( proto1, proto2 )
  {
    if( proto1 === proto2 )
    return true;

    if( proto1 === null && proto2 === Object.prototype )
    return true;

    if( proto2 === null && proto1 === Object.prototype )
    return true;

    return false;
  }

  /* */

}

var defaults = entityDiffExplanation.defaults = Object.create( null );

defaults.name1 = '- src1';
defaults.name2 = '- src2';
defaults.differenceName = '- difference';
defaults.accuracyName = 'with accuracy';
defaults.srcs = null;
defaults.path = null;
defaults.accuracy = null;
defaults.levels = 3;
defaults.strictString = 1; /* qqq : cover option strictString */
defaults.onStringPreprocess = null

// --
// options
// --

function head( routine, args )
{
  _.assert( arguments.length === 2 );
  if( args.length === 3 && _.looker.iterationIs( args[ 2 ] ) )
  {
    let it = args[ 2 ];
    _.assert( it.src === args[ 1 ] );
    _.assert( it.src2 === args[ 0 ] );
    return it;
  }
  _.assert( !!routine.defaults.Looker );
  let o = routine.defaults.Looker.optionsFromArguments( args );

  o.Looker = o.Looker || routine.defaults;

  _.assertMapHasOnly( o, routine.defaults );
  _.assert( routine.defaults === o.Looker );
  _.assert( routine.defaults.withImplicit === null );
  let it = o.Looker.optionsToIteration( null, o );
  return it;
}

//

function optionsFromArguments( args )
{
  let o = args[ 2 ] || Object.create( null );

  /*
    second argument should goes first to make contain work properly
  */

  o.src = args[ 1 ];
  o.src2 = args[ 0 ];

  _.assert( args.length === 1 || args.length === 2 || args.length === 3 );
  _.assert( arguments.length === 1 );
  _.assert( _.mapIs( o ) );

  return o;
}

//

function optionsForm( routine, o )
{

  _.assert( o.iteratorProper( o ) );
  _.assert( 0 <= o.revisiting && o.revisiting <= 2 );
  _.assert( o.withImplicit !== undefined );
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert
  (
    _.longHasAll( [ 0, false, 'all', 'any', 'only', 'none' ], o.containing )
    , () => `Unknown value of option o.containing : ${o.containing}`
    + `\nExpects any of [ ${[ 0, false, 'all', 'any', 'only', 'none' ].join( ' ' )} ]`
  );

  let accuracy = o.accuracy;

  if( o.strictTyping === null )
  o.strictTyping = o.strict;
  if( o.strictNumbering === null )
  o.strictNumbering = o.strict;
  if( o.strictCycling === null )
  o.strictCycling = o.strict;
  if( o.strictString === null )
  o.strictString = o.strict;
  if( o.strictContainer === null )
  o.strictContainer = o.strict;
  if( o.withImplicit === null )
  o.withImplicit = o.strictTyping ? 'aux' : '';

  if( o.onNumbersAreEqual === null )
  if( o.strictNumbering && o.strictTyping )
  o.onNumbersAreEqual = _.numbersAreIdentical;
  else if( o.strictNumbering && !o.strictTyping )
  o.onNumbersAreEqual = _.numbersAreIdenticalNotStrictly;
  else
  o.onNumbersAreEqual = ( a, b, acc ) =>
  {
    return _.numbersAreEquivalent( a, b, ( acc === undefined || acc === null ) ? accuracy : acc );
  }

  if( o.onStringsAreEqual === null )
  o.onStringsAreEqual = stringsAreIdentical;

  if( o.onStringPreprocess === null )
  if( o.strictString )
  o.onStringPreprocess = stringsPreprocessNo;
  else
  o.onStringPreprocess = stringsPreprocessLose;

  Parent.optionsForm.call( this, routine, o );

  return o;

  /* */

  function stringsAreIdentical( a, b )
  {
    if( !_.strIs( a ) )
    return false;
    if( !_.strIs( b ) )
    return false;
    return a === b;
  }

  /* */

  function stringsPreprocessLose( str )
  {
    return _.strLinesStrip( str );
  }

  /* */

  function stringsPreprocessNo( str )
  {
    return str;
  }

}

//

function optionsToIteration( iterator, o )
{
  let it = Parent.optionsToIteration.call( this, iterator, o );

  _.assert( arguments.length === 2 );
  _.assert( it.iterator.visitedContainer2 === null );
  _.assert( it.originalSrc === null );
  _.assert( it.originalSrc2 === null );
  _.assert( it.result === true );

  return it;
}

// --
// looker routines
// --

function performBegin()
{
  let it = this;
  Parent.performBegin.apply( it, arguments );

  _.assert( it.iterator.visitedContainer2 === null );

  if( it.iterator.revisiting < 2 )
  {
    if( it.iterator.revisiting === 0 )
    it.iterator.visitedContainer2 = _.containerAdapter.from( new Set );
    else
    it.iterator.visitedContainer2 = _.containerAdapter.from( new Array );
  }
  _.assert( it.iterator.revisiting >= 2 || !!it.iterator.visitedContainer2 );

  return it;
}

//

function performEnd()
{
  let it = this;

  _.assert( _.boolIs( it.result ) );
  _.assert( it.withImplicit === '' ^ it.strictTyping );

  Parent.performEnd.apply( it, arguments );
  return it;
}

//

function chooseBegin( e, k )
{
  let it = this;
  [ e, k ] = Parent.chooseBegin.apply( it, arguments );

  _.assert( arguments.length === 2 );
  _.assert( it.level >= 0 );
  _.assert( _.objectIs( it.down ) );

  it.src2 = _.container.elementGet( it.src2, k );
  it.originalSrc2 = it.src2;

  return [ e, k ];
}

//

function chooseRoot( e )
{
  let it = this;

  _.assert( arguments.length === 1 );

  it.src = e;
  it.originalSrc = e;

  it.originalSrc2 = it.src2;

  if( it.containing === 'only' )
  {
    let x;
    x = it.src;
    it.src = it.src2;
    it.src2 = x;
    x = it.originalSrc;
    it.originalSrc = it.originalSrc2;
    it.originalSrc2 = x;
  }

  it.srcChanged(); /* yyy */

  return it;
}

//

function iterableEval()
{
  let it = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  it._iterableEval();
  if( it.secondCoerce() )
  it._iterableEval();

  _.assert( it.iterable >= 0 );
}

//

function _iterableEval()
{
  let it = this;
  it.iterable = null;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  if( _.mapIs( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.aux;
    it.iterable = it.containerNameToIdMap.aux;
  }
  else if( _.entity.methodEqualOf( it.src ) && !_.aux.is( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.object;
    it.iterable = it.containerNameToIdMap.object;
  }
  else if( _.hashMapLike( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.hashMap;
    it.iterable = it.containerNameToIdMap.hashMap
  }
  else if( _.setLike( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.set;
    it.iterable = it.containerNameToIdMap.set;
  }
  else if( it.isCountable( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.countable;
    it.iterable = it.containerNameToIdMap.countable;
  }
  else if( _.primitiveIs( it.src ) )
  {
    it.type1 = 0;
    it.iterable = 0;
  }
  else if( _.aux.is( it.src ) )
  {
    it.type1 = it.containerNameToIdMap.aux;
    it.iterable = it.containerNameToIdMap.aux;
  }
  else
  {
    it.type1 = it.containerNameToIdMap.object;

    if( it.containing === 'only' )
    it.iterable = it.containerNameToIdMap.aux;

    if( !it.iterable )
    it.iterable = it.containerNameToIdMap.object;
  }

  if( _.entity.methodEqualOf( it.src2 ) && !_.aux.is( it.src2 ) )
  {
    it.type2 = it.containerNameToIdMap.object;
    it.iterable = it.containerNameToIdMap.object;
  }
  else if( it.isCountable( it.src2 ) )
  {
    it.type2 = it.containerNameToIdMap.countable;
  }
  else if( _.hashMapLike( it.src2 ) )
  {
    it.type2 = it.containerNameToIdMap.hashMap;
  }
  else if( _.setLike( it.src2 ) )
  {
    it.type2 = it.containerNameToIdMap.set;
  }
  else if( _.aux.is( it.src2 ) )
  {
    it.type2 = it.containerNameToIdMap.aux;
  }
  else if( _.primitiveIs( it.src2 ) )
  {
    it.type2 = 0;
  }
  else
  {
    it.type2 = it.containerNameToIdMap.object;

    if( it.iterable !== it.containerNameToIdMap.aux && it.iterable !== it.containerNameToIdMap.countable )
    {
      it.iterable = it.containerNameToIdMap.object;
    }
    else if( !it.containing || it.containing === 'only' )
    {
      it.iterable = it.containerNameToIdMap.object;
    }

  }

}

//

function visitPush()
{
  let it = this;

  if( it.iterator.visitedContainer2 )
  if( it.visitCounting && it.type2 )
  {
    it.iterator.visitedContainer2.push( it.originalSrc2 );
  }

  Parent.visitPush.apply( it, arguments );
}

//

function visitPop()
{
  let it = this;

  if( it.iterator.visitedContainer2 && it.iterator.revisiting !== 0 )
  if( it.visitCounting && it.type2 )
  if( _.arrayIs( it.iterator.visitedContainer2.original ) || !it.revisited )
  {
    if( _.arrayIs( it.iterator.visitedContainer2.original ) )
    _.assert
    (
      Object.is( it.iterator.visitedContainer2.original[ it.iterator.visitedContainer2.original.length-1 ], it.originalSrc2 ),
      () => `Top-most visit ${it.path} does not match`
      + `${_.entity.exportStringShort( it.originalSrc2 )} <> ${_.entity.exportStringShort
      (
        it.iterator.visitedContainer2.original[ it.iterator.visitedContainer2.original.length-1 ]
      )}`
    );
    it.iterator.visitedContainer2.pop( it.originalSrc2 );
  }

  Parent.visitPop.apply( it, arguments );
}

//

function visitUp()
{
  let it = this;

  it.visitUpBegin();

  _.assert( _.routineIs( it.onUp ) );
  let r = it.onUp.call( it, it.src, it.key, it );
  _.assert( r === undefined );

  it.equalUp();

  it.visitUpEnd()
}

//

function visitDown()
{
  let it = this;
  it.visitDownBegin();

  _.assert( it.visiting );
  if( it.visiting )
  if( it.onDown )
  {
    let r = it.onDown.call( it, it.src, it.key, it );
    _.assert( r === undefined );
  }

  it.equalDown();

  it.visitDownEnd();
  return it;
}

//

function stop( result )
{
  let it = this;

  _.assert( arguments.length === 1 );
  _.assert( _.boolIs( result ) );

  if( !result )
  _.debugger;

  if( it.containing )
  {

    if( it.containing === 'any' )
    {
      let any =
      [
        it.containerNameToIdMap.aux,
        containerNameToIdMap.hashMap,
        containerNameToIdMap.set,
        containerNameToIdMap.object
      ];
      if( it.down && _.longHasAny( any, it.down.iterable ) )
      {
        it.result = false;
        it.result = it.result || result;
        if( it.result )
        {
          it.continue = false;
          if( it.down )
          {
            it.down.result = it.result;
            it.down.continue = false;
          }
        }
        return result;
      }
    }
    else if( it.containing === 'none' )
    {
      let any =
      [
        it.containerNameToIdMap.aux,
        containerNameToIdMap.hashMap,
        containerNameToIdMap.set,
        containerNameToIdMap.object
      ];
      if( it.down && _.longHasAny( any, it.down.iterable ) )
      {
        result = !result;
        it.result = it.result && result;
        if( !it.result )
        {
          it.iterator.continue = false;
          it.continue = false;
        }
        return result;
      }
    }

  }

  it.result = it.result && result;
  if( !it.result )
  it.iterator.continue = false;
  it.continue = false;

  return result;
}

//

function downUpdate()
{
  let it = this;

  if( it.down )
  it.down.result = it.down.result && it.result;

}

//

function equalUp()
{
  let it = this;

  _.assert( it.ascending === true );
  _.assert( arguments.length === 0, 'Expects no arguments' );

  /* if containing mode then src2 could even don't have such entry */

  if( it.containing )
  if( it.down && it.down.iterable === it.containerNameToIdMap.aux )
  {
    if( !( it.key in it.down.src2 ) )
    {
      return it.stop( false );
    }
  }

  /* */

  if( Object.is( it.src, it.src2 ) )
  {
    return it.stop( true );
  }

  /* fast comparison if possible */

  if( it.strictTyping )
  {

    if( _ObjectToString.call( it.src ) !== _ObjectToString.call( it.src2 ) )
    return it.stop( false );

  }
  else
  {
    if( !it.type1 || !it.type2 )
    {
      if
      (
        it.src === null
        || it.src === undefined
        || it.src2 === null
        || it.src2 === undefined
      )
      return it.stop( it.src === it.src2 );
    }
  }

  /* */

  it.containerIdToEqual[ it.iterable ].call( it );

  it.equalCycle();

}

//

function equalDown()
{
  let it = this;

  _.assert( it.ascending === false );
  _.assert( arguments.length === 0, 'Expects no arguments' );

  it.downUpdate();

}

//

function equalCycle()
{
  let it = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  if( !it.revisited )
  return;
  if( !it.result )
  return;

  /* if cycled and strict cycling */
  if( it.strictCycling )
  {
    /* if opposite branch was cycled earlier */
    if( it.down.src2 !== undefined )
    if( it.iterator.visitedContainer2 )
    {
      if( _.arrayIs( it.iterator.visitedContainer2.original ) )
      {
        let i = it.iterator.visitedContainer2.original.indexOf( it.down.src2 );
        if( 0 <= i && i <= it.iterator.visitedContainer2.original.length-2 )
        {
          it.result = false;
          it.iterator.continue = false;
          it.continue = false;
        }
      }
      else
      {
        /* qqq : cover revisiting : 0, ask how */
        if( it.iterator.visitedContainer2 && it.iterator.visitedContainer2.has( it.down.originalSrc2 ) )
        {
          it.result = false;
          it.iterator.continue = false;
          it.continue = false;
        }
      }
    }
    /* or not yet cycled */
    if( it.result )
    {
      if( it.iterator.visitedContainer2 && _.arrayIs( it.iterator.visitedContainer2.original ) )
      {
        it.result = it
        .iterator
        .visitedContainer2
        .original[ it.visitedContainer.original.indexOf( it.originalSrc ) ] === it.originalSrc2;
      }
      if( !it.result )
      {
        it.iterator.continue = false;
        it.continue = false;
      }
    }
    /* then not equal otherwise equal */
  }
  else
  {
    if( it.level >= it.recursive )
    {
      let containing = it.containing;
      if( containing === 'only' )
      {
        _.assert( 0, 'not tested' ); /* qqq : cover */
        containing = 'all';
      }
      it.result = it.reperform( it.src2, it.src, { recursive : 0, containing } ) && it.result;
      if( !it.result )
      {
        it.iterator.continue = false;
        it.continue = false;
      }
      if( _global_.debugger )
      debugger;
    }
  }

}

//

// function reperform()
// {
//   let it = this;
//
//   _.assert( arguments.length === 1 );
//   _.assert( it.selector !== null, () => `Iteration is not looked` );
//   _.assert
//   (
//     it.iterationProper( it ),
//     () => `Expects iteration of ${Self.constructor.name} but got ${_.entity.exportStringShort( it )}`
//   );
//
//   let it2 = it.iterationMake();
//   let args = _.longSlice( arguments );
//   if( args.length === 1 && !_.objectIs( args[ 0 ] ) )
//   args = [ it.src, args[ 0 ] ];
//   let o = Self.optionsFromArguments( args );
//   o.Looker = o.Looker || it.Looker || Self;
//
//   _.assert( _.mapIs( o ) );
//   _.assertMapHasOnly( o, { src : null, selector : null, Looker : null }, 'Implemented only for options::selector' );
//   _.assert( _.strIs( o.selector ) );
//   _.assert( _.strIs( it2.iterator.selector ) );
//
//   it2.iterator.selector = it2.iterator.selector + _.strsShortest( it2.iterator.upToken ) + o.selector;
//   // it2.iterator.prevSelectIteration = it;
//   it2.iteratorSelectorChanged();
//   it2.chooseRoot( it2.src );
//   it2.iterate();
//
//   return it2.lastIt;
// }

//

/* xxx : improve */
function reperform()
{
  let it = this;

  _.assert( arguments.length === 3 );
  _.assert( it.selector !== null, () => `Iteration is not looked` );
  _.assert
  (
    it.iterationProper( it ),
    () => `Expects iteration of ${Self.constructor.name} but got ${_.entity.exportStringShort( it )}`
  );

  let o = arguments[ 2 ];
  o.Looker = o.Looker || it.Looker || Self;

  o.src = arguments[ 0 ];
  o.src2 = arguments[ 1 ];

  _.assert( _.mapIs( o ) );
  _.assertMapHasOnly( o, o.Looker, 'Implemented only for options::selector' );

  _.assert( it.iterator.continue === true );

  /* xxx : move out */
  let iterator2 = Object.create( it.iterator );
  iterator2.iterator = iterator2;
  iterator2.iterationPrototype = Object.create( iterator2 );
  Object.assign( iterator2.iterationPrototype, iterator2.Looker.Iteration );
  Object.preventExtensions( iterator2.iterationPrototype );

  _.mapExtend( iterator2, o );
  let it2 = iterator2.iteratorIterationMake();
  _.assert( it2.iterator === iterator2 );
  it2.src = o.src;
  it2.src2 = o.src2;
  it2.chooseRoot( o.src );
  _.assert( it.Looker.iterationProper( it2 ) );

  it2.iterate();

  _.assert( it.iterator.continue === true );
  return it2.result;
}

//

function secondCoerce()
{
  let it = this;

  if( !_.primitiveIs( it.src ) && _.routineIs( it.src[ equalSecondCoerceSymbol ] ) )
  {
    it.src[ equalSecondCoerceSymbol ]( it );
    return true;
  }

  if( !_.primitiveIs( it.src2 ) && _.routineIs( it.src2[ equalSecondCoerceSymbol ] ) )
  {
    it.src2[ equalSecondCoerceSymbol ]( it );
    return true;
  }

  return false;
}

//

function equalSets()
{
  let it = this;
  let unpaired1 = new Set();
  let unpaired2 = new Set();

  _.assert( arguments.length === 0, 'Expects no arguments' );

  if( !_.setLike( it.src2 ) )
  return it.stop( false );

  if( it.containing )
  {
    if( it.containing === 'all' || it.containing === 'only' )
    {
      if( it.src.size > it.src2.size )
      return it.stop( false );
    }
  }
  else
  {
    if( it.src.size !== it.src2.size )
    return it.stop( false );
  }

  _.assert( _.setLike( it.src ) );
  _.assert( _.setLike( it.src2 ) );
  _.assert( !it.containing, 'not implemented' );

  for( let e of it.src )
  unpaired1.add( e );
  for( let e of it.src2 )
  unpaired2.add( e );

  for( let e of unpaired1 )
  {
    if( unpaired2.has( e ) )
    pairFound( e, e );
  }

  for( let e1 of unpaired1 )
  {
    let found = false;
    for( let e2 of unpaired2 )
    {
      if( equal( e1, e2 ) ) /* xxx : improve? */
      {
        pairFound( e1, e2 );
        found = true;
        break;
      }
    }
    if( !found )
    return it.stop( false );
  }

  if( unpaired1.size || unpaired2.size )
  return it.stop( false );

  it.continue = false;
  return true;

  /* */

  function pairFound( e1, e2 )
  {
    unpaired1.delete( e1 );
    unpaired2.delete( e2 );
  }

  function equal( e1, e2 )
  {
    return it.reperform( e1, e2, {} );
  }

}

//

function equalCountable()
{
  let it = this;

  if( !it.src2 )
  return it.stop( false );

  if( it.strictContainer )
  {

    if( _.bufferAnyIs( it.src ) || _.bufferAnyIs( it.src2 ) )
    return it.equalBuffers();

    if( !it.isCountable( it.src2 ) )
    return it.stop( false );

  }
  else
  {

    if( !it.type1 || !it.type2 )
    return it.stop( false );

    if( !_.vectorLike( it.src2 ) && !_.entity.methodIteratorOf( it.src2 ) )
    return it.stop( false );

  }

  if( it.containing )
  {
    if( it.containing === 'all' || it.containing === 'only' )
    {
      if( _.container.lengthOf( it.src ) > _.container.lengthOf( it.src2 ) )
      return it.stop( false );
    }
  }
  else
  {
    if( _.container.lengthOf( it.src ) !== _.container.lengthOf( it.src2 ) )
    return it.stop( false );
  }

}

//

function equalHashes()
{
  let it = this;
  let unpaired1 = new HashMap();
  let unpaired2 = new HashMap();

  _.assert( arguments.length === 0, 'Expects no arguments' );

  if( !_.hashMapLike( it.src2 ) )
  return it.stop( false );

  if( it.containing )
  {
    if( it.containing === 'all' || it.containing === 'only' )
    {
      debugger;
      if( it.src.size > it.src2.size )
      return it.stop( false );
    }
  }
  else
  {
    if( it.src.size !== it.src2.size )
    return it.stop( false );
  }

  _.assert( _.hashMapLike( it.src ) );
  _.assert( _.hashMapLike( it.src2 ) );
  _.assert( !it.containing, 'not implemented' );

  for( let [ k, e ] of it.src )
  unpaired1.set( k, e );
  for( let [ k, e ] of it.src2 )
  unpaired2.set( k, e );

  for( let [ k1, e1 ] of unpaired1 )
  {
    if( !unpaired2.has( k1 ) )
    continue;
    let e2 = unpaired2.get( k1 );
    if( !equal( e1, e2 ) )
    return it.stop( false );
    pairFound( k1, k1 );
  }

  for( let [ k1, e1 ] of unpaired1 )
  {
    let found = false;
    for( let [ k2, e2 ] of unpaired1 )
    {
      if( !equal( k1, k2 ) )
      continue;
      if( !equal( e1, e2 ) )
      continue;
      pairFound( k1, k2 );
    }
    if( !found )
    return it.stop( false );
  }

  if( unpaired1.size || unpaired2.size )
  return it.stop( false );

  return true;

  /* */

  function pairFound( k1, k2 )
  {
    unpaired1.delete( k1 );
    unpaired2.delete( k2 );
  }

  /* */

  function equal( e1, e2 )
  {
    return it.reperform( e1, e2, {} );
  }

}

//

function equalAuxiliary()
{
  let it = this;
  let types =
  [
    it.containerNameToIdMap.aux,
    it.containerNameToIdMap.object,
  ];

  _.assert( _.longHas( types, it.iterable ) );

  if( !_.longHas( types, it.type1 ) || !_.longHas( types, it.type2 ) )
  return it.stop( false );

  if( it.containing )
  {

    if( it.containing === 'only' )
    {
      debugger;
      if( _.aux.is( it.src ) && !_.aux.is( it.src2 ) )
      return it.stop( true );
    }
    else
    {
      if( !_.aux.is( it.src ) && _.aux.is( it.src2 ) )
      return it.stop( false );
    }

    if( it.containing === 'all' || it.containing === 'only' )
    {
      if( it.type1 !== it.containerNameToIdMap.object || _.routineIs( it.src[ equalAreSymbol ] ) || 'length' in it.src )
      if( it.type2 !== it.containerNameToIdMap.object || _.routineIs( it.src2[ equalAreSymbol ] ) || 'length' in it.src2 )
      if( _.lengthOf( it.src ) > _.lengthOf( it.src2 ) )
      return it.stop( false );
    }

  }
  else
  {

    if( it.strictTyping )
    {
      /*
      there is no such check in contain branch because
      second argument of contain-comparison does not have to be object, but may be auxiliary to give true
      */
      if( _.mapIs( it.src ) ^ _.mapIs( it.src2 ) )
      return it.stop( false );
      if( _.mapKeys( it.src ).length !== _.mapKeys( it.src2 ).length )
      return it.stop( false );
      if( _.mapOnlyOwnKeys( it.src ).length !== _.mapOnlyOwnKeys( it.src2 ).length )
      return it.stop( false );
    }
    else
    {
      if( !it.type1 || !it.type2 )
      return it.stop( false );
      if( _.mapKeys( it.src ).length !== _.mapKeys( it.src2 ).length )
      return it.stop( false );
    }

  }

}

//

function equalObjects()
{
  let it = this;

  _.assert
  (
    it.iterable === it.containerNameToIdMap.object
  );

  if( it.src && _.routineIs( it.src[ equalAreSymbol ] ) )
  {
    _.assert( it.src[ equalAreSymbol ].length <= 1 );
    let r = it.src[ equalAreSymbol ]( it );
    _.assert( r === undefined, `Equalizer should return undefined, but it returned ${_.entity.strType( r )}` );
  }
  else if( it.src2 && _.routineIs( it.src2[ equalAreSymbol ] ) )
  {
    _.assert( it.src2[ equalAreSymbol ].length <= 1 );
    let r = it.src2[ equalAreSymbol ]( it );
    _.assert( r === undefined, `Equalizer should return undefined, but it returned ${_.entity.strType( r )}` );
  }
  else if( _.regexpIs( it.src ) )
  {
    return it.equalRegexps();
  }
  else if( _.dateIs( it.src ) )
  {
    return it.equalDates();
  }
  else if( _.bufferAnyIs( it.src ) )
  {
    return it.equalBuffers();
  }
  else
  {
    if( !_.entity.methodIteratorOf( it.src ) )
    return it.stop( false );
  }

}

//

function equalTerminals()
{
  let it = this;

  if( it.type1 || it.type2 )
  return it.stop( false );

  if( _.strIs( it.src ) )
  {
    if( !_.strIs( it.src2 ) )
    return it.stop( false );
    return it.stop( it.onStringsAreEqual( it.onStringPreprocess( it.src ), it.onStringPreprocess( it.src2 ) ) );
  }
  else if( it.strictTyping && ( _.boolIs( it.src ) || _.boolIs( it.src2 ) ) )
  {
    it.stop( it.src === it.src2 );
  }
  else if( !it.strictTyping && ( _.boolIs( it.src ) || _.boolIs( it.src2 ) ) )
  {
    if( !_.boolLike( it.src ) || !_.boolLike( it.src2 ) )
    it.stop( false );
    else /* Yevhen : case 1 and true or false and 0 */
    it.stop
    (
      ( _.boolLikeTrue( it.src ) && _.boolLikeTrue( it.src2 ) )
      || ( _.boolLikeFalse( it.src ) && _.boolLikeFalse( it.src2 ) )
    )
  }
  else if( _.numberIs( it.src ) || _.bigIntIs( it.src ) )
  {
    return it.stop( it.onNumbersAreEqual( it.src, it.src2 ) );
  }
  else
  {
    if( it.strictTyping )
    return it.stop( it.src === it.src2 );
    else
    return it.stop( it.src === it.src2 );
  }

}

//

function equalRegexps()
{
  let it = this;
  if( it.strictTyping )
  return it.stop( _.regexpIdentical( it.src, it.src2 ) );
  else
  return it.stop( _.regexpEquivalent( it.src, it.src2 ) );
}

//

function equalDates()
{
  let it = this;
  it.stop( _.datesAreIdentical( it.src, it.src2 ) );
}

//

function equalBuffers()
{
  let it = this;

  if( it.strictNumbering && it.strictTyping )
  {
    return it.stop( _.buffersAreIdentical( it.src, it.src2 ) );
  }
  else
  {

    if( it.strictTyping )
    {
      return it.stop( _.buffersAreEquivalent( it.src, it.src2, it.strictNumbering ? 0 : it.accuracy ) );
    }
    else
    {
      let src1 = it.src;
      let src2 = it.src2;
      if( !_.longIs( src1 ) && _.entity.methodIteratorOf( src1 ) )
      src1 = [ ... src1 ];
      if( !_.longIs( src2 ) && _.entity.methodIteratorOf( src2 ) )
      src2 = [ ... src2 ];
      return it.stop( _.buffersAreEquivalent( src1, src2, it.strictNumbering ? 0 : it.accuracy ) );
    }

  }

}

//

function _objectAscend( src )
{
  let it = this;

  _.assert( it.iterator.continue === true );
  _.assert( it.continue === true );
  _.assert( arguments.length === 1 );

  if( _.entity.methodIteratorOf( src ) )
  {

    let index = 0;
    for( let e of src )
    {
      let eit = it.iterationMake().choose( e, index );
      eit.iterate();
      index += 1;
      if( !it.canSibling() )
      break;
    }

  }

}

// --
// relations
// --

_.assert( !!_.looker.Looker.containerIdToNameMap[ 4 ] );
_.assert( !_.looker.Looker.containerIdToNameMap[ 5 ] );

let last = _.looker.Looker.containerNameToIdMap.last;
let equalAreSymbol = Symbol.for( 'equalAre' );
let equalSecondCoerceSymbol = Symbol.for( 'equalSecondCoerce' );

let containerNameToIdMap =
{
  ... _.looker.Looker.containerNameToIdMap,
  'object' : last+1,
  'last' : last+1,
}

_.assert( containerNameToIdMap.hashMap >= 0 );

let containerIdToNameMap =
{
  ... _.looker.Looker.containerIdToNameMap,
  [ last+1 ] : 'object',
}

let containerIdToAscendMap =
{
  ... _.looker.Looker.containerIdToAscendMap,
  [ last+1 ] : _objectAscend,
}

let containerIdToEqual =
{
  [ containerNameToIdMap.terminal ] : equalTerminals,
  [ containerNameToIdMap.countable ] : equalCountable,
  [ containerNameToIdMap.aux ] : equalAuxiliary,
  [ containerNameToIdMap.hashMap ] : equalHashes,
  [ containerNameToIdMap.set ] : equalSets,
  [ containerNameToIdMap.object ] : equalObjects,
}

//

let LookerExtension =
{

  constructor : function Equaler(){},
  head,
  optionsFromArguments,
  optionsForm,
  optionsToIteration,
  performBegin,
  performEnd,
  chooseBegin,
  chooseRoot,
  iterableEval,
  _iterableEval, /* xxx : remove? */
  visitPush,
  visitPop,
  visitUp,
  visitDown,
  stop,
  downUpdate,
  equalUp,
  equalDown,
  equalCycle,
  reperform, /* xxx : improve */
  secondCoerce,
  equalSets,
  equalCountable,
  equalHashes,
  equalAuxiliary,
  equalObjects,
  equalTerminals,
  equalRegexps,
  equalDates,
  equalBuffers,
  _objectAscend,

  // feilds

  containerNameToIdMap,
  containerIdToNameMap,
  containerIdToAscendMap,
  containerIdToEqual,

}

let Iterator =
{

  //

  visitedContainer2 : null,

  // defaults fields

  src : null,
  src2 : null,
  containing : 0,
  strict : 1,
  revisiting : 1,
  strictTyping : null,
  strictNumbering : null,
  strictCycling : null,
  strictString : null,
  strictContainer : null,
  withImplicit : null,
  withCountable : 'countable',
  accuracy : 1e-7,
  recursive : Infinity,
  onNumbersAreEqual : null,
  onStringsAreEqual : null,
  onStringPreprocess : null,

}

let Iteration = Object.create( null );
Iteration.result = true;
Iteration.originalSrc2 = null; /* qqq : cover the field */
Iteration.type1 = null;
Iteration.type2 = null;

let IterationPreserve = Object.create( null );
IterationPreserve.src2 = null;

const Equaler = _.looker.classDefine
({
  name : 'Equaler',
  parent : _.looker.Looker,
  prime : Prime,
  looker : LookerExtension,
  iterator : Iterator,
  iteration : Iteration,
  iterationPreserve : IterationPreserve,
});

// --
//
// --

function _equal_head( routine, args )
{
  return routine.defaults.head( routine, args );
}

//

function _equalIt_body( it )
{
  let it2 = _.look.body( it );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( it2 === it );
  return it;
}

_equalIt_body.defaults = Equaler;

let _equalIt = _.routine.uniteReplacing( _equal_head, _equalIt_body );

_.assert( _equalIt_body.defaults === Equaler );
_.assert( _equalIt.body.defaults === Equaler );
_.assert( _equalIt.defaults === Equaler );

//

function _equal_body( it )
{
  it = _.equaler._equalIt.body( it );
  return it.result;
  // return it.result === _.dont ? false : it.result; /* yyy : remove */
}

_equal_body.defaults = Equaler;

let _equal = _.routine.uniteReplacing( _equal_head, _equal_body );

//

/**
 * Deep strict comparsion of two entities. Uses recursive comparsion for objects, arrays and array-like objects.
 * Returns true if entities are identical.
 *
 * @param {*} src - Entity for comparison.
 * @param {*} src2 - Entity for comparison.
 * @param {wTools~entityEqualOptions} options - Comparsion options {@link wTools~entityEqualOptions}.
 * @param {boolean} [ options.strictTyping = true ] - Method uses strict equality mode( '===' ).
 * @returns {boolean} result - Returns true for identical entities.
 *
 * @example
 * //returns true
 * let src1 = { a : 1, b : { a : 1, b : 2 } };
 * let src2 = { a : 1, b : { a : 1, b : 2 } };
 * _.entityIdentical( src1, src2 ) ;
 *
 * @example
 * //returns false
 * let src1 = { a : '1', b : { a : 1, b : '2' } };
 * let src2 = { a : 1, b : { a : 1, b : 2 } };
 * _.entityIdentical( src1, src2 ) ;
 *
 * @function entityIdentical
 * @function identical
 * @throws {exception} If( arguments.length ) is not equal 2 or 3.
 * @throws {exception} If( options ) is extended by unknown property.
 * @namespace Tools
 * @module Tools/base/Equaler
*/

let entityIdentical = _.routine.uniteInheriting( _equal_head, _equal_body );
var defaults = entityIdentical.defaults;
defaults.strict = 1;
defaults.Looker = defaults;

//

function entityNotIdentical( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotIdentical, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotIdentical, entityIdentical );

//

/**
 * Deep soft comparsion of two entities. Uses recursive comparsion for objects, arrays and array-like objects.
 * By default uses own( onNumbersAreEqual ) routine to compare numbers using( options.accuracy ). Returns true if two numbers are NaN, strict equal or
 * ( a - b ) <= ( options.accuracy ). For example: '_.entityEquivalent( 1, 1.5, { accuracy : .5 } )' returns true.
 *
 * @param {*} src1 - Entity for comparison.
 * @param {*} src2 - Entity for comparison.
 * @param {wTools~entityEqualOptions} options - Comparsion options {@link wTools~entityEqualOptions}.
 * @param {boolean} [ options.strict = false ] - Method uses( '==' ) equality mode .
 * @param {number} [ options.accuracy = 1e-7 ] - Maximal distance between two numbers.
 * Example: If( options.accuracy ) is '1e-7' then 0.99999 and 1.0 are equivalent.
 * @returns {boolean} Returns true if entities are equivalent.
 *
 * @example
 * //returns true
 * _.entityEquivalent( 2, 2.1, { accuracy : .2 } );
 *
 * @example
 * //returns true
 * _.entityEquivalent( [ 1, 2, 3 ], [ 1.9, 2.9, 3.9 ], { accuracy : 0.9 } );
 *
 * @function entityEquivalent
 * @throws {exception} If( arguments.length ) is not equal 2 or 3.
 * @throws {exception} If( options ) is extended by unknown property.
 * @namespace Tools
 * @module Tools/base/Equaler
*/

let entityEquivalent = _.routine.uniteInheriting( _equal_head, _equal_body );

var defaults = entityEquivalent.defaults;
defaults.strict = 0;
defaults.Looker = defaults;

//

function entityNotEquivalent( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotEquivalent, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotEquivalent, entityEquivalent );

//

/**
 * Deep contain comparsion of two entities. Uses recursive comparsion for objects, arrays and array-like objects.
 * Returns true if entity( src1 ) contains keys/values from entity( src2 ) or they are indentical.
 *
 * @param {*} src1 - Entity for comparison.
 * @param {*} src2 - Entity for comparison.
 * @param {wTools~entityEqualOptions} opts - Comparsion options {@link wTools~entityEqualOptions}.
 * @param {boolean} [ opts.strict = true ] - Method uses strict( '===' ) equality mode .
 * @param {boolean} [ opts.containing = true ] - Check if( src1 ) contains  keys/indexes and same appropriates values from( src2 ).
 * @returns {boolean} Returns boolean result of comparison.
 *
 * @example
 * //returns true
 * _.entityContains( [ 1, 2, 3 ], [ 1 ] );
 *
 * @example
 * //returns false
 * _.entityContains( [ 1, 2, 3 ], [ 1, 4 ] );
 *
 * @example
 * //returns true
 * _.entityContains( { a : 1, b : 2 }, { a : 1 , b : 2 }  );
 *
 * @function entityContains
 * @throws {exception} If( arguments.length ) is not equal 2 or 3.
 * @throws {exception} If( opts ) is extended by unknown property.
 * @namespace Tools
 * @module Tools/base/Equaler
*/

function entityContains( src, src2, opts )
{
  let it = _equal.head.call( this, entityContains, arguments );
  let result = _equal.body.call( this, it );
  return result;
}

_.routine.extendInheriting( entityContains, _equal );

var defaults = entityContains.defaults;
defaults.containing = 'all';
defaults.strict = 1;
defaults.strictTyping = 0;
defaults.strictNumbering = 0;
defaults.strictString = 0;
defaults.strictCycling = 1;
defaults.strictContainer = 0; /* qqq : cover option strictContainer */
defaults.Looker = defaults;

_.assert( entityContains.defaults.containing === 'all' );

//

function entityNotContains( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotContains, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotContains, entityContains );

//

function entityContainsAll( src, src2, opts )
{
  let it = _equal.head.call( this, entityContainsAll, arguments );
  let result = _equal.body.call( this, it );
  return result;
}

_.routine.extendInheriting( entityContainsAll, entityContains );

var defaults = entityContainsAll.defaults;
defaults.containing = 'all';
defaults.Looker = defaults;

//

function entityNotContainsAll( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotContainsAll, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotContainsAll, entityContainsAll );

//

function entityContainsAny( src, src2, opts )
{
  let it = _equal.head.call( this, entityContainsAny, arguments );
  let result = _equal.body.call( this, it );
  return result;
}

_.assert( entityContains.defaults.containing === 'all' );

_.routine.extendInheriting( entityContainsAny, entityContains );

var defaults = entityContainsAny.defaults;
defaults.containing = 'any';
defaults.Looker = defaults;

_.assert( entityContains.defaults !== entityContainsAny.defaults );
_.assert( entityContains.defaults.containing === 'all' );

//

function entityNotContainsAny( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotContainsAny, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotContainsAny, entityContainsAny );

//

function entityContainsOnly( src, src2, opts )
{
  let it = _equal.head.call( this, entityContainsOnly, arguments );
  let result = _equal.body.call( this, it );
  return result;
}

_.routine.extendInheriting( entityContainsOnly, entityContains );

var defaults = entityContainsOnly.defaults;
defaults.containing = 'only';
defaults.Looker = defaults;

//

function entityNotContainsOnly( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotContainsOnly, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotContainsOnly, entityContainsOnly );

//

function entityContainsNone( src, src2, opts )
{
  let it = _equal.head.call( this, entityContainsNone, arguments );
  let result = _equal.body.call( this, it );
  return result;
}

_.routine.extendInheriting( entityContainsNone, entityContains );

var defaults = entityContainsNone.defaults;
defaults.containing = 'none';
defaults.Looker = defaults;

//

function entityNotContainsNone( src, src2, opts )
{
  let it = _equal.head.call( this, entityNotContainsNone, arguments );
  let result = _equal.body.call( this, it );
  it.result = !it.result;
  return !result;
}

_.routine.extendReplacing( entityNotContainsNone, entityContainsNone );

_.assert( entityContains.defaults.containing === 'all' );
_.assert( entityContainsNone.defaults.containing === 'none' );
_.assert( entityNotContainsNone.defaults.containing === 'none' );

// --
//
// --

Equaler.exec = _equalIt;

let EqualerExtension =
{

  name : 'equaler',
  Equaler,

  _equalIt,
  _equal,

  identical : entityIdentical,
  notIdentical : entityNotIdentical,
  equivalent : entityEquivalent,
  notEquivalent : entityNotEquivalent,

  contains : entityContains,
  notContains : entityNotContains,
  containsAll : entityContainsAll,
  notContainsAll : entityNotContainsAll,
  containsAny : entityContainsAny,
  notContainsAny : entityNotContainsAny,
  containsOnly : entityContainsOnly,
  notContainsOnly : entityNotContainsOnly,
  containsNone : entityContainsNone,
  notContainsNone : entityNotContainsNone,

  diff : entityDiff,
  diffExplanation : entityDiffExplanation, /* qqq : cover and extend */

}

let EntityExtension =
{

  identical : entityIdentical,
  notIdentical : entityNotIdentical,
  equivalent : entityEquivalent,
  notEquivalent : entityNotEquivalent,

  contains : entityContains,
  notContains : entityNotContains,
  containsAll : entityContainsAll,
  notContainsAll : entityNotContainsAll,
  containsAny : entityContainsAny,
  notContainsAny : entityNotContainsAny,
  containsOnly : entityContainsOnly,
  notContainsOnly : entityNotContainsOnly,
  containsNone : entityContainsNone,
  notContainsNone : entityNotContainsNone,

  diff : entityDiff,
  diffExplanation : entityDiffExplanation,

}

let ToolsExtension =
{

  identical : entityIdentical,
  entityIdentical,
  notIdentical : entityNotIdentical,
  entityNotIdentical,
  equivalent : entityEquivalent,
  entityEquivalent,
  notEquivalent : entityNotEquivalent,
  entityNotEquivalent,

  contains : entityContains,
  entityContains,
  notContains : entityNotContains,
  entityNotContains,
  containsAll : entityContainsAll,
  entityContainsAll,
  notContainsAll : entityNotContainsAll,
  entityNotContainsAll,
  containsAny : entityContainsAny,
  entityContainsAny,
  notContainsAny : entityNotContainsAny,
  entityNotContainsAny,
  containsOnly : entityContainsOnly,
  entityContainsOnly,
  notContainsOnly : entityNotContainsOnly,
  entityNotContainsOnly,
  containsNone : entityContainsNone,
  entityContainsNone,
  notContainsNone : entityNotContainsNone,
  entityNotContainsNone,

  diff : entityDiff,
  entityDiff,
  diffExplanation : entityDiffExplanation,
  entityDiffExplanation,

}

let Self = Equaler;
_.mapExtend( _.equaler, EqualerExtension );
_.mapExtend( _.entity, EntityExtension );
_.mapExtend( _, ToolsExtension );

// --
// export
// --

if( typeof module !== 'undefined' )
module[ 'exports' ] = _;

})();
