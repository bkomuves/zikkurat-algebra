
// elliptic curve "BN128 ( Fp2 ) " in affine coordinates, Montgomery field representation
//
// NOTES:
//  - generated code, do not edit!
//  - the point at infinity is represented by the special string 0xffff ..fffff
//    this is not a valid value for prime fields, so it's OK as long as we always check for it

#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "bn128_G2_affine.h"
#include "bn128_G2_proj.h"
#include "bn128_Fp2_mont.h"
#include "bn128_Fr_mont.h"

#define NLIMBS_P 8
#define NLIMBS_R 4

#define X1 (src1)
#define Y1 (src1 + 8)

#define X2 (src2)
#define Y2 (src2 + 8)

#define X3 (tgt)
#define Y3 (tgt + 8)

// the generator of the subgroup G2
const uint64_t bn128_G2_affine_gen_G2[24] = { 0xaf2f35351efbe5db, 0x66a2e3e98253e7ad, 0x36701d8c0c66d66d, 0x128787e74c6d089f, 0x4560607a2d4afc95, 0x58dd4111299cc567, 0xb028be49345b3b5f, 0x0875b5e4294a6cdd, 0x71a551578f9ba639, 0xd03ece4a4bffb6c4, 0x957d3a7a01ba9551, 0x2a613ea3aa6bbddf, 0x9f0a4cbbfbeae987, 0xa5471bec20650a0b, 0xafa055cd8bd3c0dd, 0x1e979413b23ade5e, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000 };

// the cofactor of the curve subgroup = 21888242871839275222246405745257275088844257914179612981679871602714643921549
const uint64_t bn128_G2_affine_cofactor[8] = { 0x345f2299c0f9fa8d, 0x06ceecda572a2489, 0xb85045b68181585e, 0x30644e72e131a029, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000 };

// the constants A and B of the equation
const uint64_t bn128_G2_affine_const_A[8] = { 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000 };
const uint64_t bn128_G2_affine_const_B[8] = { 0x3bf938e377b802a8, 0x020b1b273633535d, 0x26b7edf049755260, 0x2514c6324384a86d, 0x38e7ecccd1dcff67, 0x65f0b37d93ce0d3e, 0xd749d0dd22ac00aa, 0x0141b9ce4a688d4d };
const uint64_t bn128_G2_affine_const_3B[8] = { 0x3baa927cb62e0d6a, 0xd71e7c52d1b664fd, 0x03873e63d95d4664, 0x0e75b5b1082ab8f4, 0xaab7c6667596fe35, 0x31d21a78bb6a27ba, 0x85dd7297680401ff, 0x03c52d6adf39a7e9 };

//------------------------------------------------------------------------------

void bn128_G2_affine_set_ffff( uint64_t *tgt ) {
  memset( tgt, 0xff, 64 );
}

uint8_t bn128_G2_affine_is_ffff( const uint64_t *src ) {
  return ( (src[0] + 1 == 0) && (src[1] + 1 == 0) && (src[2] + 1 == 0) && (src[3] + 1 == 0) && (src[4] + 1 == 0) && (src[5] + 1 == 0) && (src[6] + 1 == 0) && (src[7] + 1 == 0) );
}

// checks whether two curve points are equal
uint8_t bn128_G2_affine_is_equal( const uint64_t *src1, const uint64_t *src2 ) {
  return ( bn128_Fp2_mont_is_equal( X1, X2 ) &&
           bn128_Fp2_mont_is_equal( Y1, Y2 ) );
}

// checks whether the underlying representation is the same
uint8_t bn128_G2_affine_is_same( const uint64_t *src1, const uint64_t *src2 ) {
  return bn128_G2_affine_is_equal( src1, src2 );
}

uint8_t bn128_G2_affine_is_infinity ( const uint64_t *src1 ) {
  return ( bn128_G2_affine_is_ffff( X1 ) &&
           bn128_G2_affine_is_ffff( Y1 ) );
}

// convert from the more standard convention of encoding infinity as (0,0)
// to our convention (0xffff...,0xffff...). TODO: maybe change our convention
// to the more standard one?
void bn128_G2_affine_convert_infinity_inplace( uint64_t *tgt) 
{ if ( (bn128_Fp2_mont_is_zero(tgt           ) ) && 
       (bn128_Fp2_mont_is_zero(tgt + NLIMBS_P) ) ) {
    bn128_G2_affine_set_infinity(tgt);
  }
}

void bn128_G2_affine_batch_convert_infinity_inplace( int n, uint64_t *tgt ) 
{ uint64_t *q = tgt;
  for(int i=0; i<n; i++) {
    if ( (bn128_Fp2_mont_is_zero(q           ) ) && 
         (bn128_Fp2_mont_is_zero(q + NLIMBS_P) ) ) {
      bn128_G2_affine_set_infinity(q);
    }
    q += 2*NLIMBS_P;
  }
}

void bn128_G2_affine_set_infinity ( uint64_t *tgt ) {
  bn128_G2_affine_set_ffff( X3 );
  bn128_G2_affine_set_ffff( Y3 );
}

