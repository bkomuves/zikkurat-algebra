
// finite field arithmetic in Montgomery representation, in the prime field with 
//
//   p = 52435875175126190479447740508185965837690552500527637822603658699938581184513
//
// NOTE: generated code, do not edit!

#include <string.h>
#include <stdint.h>
#include <x86intrin.h>
#include "bls12_381_r_mont.h"
#include "bls12_381_r_std.h"
#include "bigint256.h"

#define NLIMBS 4

const uint64_t bls12_381_r_mont_prime[4] = { 0xffffffff00000001, 0x53bda402fffe5bfe, 0x3339d80809a1d805, 0x73eda753299d7d48 };

inline uint8_t addcarry_u128_inplace(  uint64_t *tgt_lo, uint64_t *tgt_hi, uint64_t arg_lo, uint64_t arg_hi) {
  uint8_t c;
  c = _addcarry_u64( 0, *tgt_lo, arg_lo, tgt_lo );
  c = _addcarry_u64( c, *tgt_hi, arg_hi, tgt_hi );
  return c;
}

//------------------------------------------------------------------------------

// adds the prime p to a bigint, inplace
uint8_t bls12_381_r_mont_bigint256_add_prime_inplace( uint64_t *tgt ) {
  return bigint256_add_inplace( tgt, bls12_381_r_mont_prime);
}

// the constant `p + 1`
const uint64_t bls12_381_r_mont_p_plus_1[4] = { 0xffffffff00000002, 0x53bda402fffe5bfe, 0x3339d80809a1d805, 0x73eda753299d7d48 };

// adds `p+1` to the input, inplace
uint8_t bls12_381_r_mont_bigint256_add_prime_plus_1_inplace( uint64_t *tgt ) {
  return bigint256_add_inplace( tgt, bls12_381_r_mont_p_plus_1);
}

// subtracts the prime p from a bigint, inplace
uint8_t bls12_381_r_mont_bigint256_sub_prime_inplace( uint64_t *tgt ) {
  return bigint256_sub_inplace( tgt, bls12_381_r_mont_prime);
}


// negates a field element
void bls12_381_r_mont_neg( const uint64_t *src, uint64_t *tgt ) {
  if (bigint256_is_zero(src)) {
    bigint256_set_zero(tgt);
  }
  else {
    // mod (-x) p = p - x
    tgt[0] = 0xffffffff00000001 ;
    tgt[1] = 0x53bda402fffe5bfe ;
    tgt[2] = 0x3339d80809a1d805 ;
    tgt[3] = 0x73eda753299d7d48 ;
    bigint256_sub_inplace(tgt, src);
  }
}

// negates a field element
void bls12_381_r_mont_neg_inplace( uint64_t *tgt ) {
  if (bigint256_is_zero(tgt)) {
    return;
  }
  else {
    for(int i=0; i<4; i++) tgt[i] = ~tgt[i];
    bls12_381_r_mont_bigint256_add_prime_plus_1_inplace(tgt);
  }
}

// if (x > prime) then (x - prime) else x
void bls12_381_r_mont_bigint256_sub_prime_if_above_inplace( uint64_t *tgt ) {
  if (tgt[3] <  0x73eda753299d7d48) return;
  if (tgt[3] >  0x73eda753299d7d48) { bls12_381_r_mont_bigint256_sub_prime_inplace( tgt ); return; }
  if (tgt[2] <  0x3339d80809a1d805) return;
  if (tgt[2] >  0x3339d80809a1d805) { bls12_381_r_mont_bigint256_sub_prime_inplace( tgt ); return; }
  if (tgt[1] <  0x53bda402fffe5bfe) return;
  if (tgt[1] >  0x53bda402fffe5bfe) { bls12_381_r_mont_bigint256_sub_prime_inplace( tgt ); return; }
  if (tgt[0] <  0xffffffff00000001) return;
  if (tgt[0] >= 0xffffffff00000001) { bls12_381_r_mont_bigint256_sub_prime_inplace( tgt ); return; }
}

// adds two field elements
void bls12_381_r_mont_add( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt ) {
  uint8_t c = 0;
  c = bigint256_add( src1, src2, tgt );
  bls12_381_r_mont_bigint256_sub_prime_if_above_inplace( tgt );
}

