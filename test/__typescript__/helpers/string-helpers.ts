import { network } from "hardhat";

const { ethers } = await network.connect();

const {
  toUtf8Bytes,
  toUtf8String,
  encodeBytes32String,
  decodeBytes32String,
  getBytes,
  hexlify,
  zeroPadValue,
} = ethers;

/** String ↔ bytes32 */
export function stringToBytes32(str: string) {
  return encodeBytes32String(str);
}

export function bytes32ToString(b32: string) {
  return decodeBytes32String(b32);
}

/** String ↔ bytes16 */
export function stringToBytes16(str: string) {
  const bytes = toUtf8Bytes(str);
  if (bytes.length > 16) {
    throw new Error("String too long for bytes16");
  }
  const padded = zeroPadValue(hexlify(bytes), 16);
  return padded; // hex string, length 34 chars (0x + 32 hex = 16 bytes)
}

export function bytes16ToString(b16: string) {
  const bytes = getBytes(b16);
  // strip trailing zero padding
  let end = bytes.length;
  while (end > 0 && bytes[end - 1] === 0) {
    end--;
  }
  return toUtf8String(bytes.slice(0, end));
}