// checks the curve equation
//   y^2 == x^3 + A*x + B
uint8_t bn128_G2_affine_is_on_curve ( const uint64_t *src1 ) {
  if (bn128_G2_affine_is_infinity(src1)) {
    return 1;
  }
  else {
    uint64_t acc[8];
    uint64_t tmp[8];
    bn128_Fp2_mont_sqr( Y1, acc );             // Y^2
    bn128_Fp2_mont_neg_inplace( acc );         // -Y^2
    bn128_Fp2_mont_sqr( X1, tmp );             // X^2
    bn128_Fp2_mont_mul_inplace( tmp, X1 );     // X^3
    bn128_Fp2_mont_add_inplace( acc, tmp );    // - Y^2 + X^3
    bn128_Fp2_mont_add_inplace( acc, bn128_G2_affine_const_B );     // - Y^2*Z + X^3 + A*X + B
    return bn128_Fp2_mont_is_zero( acc );
  }
}

// checks whether the given point is in the subgroup G1
uint8_t bn128_G2_affine_is_in_subgroup ( const uint64_t *src1 ) {
  if (!bn128_G2_affine_is_on_curve(src1)) {
    return 0;
  }
  else {
    if (bn128_G2_affine_is_infinity(src1)) {
      return 1;
    }
    else {
      uint64_t proj[24];
      uint64_t tmp [24];
      bn128_G2_proj_from_affine( src1, proj );
      bn128_G2_proj_scl_Fr_std( bn128_G2_affine_cofactor , proj , tmp );
      return bn128_G2_proj_is_infinity( tmp );
    }
  }
}

void bn128_G2_affine_copy( const uint64_t *src1 , uint64_t *tgt ) {
  if (tgt != src1) { memcpy( tgt, src1, 128 ); }
}

// negates an elliptic curve point in affine coordinates
void bn128_G2_affine_neg( const uint64_t *src1, uint64_t *tgt ) {
  if (bn128_G2_affine_is_infinity(src1)) {
    memcpy( tgt, src1, 128);
  }
  else {
    memcpy( tgt, src1, 64 );
    bn128_Fp2_mont_neg( Y1, Y3 );
  }
}

// negates an elliptic curve point in affine coordinates
void bn128_G2_affine_neg_inplace( uint64_t *tgt ) {
  if (bn128_G2_affine_is_infinity(tgt)) {
    return;
  }
  else {
    bn128_Fp2_mont_neg_inplace( Y3 );
  }
}

// doubles an affine elliptic curve point
void bn128_G2_affine_dbl( const uint64_t *src1, uint64_t *tgt ) {
  if (bn128_G2_affine_is_infinity(src1)) {
    bn128_G2_affine_copy( src1, tgt );
    return;
  }
  else {
    uint64_t  xx[8];
    uint64_t   t[8];
    uint64_t tmp[8];
    bn128_Fp2_mont_sqr( X1 , xx );            // xx = X1^2
    bn128_Fp2_mont_add( xx , xx, t );         // t  = 2*X1^2
    bn128_Fp2_mont_add_inplace( t, xx );      // t  = 3*X1^2
    bn128_Fp2_mont_add( Y1, Y1, tmp );             // tmp = 2*Y1
    bn128_Fp2_mont_div_inplace( t, tmp );          // t   = (3*X1^2 + A) / (2*Y1)
    bn128_Fp2_mont_sqr( t, tmp );                  // tmp = t^2
    bn128_Fp2_mont_sub_inplace( tmp, X1 );         // tmp = t^2 - X1
    bn128_Fp2_mont_sub_inplace( tmp, X1 );         // tmp = t^2 - 2*X1
    bn128_Fp2_mont_sub( tmp, X1 , xx );            // xx =  (t^2 - 2*X1) - X1 = X3 - X1
    bn128_Fp2_mont_mul_inplace( xx , t );          // xx = t*(X3 - X1)
    bn128_Fp2_mont_add_inplace( xx , Y1);          // xx = Y1 + t*(X3 - X1)
    bn128_Fp2_mont_copy( tmp, X3 );                // X3 = t^2 - 2*X1
    bn128_Fp2_mont_neg ( xx, Y3 );                 // Y3 = - Y1 - t*(X3 - X1)
  }
}

// doubles an elliptic curve point, in place
void bn128_G2_affine_dbl_inplace( uint64_t *tgt ) {
  bn128_G2_affine_dbl( tgt , tgt );
}

