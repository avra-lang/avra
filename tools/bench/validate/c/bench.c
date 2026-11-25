/* The C floor for tools/bench/validate: yyjson parses, a hand-written
 * reader walks the object into a struct of views, and hand-written
 * rules count every issue. No allocation past yyjson's document. Each
 * line is nanoseconds per payload. */
#include "yyjson.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct { const char *s; size_t n; } view;

static long now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000000000L + t.tv_nsec;
}

static size_t chars(view v) {
    size_t k = 0;
    for (size_t i = 0; i < v.n; i++) k += ((unsigned char)v.s[i] & 0xC0) != 0x80;
    return k;
}

static int local_ok(const char *s, size_t n) {
    if (n == 0 || n > 64) return 0;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = s[i];
        if (c <= 32 || c >= 127 || c == '@' || c == '"' || c == ',' || c == ';') return 0;
    }
    return 1;
}

static int label_ok(const char *s, size_t n) {
    if (n == 0 || n > 63 || s[0] == '-' || s[n - 1] == '-') return 0;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = s[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '-' || c >= 128)) return 0;
    }
    return 1;
}

static int email_ok(view v) {
    if (v.n > 254) return 0;
    const char *at = memchr(v.s, '@', v.n);
    if (!at) return 0;
    size_t ln = at - v.s;
    if (!local_ok(v.s, ln)) return 0;
    const char *d = at + 1, *end = v.s + v.n;
    if (d == end || end[-1] == '.') return 0;
    int labels = 0;
    while (d <= end) {
        const char *dot = memchr(d, '.', end - d);
        const char *stop = dot ? dot : end;
        if (!label_ok(d, stop - d)) return 0;
        labels++;
        if (!dot) break;
        d = dot + 1;
    }
    return labels >= 2;
}

static int slug_ok(view v) {
    if (v.n && (v.s[0] == '-' || v.s[v.n - 1] == '-')) return 0;
    for (size_t i = 0; i < v.n; i++) {
        char c = v.s[i];
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-')) return 0;
    }
    return 1;
}

static int is(view v, const char *w) { return strlen(w) == v.n && memcmp(v.s, w, v.n) == 0; }

static int username_issues(yyjson_val *x) {
    if (!yyjson_is_str(x)) return 1;
    view u = { yyjson_get_str(x), yyjson_get_len(x) };
    size_t c = chars(u);
    if (c < 3 || c > 32) return 1;
    return !slug_ok(u);
}

static int text(yyjson_val *x, view *out) {
    if (!yyjson_is_str(x)) return 1;
    *out = (view){ yyjson_get_str(x), yyjson_get_len(x) };
    return 0;
}

/* Every issue the payload holds; -1 when it is not JSON. */
static int issues(const char *json, size_t len) {
    yyjson_doc *doc = yyjson_read(json, len, 0);
    if (!doc) return -1;
    yyjson_val *root = yyjson_doc_get_root(doc);
    int bad = 0;
    view email = {0}, password = {0}, confirm = {0}, plan = { "free", 4 };
    long long age = 0;
    int seen = 0;
    if (!yyjson_is_obj(root)) { yyjson_doc_free(doc); return 1; }
    size_t i, max;
    yyjson_val *k, *v;
    yyjson_obj_foreach(root, i, max, k, v) {
        view key = { yyjson_get_str(k), yyjson_get_len(k) };
        int bit;
        if (is(key, "email")) { bit = 1; bad += text(v, &email); }
        else if (is(key, "age")) { bit = 2; if (yyjson_is_int(v)) age = yyjson_get_sint(v); else bad++; }
        else if (is(key, "username")) { bit = 4; bad += username_issues(v); }
        else if (is(key, "password")) { bit = 8; bad += text(v, &password); }
        else if (is(key, "confirm")) { bit = 16; bad += text(v, &confirm); }
        else if (is(key, "plan")) { bit = 32; bad += text(v, &plan); }
        else if (is(key, "interests")) {
            bit = 64;
            if (!yyjson_is_arr(v)) bad++;
            else {
                size_t j, m;
                yyjson_val *x;
                yyjson_arr_foreach(v, j, m, x) {
                    view t;
                    if (text(x, &t) || !(is(t, "music") || is(t, "maths") || is(t, "code"))) bad++;
                }
            }
        }
        else if (is(key, "referrer")) { bit = 128; if (!yyjson_is_null(v)) bad += username_issues(v); }
        else { bad++; continue; }
        if (seen & bit) bad++;
        seen |= bit;
    }
    if ((seen & 31) != 31) bad++;
    if (!email_ok(email)) bad++;
    if (age < 13 || age > 130) bad++;
    if (chars(password) < 12) bad++;
    if (password.n != confirm.n || memcmp(password.s, confirm.s, password.n)) bad++;
    if (!(is(plan, "free") || is(plan, "pro"))) bad++;
    if (bad == 0 && is(plan, "pro") && age < 18) bad++;
    yyjson_doc_free(doc);
    return bad;
}

static char *slurp(const char *path, size_t *n) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); exit(1); }
    fseek(f, 0, SEEK_END);
    *n = ftell(f);
    rewind(f);
    char *b = malloc(*n + 1);
    if (fread(b, 1, *n, f) != *n) exit(1);
    b[*n] = 0;
    fclose(f);
    return b;
}

static volatile long sink;

static void timed(const char *label, int n, const char *json, size_t len, int parse_only) {
    for (int i = 0; i < n / 10; i++) sink += parse_only ? (long)yyjson_read(json, len, 0) != 0 : issues(json, len);
    long t0 = now_ns();
    for (int i = 0; i < n; i++) {
        if (parse_only) { yyjson_doc *d = yyjson_read(json, len, 0); sink += d != 0; yyjson_doc_free(d); }
        else sink += issues(json, len);
    }
    printf("%s: %ld ns/payload\n", label, (now_ns() - t0) / n);
}

int main(int argc, char **argv) {
    const char *dir = argc > 1 ? argv[1] : "tools/bench/validate/payloads";
    char p[1024];
    size_t gn, bn;
    snprintf(p, sizeof p, "%s/valid.json", dir);
    char *good = slurp(p, &gn);
    snprintf(p, sizeof p, "%s/refused.json", dir);
    char *bad = slurp(p, &bn);
    const char *row = getenv("ROW");
    if (row) {
        int k = getenv("N") ? atoi(getenv("N")) : 0;
        for (int i = 0; i < k; i++) {
            if (!strcmp(row, "parse")) { yyjson_doc *d = yyjson_read(good, gn, 0); sink += d != 0; yyjson_doc_free(d); }
            else if (!strcmp(row, "valid")) sink += issues(good, gn);
            else if (!strcmp(row, "refused")) sink += issues(bad, bn);
        }
        printf("%ld\n", (long)sink);
        return 0;
    }
    int n = 200000;
    timed("parse only (valid)", n, good, gn, 1);
    timed("decode + rules (valid)", n, good, gn, 0);
    timed("decode + rules (refused, every rule)", n, bad, bn, 0);
    fprintf(stderr, "issues: valid %d, refused %d\n", issues(good, gn), issues(bad, bn));
    return 0;
}
