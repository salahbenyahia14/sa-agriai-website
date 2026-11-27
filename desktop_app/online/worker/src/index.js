const SESSION_COOKIE = "sa_agriai_session";
const SESSION_TTL = 60 * 60 * 24 * 30;
const RESET_TTL = 60 * 20;
const PBKDF2_ITERATIONS = 310000;

const json = (data, status = 200, headers = {}) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      ...headers,
    },
  });

const now = () => Math.floor(Date.now() / 1000);
const enc = new TextEncoder();

function toHex(bytes) {
  return [...new Uint8Array(bytes)].map((v) => v.toString(16).padStart(2, "0")).join("");
}

function toBase64Url(bytes) {
  let binary = "";
  for (const byte of new Uint8Array(bytes)) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function fromBase64Url(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(normalized + "=".repeat((4 - normalized.length % 4) % 4));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

async function sha256(value) {
  return toHex(await crypto.subtle.digest("SHA-256", enc.encode(value)));
}

async function hashPassword(password, salt) {
  const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"]);
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt: fromBase64Url(salt), iterations: PBKDF2_ITERATIONS, hash: "SHA-256" },
    key,
    256,
  );
  return toHex(bits);
}

async function newSecret() {
  return toBase64Url(crypto.getRandomValues(new Uint8Array(32)));
}

function equalConstantTime(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function readJson(request, max = 12000) {
  const length = Number(request.headers.get("content-length") || 0);
  if (length > max) throw new Error("BODY_TOO_LARGE");
  const text = await request.text();
  if (text.length > max) throw new Error("BODY_TOO_LARGE");
  try { return JSON.parse(text); } catch { throw new Error("INVALID_JSON"); }
}

function cookieValue(request, name) {
  const cookie = request.headers.get("cookie") || "";
  for (const item of cookie.split(";")) {
    const part = item.trim();
    const index = part.indexOf("=");
    if (index > 0 && part.slice(0, index) === name) return decodeURIComponent(part.slice(index + 1));
  }
  return "";
}

function sessionCookie(token, maxAge = SESSION_TTL) {
  return SESSION_COOKIE + "=" + encodeURIComponent(token) + "; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=" + maxAge;
}

function clearSessionCookie() {
  return SESSION_COOKIE + "=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0";
}

async function getSession(request, env) {
  const bearer = request.headers.get("authorization") || "";
  const token = bearer.startsWith("Bearer ") ? bearer.slice(7) : cookieValue(request, SESSION_COOKIE);
  if (!token || !env.DB) return null;
  const tokenHash = await sha256(token);
  const user = await env.DB.prepare(
    "SELECT u.id, u.email, u.display_name " +
    "FROM sessions s JOIN users u ON u.id = s.user_id " +
    "WHERE s.token_hash = ? AND s.expires_at > ? AND s.revoked_at IS NULL " +
    "AND u.deleted_at IS NULL LIMIT 1",
  ).bind(tokenHash, now()).first();
  return user || null;
}

async function createSession(request, env, userId) {
  const token = await newSecret();
  const tokenHash = await sha256(token);
  const createdAt = now();
  await env.DB.prepare(
    "INSERT INTO sessions (id, token_hash, user_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)",
  ).bind(crypto.randomUUID(), tokenHash, userId, createdAt, createdAt + SESSION_TTL).run();
  const body = { ok: true };
  if (request.headers.get("x-sa-client") === "desktop") body.sessionToken = token;
  return { body, cookie: sessionCookie(token) };
}

async function rateLimit(env, request, action, max, seconds) {
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const key = action + ":" + await sha256(ip);
  const t = now();
  await env.DB.prepare(
    "INSERT INTO auth_rate_limits (rate_key, hits, window_started_at) VALUES (?, 1, ?) " +
    "ON CONFLICT(rate_key) DO UPDATE SET " +
    "hits = CASE WHEN window_started_at <= ? THEN 1 ELSE hits + 1 END, " +
    "window_started_at = CASE WHEN window_started_at <= ? THEN ? ELSE window_started_at END",
  ).bind(key, t, t - seconds, t - seconds, t).run();
  const row = await env.DB.prepare("SELECT hits FROM auth_rate_limits WHERE rate_key = ?").bind(key).first();
  return Number(row?.hits || 0) <= max;
}

async function sendResetEmail(env, email, link) {
  const service = env.EMAILJS_SERVICE_ID;
  const template = env.EMAILJS_TEMPLATE_ID;
  const publicKey = env.EMAILJS_PUBLIC_KEY;
  const privateKey = env.EMAILJS_PRIVATE_KEY;
  if (!service || !template || !publicKey || !privateKey) throw new Error("EMAIL_SERVICE_NOT_CONFIGURED");

  const response = await fetch("https://api.emailjs.com/api/v1.0/email/send", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      service_id: service,
      template_id: template,
      user_id: publicKey,
      accessToken: privateKey,
      template_params: {
        to_email: email,
        email: email,
        app_name: "SA AgriAI",
        reset_link: link,
        expiry_minutes: RESET_TTL / 60,
      },
    }),
  });
  if (!response.ok) throw new Error("EMAIL_DELIVERY_FAILED");
}