// adds two affine elliptic curve points
void bn128_G2_affine_add( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt ) {
  if (bn128_G2_affine_is_infinity(src1)) {
    // PT1 = infinity
    bn128_G2_affine_copy( src2, tgt );
    return;
  }
  if (bn128_G2_affine_is_infinity(src2)) {
    // PT2 = infinity
    bn128_G2_affine_copy( src1, tgt );
    return;
  }
  else {
    uint64_t xdif[8];
    uint64_t  tmp[8];
    uint64_t    s[8];
    bn128_Fp2_mont_sub( X2, X1, xdif );             // xdif = X2 - X1
    if (bn128_Fp2_mont_is_zero(xdif)) {
      // X1 == X2
      if (bn128_Fp2_mont_is_equal(Y1,Y2)) {
        // Y1 == Y2, it's a doubling
        bn128_G2_affine_dbl( src1, tgt );
        return;
      }
      else {
        // Y1 /= Y2, so, it must be Y1 == -Y2, result is the point at infinity
        bn128_G2_affine_set_infinity(X3);
      }
    }
    else {
      // normal addition
      bn128_Fp2_mont_sub( Y2, Y1, s );             // s   = Y2 - Y1
      bn128_Fp2_mont_div_inplace( s, xdif );       // s   = (Y2 - Y1) / (X2 - X1)
      bn128_Fp2_mont_sqr( s, tmp );                // tmp = s^2
      bn128_Fp2_mont_sub_inplace( tmp, X1 );       // tmp = s^2 - X1
      bn128_Fp2_mont_sub_inplace( tmp, X2 );       // tmp = s^2 - X1 - X2 = X3
      bn128_Fp2_mont_sub( tmp, X1 , xdif );        // xdif = X3 - X1
      bn128_Fp2_mont_mul_inplace( xdif, s );       // xdif = s*(X3 - X1)
      bn128_Fp2_mont_add_inplace( xdif, Y1 );      // xdif = Y1 + s*(X3 - X1)
      bn128_Fp2_mont_copy( tmp  , X3 );
      bn128_Fp2_mont_neg ( xdif , Y3 );
    }
  }
}

void bn128_G2_affine_add_inplace( uint64_t *tgt, const uint64_t *src2 ) {
  bn128_G2_affine_add( tgt, src2, tgt);
}

void bn128_G2_affine_sub( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt ) {
  uint64_t tmp[16];
  bn128_G2_affine_neg( src2, tmp );
  bn128_G2_affine_add( src1, tmp, tgt );
}

void bn128_G2_affine_sub_inplace( uint64_t *tgt, const uint64_t *src2 ) {
  uint64_t tmp[16];
  bn128_G2_affine_neg( src2, tmp );
  bn128_G2_affine_add( tgt , tmp, tgt );
}

// computes `expo*grp` (or `grp^expo` in multiplicative notation)
// where `grp` is a group element in G1, and `expo` is in Fr
void bn128_G2_affine_scl_generic(const uint64_t *expo, const uint64_t *grp, uint64_t *tgt, int nlimbs) {
  uint64_t proj1[3*NLIMBS_P];
  uint64_t proj2[3*NLIMBS_P];
  bn128_G2_proj_from_affine( grp, proj1 );
  bn128_G2_proj_scl_generic( expo, proj1, proj2, nlimbs);
  bn128_G2_proj_to_affine( proj2, tgt );
}

// computes `expo*grp` (or `grp^expo` in multiplicative notation)
// where `grp` is a group element in G1, and `expo` is in Fr (standard repr)
void bn128_G2_affine_scl_Fr_std(const uint64_t *expo, const uint64_t *grp, uint64_t *tgt) {
  uint64_t proj1[3*NLIMBS_P];
  uint64_t proj2[3*NLIMBS_P];
  bn128_G2_proj_from_affine( grp, proj1 );
  bn128_G2_proj_scl_Fr_std( expo, proj1, proj2);
  bn128_G2_proj_to_affine( proj2, tgt );
}

// computes `expo*grp` (or `grp^expo` in multiplicative notation)
// where `grp` is a group element in G1, and `expo` is in Fr (Montgomery repr)
void bn128_G2_affine_scl_Fr_mont(const uint64_t *expo, const uint64_t *grp, uint64_t *tgt) {
  uint64_t proj1[3*NLIMBS_P];
  uint64_t proj2[3*NLIMBS_P];
  bn128_G2_proj_from_affine( grp, proj1 );
  bn128_G2_proj_scl_Fr_mont( expo, proj1, proj2);
  bn128_G2_proj_to_affine( proj2, tgt );
}

// computes `expo*grp` (or `grp^expo` in multiplicative notation)
// where `grp` is a group element in G1, and `expo` is the same size as Fp
void bn128_G2_affine_scl_big(const uint64_t *expo, const uint64_t *grp, uint64_t *tgt) {
  uint64_t proj1[3*NLIMBS_P];
  uint64_t proj2[3*NLIMBS_P];
  bn128_G2_proj_from_affine( grp, proj1 );
  bn128_G2_proj_scl_big( expo, proj1, proj2 );
  bn128_G2_proj_to_affine( proj2, tgt );
}

// computes `expo*grp` (or `grp^expo` in multiplicative notation)
// where `grp` is a group element in G1, and `expo` is a 64 bit (unsigned!) word
void bn128_G2_affine_scl_small(uint64_t expo, const uint64_t *grp, uint64_t *tgt) {
  uint64_t proj1[3*NLIMBS_P];
  uint64_t proj2[3*NLIMBS_P];
  bn128_G2_proj_from_affine( grp, proj1 );
  bn128_G2_proj_scl_small( expo, proj1, proj2 );
  bn128_G2_proj_to_affine( proj2, tgt );
}