// adds two field elements, inplace
void bls12_381_r_mont_add_inplace( uint64_t *tgt, const uint64_t *src2 ) {
  uint8_t c = 0;
  c = bigint256_add_inplace( tgt, src2 );
  bls12_381_r_mont_bigint256_sub_prime_if_above_inplace( tgt );
}

// subtracts two field elements
void bls12_381_r_mont_sub( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt ) {
  uint8_t b = 0;
  b = bigint256_sub( src1, src2, tgt );
  if (b) { bls12_381_r_mont_bigint256_add_prime_inplace( tgt ); }
}

// subtracts two field elements
void bls12_381_r_mont_sub_inplace( uint64_t *tgt, const uint64_t *src2 ) {
  uint8_t b = 0;
  b = bigint256_sub_inplace( tgt, src2 );
  if (b) { bls12_381_r_mont_bigint256_add_prime_inplace( tgt ); }
}

// tgt := src - tgt
void bls12_381_r_mont_sub_inplace_reverse( uint64_t *tgt, const uint64_t *src1 ) {
  uint8_t b = 0;
  b = bigint256_sub_inplace_reverse( tgt, src1 );
  if (b) { bls12_381_r_mont_bigint256_add_prime_inplace( tgt ); }
}

// Montgomery constants R, R^2, R^3 mod P
const uint64_t bls12_381_r_mont_R_modp[4] = { 0x00000001fffffffe, 0x5884b7fa00034802, 0x998c4fefecbc4ff5, 0x1824b159acc5056f };
const uint64_t bls12_381_r_mont_R_squared[4] = { 0xc999e990f3f29c6d, 0x2b6cedcb87925c23, 0x05d314967254398f, 0x0748d9d99f59ff11 };
const uint64_t bls12_381_r_mont_R_cubed[4] = { 0xc62c1807439b73af, 0x1b3e0d188cf06990, 0x73d13c71c7b5f418, 0x6e2a5bb9c8db33e9 };

// Montgomery reduction REDC algorithm
// based on <https://en.wikipedia.org/wiki/Montgomery_modular_multiplication>
// T is 9 sized bigint in Montgomery representation,
// and assumed to be < 2^256*p
// WARNING: the value in T which will be overwritten!
//
void bls12_381_r_mont_REDC_unsafe( uint64_t *T, uint64_t *tgt ) {
  T[8] = 0;
  for(int i=0; i<4; i++) {
    __uint128_t x;
    uint64_t c;
    uint64_t m = T[i] * 0xfffffffeffffffff;
    // j = 0
    x = ((__uint128_t)m) * bls12_381_r_mont_prime[0] + T[i+0];    // note: cannot overflow in 128 bits
    c = x >> 64;
    T[i+0] = (uint64_t) x;
    // j = 1
    x = ((__uint128_t)m) * bls12_381_r_mont_prime[1] + T[i+1] + c;    // note: cannot overflow in 128 bits
    c = x >> 64;
    T[i+1] = (uint64_t) x;
    // j = 2
    x = ((__uint128_t)m) * bls12_381_r_mont_prime[2] + T[i+2] + c;    // note: cannot overflow in 128 bits
    c = x >> 64;
    T[i+2] = (uint64_t) x;
    // j = 3
    x = ((__uint128_t)m) * bls12_381_r_mont_prime[3] + T[i+3] + c;    // note: cannot overflow in 128 bits
    c = x >> 64;
    T[i+3] = (uint64_t) x;
    uint8_t d = _addcarry_u64( 0 , T[i+4] , c , T+i+4 );
    for(int j=5; (d>0) && (j<=8-i); j++) {
      d = _addcarry_u64( d , T[i+j] , 0 , T+i+j );
    }
  }
  memcpy( tgt, T+4, 32);
  bls12_381_r_mont_bigint256_sub_prime_if_above_inplace(tgt);
}

void bls12_381_r_mont_REDC( const uint64_t *src, uint64_t *tgt ) {
  uint64_t T[9];
  memcpy( T, src, 64 );
  bls12_381_r_mont_REDC_unsafe ( T, tgt );
}

void bls12_381_r_mont_sqr( const uint64_t *src, uint64_t *tgt) {
  uint64_t T[9];
  bigint256_sqr( src, T );
  bls12_381_r_mont_REDC_unsafe( T, tgt );
};

void bls12_381_r_mont_sqr_inplace( uint64_t *tgt ) {
  uint64_t T[9];
  bigint256_sqr( tgt, T );
  bls12_381_r_mont_REDC_unsafe( T, tgt );
};

