// These paramas from:
// https://hackmd.io/@jpw/bn254
use core::circuit::{u96, u384};

const ORDER: u256 = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
const FIELD_U384: [u96; 4] = [32324006162389411176778628423, 57042285082623239461879769745, 3486998266802970665, 0];
const ORDER_U384: [u96; 4] = [37671869049726892487204667393, 57042285082623239460012419144, 3486998266802970665, 0];
const ORDER_384: u384 = u384 { limb0: 37671869049726892487204667393, limb1: 57042285082623239460012419144, limb2: 3486998266802970665, limb3: 0 };