async function handleApi(request, env, url) {
  if (!env.DB) return json({ error: "DATABASE_NOT_CONFIGURED" }, 503);
  const path = url.pathname;
  const method = request.method;

  if (path === "/api/health" && method === "GET") {
    const result = await env.DB.prepare("SELECT 1 AS ok").first();
    return json({ ok: result?.ok === 1, service: "SA AgriAI API" });
  }

  if (path === "/api/auth/register" && method === "POST") {
    const body = await readJson(request);
    const email = String(body.email || "").trim().toLowerCase();
    const displayName = String(body.displayName || "").trim().slice(0, 80);
    const password = String(body.password || "");
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) return json({ error: "INVALID_EMAIL" }, 400);
    if (displayName.length < 2) return json({ error: "INVALID_NAME" }, 400);
    if (password.length < 10 || password.length > 128) return json({ error: "WEAK_PASSWORD" }, 400);
    if (!(await rateLimit(env, request, "register", 6, 600))) return json({ error: "RATE_LIMITED" }, 429);

    const existing = await env.DB.prepare("SELECT id FROM users WHERE email = ? LIMIT 1").bind(email).first();
    if (existing) return json({ error: "EMAIL_ALREADY_REGISTERED" }, 409);

    const salt = toBase64Url(crypto.getRandomValues(new Uint8Array(16)));
    const passwordHash = await hashPassword(password, salt);
    const userId = crypto.randomUUID();
    try {
      await env.DB.prepare(
        "INSERT INTO users (id, email, display_name, password_salt, password_hash, created_at) VALUES (?, ?, ?, ?, ?, ?)",
      ).bind(userId, email, displayName, salt, passwordHash, now()).run();
    } catch {
      return json({ error: "EMAIL_ALREADY_REGISTERED" }, 409);
    }
    const session = await createSession(request, env, userId);
    return json(
      { ...session.body, user: { id: userId, email: email, displayName: displayName } },
      201,
      { "set-cookie": session.cookie },
    );
  }

  if (path === "/api/auth/login" && method === "POST") {
    const body = await readJson(request);
    const email = String(body.email || "").trim().toLowerCase();
    const password = String(body.password || "");
    if (email.length > 254 || password.length > 128 || !email || !password) return json({ error: "INVALID_CREDENTIALS" }, 400);
    if (!(await rateLimit(env, request, "login", 12, 600))) return json({ error: "RATE_LIMITED" }, 429);
    const user = await env.DB.prepare(
      "SELECT id, email, display_name, password_salt, password_hash FROM users WHERE email = ? AND deleted_at IS NULL LIMIT 1",
    ).bind(email).first();
    if (!user) return json({ error: "INVALID_CREDENTIALS" }, 401);
    const candidate = await hashPassword(password, user.password_salt);
    if (!equalConstantTime(candidate, user.password_hash)) return json({ error: "INVALID_CREDENTIALS" }, 401);
    const session = await createSession(request, env, user.id);
    return json(
      { ...session.body, user: { id: user.id, email: user.email, displayName: user.display_name } },
      200,
      { "set-cookie": session.cookie },
    );
  }

  if (path === "/api/auth/me" && method === "GET") {
    const user = await getSession(request, env);
    return user
      ? json({ user: { id: user.id, email: user.email, displayName: user.display_name } })
      : json({ user: null }, 401);
  }

  if (path === "/api/auth/logout" && method === "POST") {
    const bearer = request.headers.get("authorization") || "";
    const token = bearer.startsWith("Bearer ") ? bearer.slice(7) : cookieValue(request, SESSION_COOKIE);
    if (token) {
      const tokenHash = await sha256(token);
      await env.DB.prepare("UPDATE sessions SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL")
        .bind(now(), tokenHash).run();
    }
    return json({ ok: true }, 200, { "set-cookie": clearSessionCookie() });
  }

  if (path === "/api/auth/forgot-password" && method === "POST") {
    if (!(await rateLimit(env, request, "forgot", 4, 900))) return json({ error: "RATE_LIMITED" }, 429);
    const body = await readJson(request);
    const email = String(body.email || "").trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) return json({ error: "INVALID_EMAIL" }, 400);

    // Identical response whether or not this address is registered.
    const user = await env.DB.prepare("SELECT id FROM users WHERE email = ? AND deleted_at IS NULL LIMIT 1").bind(email).first();
    if (!user) return json({ ok: true });

    const rawToken = await newSecret();
    const tokenHash = await sha256(rawToken);
    const createdAt = now();
    await env.DB.prepare(
      "INSERT INTO password_reset_tokens (id, token_hash, user_id, created_at, expires_at) VALUES (?, ?, ?, ?, ?)",
    ).bind(crypto.randomUUID(), tokenHash, user.id, createdAt, createdAt + RESET_TTL).run();

    const resetUrl = new URL("/", url.origin);
    resetUrl.searchParams.set("reset", rawToken);
    try {
      await sendResetEmail(env, email, resetUrl.toString());
    } catch (error) {
      await env.DB.prepare("DELETE FROM password_reset_tokens WHERE token_hash = ?").bind(tokenHash).run();
      if (error.message === "EMAIL_SERVICE_NOT_CONFIGURED") return json({ error: "EMAIL_SERVICE_NOT_CONFIGURED" }, 503);
      return json({ error: "EMAIL_DELIVERY_FAILED" }, 503);
    }
    return json({ ok: true });
  }

  if (path === "/api/auth/reset-password" && method === "POST") {
    const body = await readJson(request);
    const token = String(body.token || "");
    const password = String(body.password || "");
    if (token.length < 30 || token.length > 200) return json({ error: "INVALID_RESET_LINK" }, 400);
    if (password.length < 10 || password.length > 128) return json({ error: "WEAK_PASSWORD" }, 400);
    if (!(await rateLimit(env, request, "reset", 8, 900))) return json({ error: "RATE_LIMITED" }, 429);
    const tokenHash = await sha256(token);
    const reset = await env.DB.prepare(
      "SELECT id, user_id FROM password_reset_tokens WHERE token_hash = ? AND used_at IS NULL AND expires_at > ? LIMIT 1",
    ).bind(tokenHash, now()).first();
    if (!reset) return json({ error: "INVALID_RESET_LINK" }, 400);

    const salt = toBase64Url(crypto.getRandomValues(new Uint8Array(16)));
    const passwordHash = await hashPassword(password, salt);
    await env.DB.batch([
      env.DB.prepare("UPDATE users SET password_salt = ?, password_hash = ? WHERE id = ? AND deleted_at IS NULL")
        .bind(salt, passwordHash, reset.user_id),
      env.DB.prepare("UPDATE password_reset_tokens SET used_at = ? WHERE id = ? AND used_at IS NULL")
        .bind(now(), reset.id),
      env.DB.prepare("UPDATE sessions SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL")
        .bind(now(), reset.user_id),
      env.DB.prepare("DELETE FROM password_reset_tokens WHERE user_id = ? AND used_at IS NULL")
        .bind(reset.user_id),
    ]);
    return json({ ok: true });
  }

  const user = await getSession(request, env);
  if (!user) return json({ error: "UNAUTHORIZED" }, 401);

  if (path === "/api/listings" && method === "GET") {
    const rows = await env.DB.prepare(
      "SELECT l.id, l.user_id, l.title, l.description, l.category, l.price, l.wilaya, l.phone, l.created_at, " +
      "u.display_name AS author_name FROM listings l JOIN users u ON u.id = l.user_id " +
      "WHERE l.deleted_at IS NULL AND u.deleted_at IS NULL ORDER BY l.created_at DESC LIMIT 200",
    ).all();
    return json({ items: rows.results || [] });
  }

  if (path === "/api/listings" && method === "POST") {
    const body = await readJson(request);
    const title = String(body.title || "").trim().slice(0, 120);
    const description = String(body.description || "").trim().slice(0, 1800);
    const category = String(body.category || "other").trim().slice(0, 32);
    const price = String(body.price || "").trim().slice(0, 60);
    const wilaya = String(body.wilaya || "").trim().slice(0, 80);
    const phone = String(body.phone || "").trim().slice(0, 40);
    if (title.length < 2 || description.length < 3 || !wilaya) return json({ error: "INVALID_LISTING" }, 400);
    const id = crypto.randomUUID();
    const createdAt = now();
    await env.DB.prepare(
      "INSERT INTO listings (id, user_id, title, description, category, price, wilaya, phone, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ).bind(id, user.id, title, description, category, price, wilaya, phone, createdAt, createdAt).run();
    return json({ item: { id, user_id: user.id, title, description, category, price, wilaya, phone, created_at: createdAt, author_name: user.display_name } }, 201);
  }

  if (path.startsWith("/api/listings/") && method === "DELETE") {
    const id = decodeURIComponent(path.slice("/api/listings/".length));
    const result = await env.DB.prepare(
      "UPDATE listings SET deleted_at = ?, updated_at = ? WHERE id = ? AND user_id = ? AND deleted_at IS NULL",
    ).bind(now(), now(), id, user.id).run();
    return result.meta.changes ? json({ ok: true }) : json({ error: "NOT_FOUND" }, 404);
  }

  if (path === "/api/posts" && method === "GET") {
    const rows = await env.DB.prepare(
      "SELECT p.id, p.content, p.created_at, p.user_id, u.display_name AS author_name " +
      "FROM community_posts p JOIN users u ON u.id = p.user_id " +
      "WHERE p.deleted_at IS NULL AND u.deleted_at IS NULL ORDER BY p.created_at DESC LIMIT 200",
    ).all();
    return json({ items: rows.results || [] });
  }

  if (path === "/api/posts" && method === "POST") {
    const body = await readJson(request);
    const content = String(body.content || "").trim().slice(0, 2000);
    if (content.length < 2) return json({ error: "INVALID_POST" }, 400);
    const id = crypto.randomUUID();
    const createdAt = now();
    await env.DB.prepare(
      "INSERT INTO community_posts (id, user_id, content, created_at) VALUES (?, ?, ?, ?)",
    ).bind(id, user.id, content, createdAt).run();
    return json({ item: { id, user_id: user.id, content, created_at: createdAt, author_name: user.display_name } }, 201);
  }

  if (path.startsWith("/api/posts/") && method === "DELETE") {
    const id = decodeURIComponent(path.slice("/api/posts/".length));
    const result = await env.DB.prepare(
      "UPDATE community_posts SET deleted_at = ? WHERE id = ? AND user_id = ? AND deleted_at IS NULL",
    ).bind(now(), id, user.id).run();
    return result.meta.changes ? json({ ok: true }) : json({ error: "NOT_FOUND" }, 404);
  }

  return json({ error: "NOT_FOUND" }, 404);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-methods": "GET,POST,DELETE,OPTIONS",
          "access-control-allow-headers": "content-type,authorization,x-sa-client",
          "access-control-max-age": "86400",
        },
      });
    }
    if (url.pathname.startsWith("/api/")) {
      try {
        return await handleApi(request, env, url);
      } catch (error) {
        const message = error?.message || "INTERNAL_ERROR";
        if (message === "INVALID_JSON") return json({ error: message }, 400);
        if (message === "BODY_TOO_LARGE") return json({ error: message }, 413);
        return json({ error: "INTERNAL_ERROR" }, 500);
      }
    }
    if (!env.ASSETS) return json({ error: "ASSETS_NOT_CONFIGURED" }, 503);
    return env.ASSETS.fetch(request);
  },
};