void bls12_381_r_mont_mul( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt) {
  uint64_t T[9];
  bigint256_mul( src1, src2, T );
  bls12_381_r_mont_REDC_unsafe( T, tgt );
};

void bls12_381_r_mont_mul_inplace( uint64_t *tgt, const uint64_t *src2) {
  uint64_t T[9];
  bigint256_mul( tgt, src2, T );
  bls12_381_r_mont_REDC_unsafe( T, tgt );
};

// computes `x^e mod p`
void bls12_381_r_mont_pow_uint64( const uint64_t *src, uint64_t exponent, uint64_t *tgt ) {
  uint64_t e = exponent;
  uint64_t sqr[4];
  bigint256_copy( src, sqr );             // sqr := src
  bigint256_copy( bls12_381_r_mont_R_modp, tgt );          // tgt := 1
  while(e!=0) {
    if (e & 1) { bls12_381_r_mont_mul_inplace(tgt, sqr); }
    bls12_381_r_mont_mul_inplace(sqr, sqr);
    e = e >> 1;
  }
}

// computes `x^e mod p` (for `e` non-negative bigint)
void bls12_381_r_mont_pow_gen( const uint64_t *src, const uint64_t *expo, uint64_t *tgt, int expo_len ) {
  uint64_t sqr[4];
  bigint256_copy( src, sqr );             // sqr := src
  bigint256_copy( bls12_381_r_mont_R_modp, tgt );        // tgt := 1
  int s = expo_len - 1;
  while ((expo[s] == 0) && (s>0)) { s--; }          // skip the unneeded largest powers
  for(int i=0; i<=s; i++) {
    uint64_t e = expo[i];
    for(int j=0; j<64; j++) {
      if (e & 1) { bls12_381_r_mont_mul_inplace(tgt, sqr); }
      bls12_381_r_mont_mul_inplace(sqr, sqr);
      e = e >> 1;
    }
  }
}

void bls12_381_r_mont_inv( const uint64_t *src, uint64_t *tgt) {
  bls12_381_r_std_inv( src, tgt );
  bls12_381_r_mont_mul_inplace( tgt, bls12_381_r_mont_R_cubed );
};

void bls12_381_r_mont_inv_inplace( uint64_t *tgt ) {
  bls12_381_r_std_inv_inplace( tgt );
  bls12_381_r_mont_mul_inplace( tgt, bls12_381_r_mont_R_cubed );
};

void bls12_381_r_mont_div( const uint64_t *src1, const uint64_t *src2, uint64_t *tgt) {
  bls12_381_r_std_div( src1, src2, tgt );
  bls12_381_r_mont_mul_inplace( tgt, bls12_381_r_mont_R_squared );
};

void bls12_381_r_mont_div_inplace( uint64_t *tgt, const uint64_t *src2) {
  bls12_381_r_std_div_inplace( tgt, src2 );
  bls12_381_r_mont_mul_inplace( tgt, bls12_381_r_mont_R_squared );
};

uint8_t bls12_381_r_mont_is_zero( const uint64_t *src ) {
  return bigint256_is_zero( src );
}

uint8_t bls12_381_r_mont_is_one( const uint64_t *src ) {
  return bigint256_is_equal( src, bls12_381_r_mont_R_modp );
}

uint8_t bls12_381_r_mont_is_equal( const uint64_t *src1, const uint64_t *src2 ) {
  return bigint256_is_equal( src1 , src2 );
}

void bls12_381_r_mont_set_zero( uint64_t *tgt ) {
  bigint256_set_zero( tgt );
}

void bls12_381_r_mont_set_one( uint64_t *tgt) {
  bigint256_copy( bls12_381_r_mont_R_modp , tgt );
}

void bls12_381_r_mont_copy( const uint64_t *src, uint64_t *tgt ) {
  bigint256_copy( src , tgt );
}

void bls12_381_r_mont_from_std( const uint64_t *src, uint64_t *tgt) {
  bls12_381_r_mont_mul( src, bls12_381_r_mont_R_squared, tgt );
}

void bls12_381_r_mont_to_std( const uint64_t *src, uint64_t *tgt) {
  uint64_t T[9];
  memcpy( T, src, 32);
  memset( T+4, 0, 32);
  bls12_381_r_mont_REDC_unsafe( T, tgt );
};
