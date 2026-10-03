// File del locale (foto o PDF): tipo riconosciuto dal contenuto, non dal nome o da quello che
// dichiara chi lo carica. Limiti uguali a quelli del database (migration 0015).

export interface FileKind {
  mime: "image/jpeg" | "image/webp" | "application/pdf";
  extension: "jpg" | "webp" | "pdf";
  maxBytes: number;
  isImage: boolean;
}

const KINDS: Record<string, FileKind> = {
  jpeg: { mime: "image/jpeg", extension: "jpg", maxBytes: 1_048_576, isImage: true },
  webp: { mime: "image/webp", extension: "webp", maxBytes: 1_048_576, isImage: true },
  pdf: { mime: "application/pdf", extension: "pdf", maxBytes: 2_097_152, isImage: false },
};

/** Lato lungo massimo di una foto: l'app la riduce a 1600 px; oltre vuol dire non ridotta. */
export const MAX_IMAGE_SIDE = 2000;

function startsWith(bytes: Uint8Array, prefix: number[], offset = 0): boolean {
  return prefix.every((value, index) => bytes[offset + index] === value);
}

const ascii = (text: string) => [...text].map((c) => c.charCodeAt(0));

/** JPEG (FF D8 FF), WebP ("RIFF" … "WEBP") o PDF ("%PDF-"); null per tutto il resto. */
export function detectFileKind(bytes: Uint8Array): FileKind | null {
  if (startsWith(bytes, [0xff, 0xd8, 0xff])) return KINDS.jpeg;
  if (startsWith(bytes, ascii("RIFF")) && startsWith(bytes, ascii("WEBP"), 8)) return KINDS.webp;
  if (startsWith(bytes, ascii("%PDF-"))) return KINDS.pdf;
  return null;
}

/** Larghezza e altezza lette dall'intestazione dell'immagine; null se non si riesce. */
export function imageSize(bytes: Uint8Array, kind: FileKind): { width: number; height: number } | null {
  if (kind.mime === "image/jpeg") return jpegSize(bytes);
  if (kind.mime === "image/webp") return webpSize(bytes);
  return null;
}

function jpegSize(bytes: Uint8Array): { width: number; height: number } | null {
  let offset = 2;
  while (offset + 9 < bytes.length) {
    if (bytes[offset] !== 0xff) return null;
    const marker = bytes[offset + 1];
    // Marcatori senza lunghezza (riempimento e restart).
    if (marker === 0xff || (marker >= 0xd0 && marker <= 0xd7) || marker === 0x01) {
      offset += marker === 0xff ? 1 : 2;
      continue;
    }
    const length = (bytes[offset + 2] << 8) | bytes[offset + 3];
    // SOF0–SOF15 tranne DHT (C4), JPG (C8), DAC (CC): contengono le dimensioni.
    if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
      const height = (bytes[offset + 5] << 8) | bytes[offset + 6];
      const width = (bytes[offset + 7] << 8) | bytes[offset + 8];
      return width > 0 && height > 0 ? { width, height } : null;
    }
    if (length < 2) return null;
    offset += 2 + length;
  }
  return null;
}

function webpSize(bytes: Uint8Array): { width: number; height: number } | null {
  const chunk = String.fromCharCode(...bytes.slice(12, 16));
  if (chunk === "VP8 " && bytes.length >= 30) {
    return { width: ((bytes[27] << 8) | bytes[26]) & 0x3fff, height: ((bytes[29] << 8) | bytes[28]) & 0x3fff };
  }
  if (chunk === "VP8L" && bytes.length >= 25) {
    const bits = bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
    return { width: (bits & 0x3fff) + 1, height: ((bits >> 14) & 0x3fff) + 1 };
  }
  if (chunk === "VP8X" && bytes.length >= 30) {
    const width = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
    const height = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
    return { width, height };
  }
  return null;
}

/**
 * Controlla un file da pubblicare: tipo vero, peso e (per le foto) dimensioni.
 * Restituisce il tipo o il codice d'errore da mandare all'app.
 */
export function checkUpload(bytes: Uint8Array): { kind: FileKind } | { error: string } {
  if (bytes.length === 0) return { error: "FILE_EMPTY" };
  const kind = detectFileKind(bytes);
  if (!kind) return { error: "FILE_TYPE_NOT_ALLOWED" };
  if (bytes.length > kind.maxBytes) return { error: "FILE_TOO_LARGE" };
  if (kind.isImage) {
    const size = imageSize(bytes, kind);
    if (!size) return { error: "FILE_TYPE_NOT_ALLOWED" };
    if (Math.max(size.width, size.height) > MAX_IMAGE_SIDE) return { error: "IMAGE_NOT_RESIZED" };
  }
  return { kind };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export function isUuid(value: string | null): value is string {
  return value !== null && UUID.test(value);
}
