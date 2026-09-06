// Immutable octets. Views retain a flat owner; their bounds are exact.
static void bytes_view_release(void* p) {
    avra_rc_release(((ByteView*)p)->owner);
}

static size_t bytes_len(const void* p) {
    const Header* h = (const Header*)p - 1;
    return h->kind == KIND_BYTE_VIEW ? ((const ByteView*)p)->length : h->len;
}

static const unsigned char* bytes_data(const void* p) {
    const Header* h = (const Header*)p - 1;
    if (h->kind != KIND_BYTE_VIEW) return p;
    const ByteView* v = p;
    return (const unsigned char*)v->owner + v->offset;
}

static void* bytes_box(size_t n) {
    if (n >= UINT32_MAX) avra_trap("Bytes length exceeds the storage limit");
    char* p = sized_box(n, KIND_BYTES);
    p[n] = 0;
    return p;
}

static void* bytes_owned(const void* p, size_t n) {
    void* out = bytes_box(n);
    if (n) memcpy(out, p, n);
    return out;
}

int64_t avra_bytes_len(const void* p) {
    return (int64_t)bytes_len(p);
}

int64_t avra_bytes_eq(const void* a, const void* b) {
    size_t n = bytes_len(a);
    return n == bytes_len(b) && memcmp(bytes_data(a), bytes_data(b), n) == 0;
}

int64_t avra_bytes_at(const void* p, int64_t i) {
    size_t n = bytes_len(p);
    if (i < 0 || (uint64_t)i >= n) {
        char msg[96];
        snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
                 (long long)i, (long long)n);
        avra_trap(msg);
    }
    return bytes_data(p)[i];
}

void* avra_bytes_slice(void* p, int64_t lo, int64_t hi) {
    size_t n = bytes_len(p);
    if (lo < 0 || hi < lo || (uint64_t)hi > n) return NULL;
    if (lo == hi) return bytes_box(0);
    if (lo == 0 && (uint64_t)hi == n) {
        avra_rc_retain(p);
        return p;
    }
    const Header* h = (const Header*)p - 1;
    const ByteView* parent = h->kind == KIND_BYTE_VIEW ? p : NULL;
    ByteView* v = box_alloc(sizeof(ByteView), KIND_BYTE_VIEW);
    v->owner = parent ? parent->owner : p;
    v->offset = (parent ? parent->offset : 0) + (size_t)lo;
    v->length = (size_t)(hi - lo);
    avra_rc_retain(v->owner);
    return v;
}

void* avra_bytes_copy(const void* p) {
    return bytes_owned(bytes_data(p), bytes_len(p));
}

void* avra_bytes_concat(const void* a, const void* b) {
    size_t n = bytes_len(a), m = bytes_len(b);
    if (m >= UINT32_MAX || n >= UINT32_MAX - m)
        avra_trap("Bytes length exceeds the storage limit");
    unsigned char* out = bytes_box(n + m);
    memcpy(out, bytes_data(a), n);
    memcpy(out + n, bytes_data(b), m);
    return out;
}

void* avra_bytes_of_str(const char* s) {
    return bytes_owned(s, str_len(s));
}

void* avra_bytes_of_list(void* p) {
    AvraArray* a = p;
    for (int64_t i = 0; i < a->len; i++)
        if (a->data[i] < 0 || a->data[i] > 255) return NULL;
    unsigned char* out = bytes_box((size_t)a->len);
    for (int64_t i = 0; i < a->len; i++) out[i] = (unsigned char)a->data[i];
    return out;
}
