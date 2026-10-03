// restaurant-file — il file facoltativo del locale (foto del menù o PDF piccolo).
//
//   POST   ?restaurant_id=…&today_only=true|false   corpo = i byte del file   (titolare con 2FA)
//   DELETE ?restaurant_id=…  (oppure POST ?restaurant_id=…&action=remove)     (titolare con 2FA)
//   POST   con intestazione "x-haposto-cron" = HAPOSTO_CRON_SECRET           (pulizia notturna, pg_cron)
//
// Il tipo si riconosce dal contenuto (JPEG, WebP, PDF), il peso e le dimensioni delle foto si
// controllano qui e di nuovo nel database. Deploy con --no-verify-jwt (controlla da sé chi chiama).
// Segreti: HAPOSTO_CRON_SECRET (lo stesso di push-dispatch).
import { HttpError, json, requireEnv, safeEqual, serve } from "../_shared/http.ts";
import { checkUpload, isUuid } from "../_shared/files.ts";
import { adminClient, requireCaller, sqlErrorCode } from "../_shared/supabase.ts";

const BUCKET = "restaurant-files";
/** Un po' più del file più grande ammesso (PDF da 2 MB). */
const MAX_REQUEST_BYTES = 2_200_000;

serve(async (request) => {
  if (request.headers.has("x-haposto-cron")) return await cleanup(request);
  const action = new URL(request.url).searchParams.get("action");
  if (request.method === "DELETE" || (request.method === "POST" && action === "remove")) return await remove(request);
  if (request.method === "POST") return await upload(request);
  throw new HttpError(405, "METHOD_NOT_ALLOWED");
});

async function checkOwner(request: Request) {
  const caller = await requireCaller(request);
  const restaurantId = new URL(request.url).searchParams.get("restaurant_id");
  if (!isUuid(restaurantId)) throw new HttpError(400, "INVALID_RESTAURANT");
  const { error } = await caller.asUser.rpc("restaurant_file_check", { p_restaurant_id: restaurantId });
  if (error) throw new HttpError(403, sqlErrorCode(error.message));
  return { userId: caller.user.id, restaurantId };
}

async function upload(request: Request): Promise<Response> {
  const declared = Number(request.headers.get("content-length") ?? "0");
  if (declared > MAX_REQUEST_BYTES) throw new HttpError(413, "FILE_TOO_LARGE");
  const { userId, restaurantId } = await checkOwner(request);
  const todayOnly = new URL(request.url).searchParams.get("today_only") === "true";

  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.length > MAX_REQUEST_BYTES) throw new HttpError(413, "FILE_TOO_LARGE");
  const checked = checkUpload(bytes);
  if ("error" in checked) throw new HttpError(422, checked.error);
  const { kind } = checked;

  const db = adminClient();
  const path = `${restaurantId}/${crypto.randomUUID()}.${kind.extension}`;
  const { error: uploadError } = await db.storage.from(BUCKET).upload(path, bytes, {
    contentType: kind.mime,
    cacheControl: "3600",
    upsert: false,
  });
  if (uploadError) {
    console.error("upload", uploadError.message);
    throw new HttpError(500, "STORAGE_ERROR");
  }

  const { data: oldPath, error } = await db.rpc("restaurant_file_attach", {
    p_restaurant_id: restaurantId,
    p_user_id: userId,
    p_path: path,
    p_mime: kind.mime,
    p_bytes: bytes.length,
    p_today_only: todayOnly,
  });
  if (error) {
    console.error("restaurant_file_attach", error.message);
    await db.storage.from(BUCKET).remove([path]);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  if (typeof oldPath === "string" && oldPath) {
    // Se non riesce, ci pensa la pulizia notturna.
    await db.storage.from(BUCKET).remove([oldPath]);
  }
  return json(request, 200, { path, mime: kind.mime, bytes: bytes.length, today_only: todayOnly });
}

async function remove(request: Request): Promise<Response> {
  const { userId, restaurantId } = await checkOwner(request);
  const db = adminClient();
  const { data: oldPath, error } = await db.rpc("restaurant_file_detach", {
    p_restaurant_id: restaurantId,
    p_user_id: userId,
  });
  if (error) {
    console.error("restaurant_file_detach", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  if (typeof oldPath === "string" && oldPath) await db.storage.from(BUCKET).remove([oldPath]);
  return json(request, 200, { ok: true });
}

async function cleanup(request: Request): Promise<Response> {
  if (request.method !== "POST") throw new HttpError(405, "METHOD_NOT_ALLOWED");
  if (!safeEqual(request.headers.get("x-haposto-cron") ?? "", requireEnv("HAPOSTO_CRON_SECRET"))) {
    throw new HttpError(401, "UNAUTHORIZED");
  }
  const db = adminClient();
  const { data, error } = await db.rpc("restaurant_files_cleanup");
  if (error) {
    console.error("restaurant_files_cleanup", error.message);
    throw new HttpError(500, "DATABASE_ERROR");
  }
  // Elenco di testi: PostgREST lo restituisce come ["a", …] (o, per sicurezza, [{ nome: "a" }, …]).
  const paths = ((data ?? []) as unknown[])
    .map((value) => typeof value === "string" ? value : Object.values(value as Record<string, unknown>)[0])
    .filter((value): value is string => typeof value === "string" && value.length > 0);
  let removed = 0;
  for (let start = 0; start < paths.length; start += 100) {
    const batch = paths.slice(start, start + 100);
    const { error: removeError } = await db.storage.from(BUCKET).remove(batch);
    if (removeError) {
      console.error("remove", removeError.message);
      continue;
    }
    removed += batch.length;
  }
  return json(request, 200, { removed });
}
