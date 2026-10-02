// Test del controllo dei file del locale: `deno test supabase/functions`.
import { assertEquals } from "jsr:@std/assert@1";
import { checkUpload, detectFileKind, imageSize, isUuid } from "./files.ts";

/** Intestazione JPEG minima: SOI, APP0 di 16 byte, SOF0 con le dimensioni. */
function jpeg(width: number, height: number, padding = 0): Uint8Array {
  const app0 = [0xff, 0xe0, 0x00, 0x10, ...new Array(14).fill(0)];
  const sof0 = [0xff, 0xc0, 0x00, 0x11, 0x08, height >> 8, height & 0xff, width >> 8, width & 0xff, 0x03];
  return new Uint8Array([0xff, 0xd8, ...app0, ...sof0, ...new Array(8 + padding).fill(0)]);
}

/** WebP "esteso" (VP8X) con le dimensioni nei byte 24–29. */
function webp(width: number, height: number): Uint8Array {
  const bytes = new Uint8Array(40);
  bytes.set([..."RIFF"].map((c) => c.charCodeAt(0)), 0);
  bytes.set([..."WEBPVP8X"].map((c) => c.charCodeAt(0)), 8);
  const w = width - 1;
  const h = height - 1;
  bytes.set([w & 0xff, (w >> 8) & 0xff, (w >> 16) & 0xff, h & 0xff, (h >> 8) & 0xff, (h >> 16) & 0xff], 24);
  return bytes;
}

const pdf = (size: number) => {
  const bytes = new Uint8Array(size);
  bytes.set([..."%PDF-1.7"].map((c) => c.charCodeAt(0)), 0);
  return bytes;
};

Deno.test("il tipo si riconosce dal contenuto, non dal nome", () => {
  assertEquals(detectFileKind(jpeg(1600, 1200))?.mime, "image/jpeg");
  assertEquals(detectFileKind(webp(1600, 900))?.mime, "image/webp");
  assertEquals(detectFileKind(pdf(100))?.mime, "application/pdf");
  const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0]);
  assertEquals(detectFileKind(png), null);
  assertEquals(detectFileKind(new TextEncoder().encode("<html>")), null);
});

Deno.test("dimensioni lette dall'intestazione della foto", () => {
  assertEquals(imageSize(jpeg(1600, 1200), detectFileKind(jpeg(1, 1))!), { width: 1600, height: 1200 });
  assertEquals(imageSize(webp(900, 1600), detectFileKind(webp(1, 1))!), { width: 900, height: 1600 });
});

Deno.test("foto ridotte e PDF piccoli accettati; il resto rifiutato con un codice chiaro", () => {
  assertEquals("kind" in checkUpload(jpeg(1600, 1200)), true);
  assertEquals("kind" in checkUpload(pdf(2_000_000)), true);
  assertEquals(checkUpload(new Uint8Array()), { error: "FILE_EMPTY" });
  assertEquals(checkUpload(jpeg(4000, 3000)), { error: "IMAGE_NOT_RESIZED" });
  assertEquals(checkUpload(jpeg(1600, 1200, 1_100_000)), { error: "FILE_TOO_LARGE" });
  assertEquals(checkUpload(pdf(2_200_000)), { error: "FILE_TOO_LARGE" });
  assertEquals(checkUpload(new TextEncoder().encode("GIF89a")), { error: "FILE_TYPE_NOT_ALLOWED" });
});

Deno.test("solo identificativi di locale validi", () => {
  assertEquals(isUuid("10000000-0000-0000-0000-000000000006"), true);
  assertEquals(isUuid("../altro-locale"), false);
  assertEquals(isUuid(null), false);
});
