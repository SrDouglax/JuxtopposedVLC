/* Standalone VLC PCM envelope analyzer. No Qt dependency or visible player. */
#include <vlc/vlc.h>
#include <math.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
# include <windows.h>
# include <wchar.h>
# include <sys/stat.h>
#else
# include <sys/stat.h>
# include <time.h>
# include <unistd.h>
#endif

enum { BINS = 512, FRAMES_PER_CHUNK = 64, MAX_CHUNKS = 131072,
       SAMPLE_RATE = 48000, CHANNELS = 2, MAX_WALL_MS = 30000 };
#define MAX_FILE_BYTES (1024LL * 1024LL * 1024LL)
#define MAX_DURATION_US (8LL * 60LL * 1000000LL)

struct analyzer {
    float *chunks;
    uint64_t frames;
    atomic_int stopping_reason;
    atomic_bool overflow;
};

static double monotonic_ms(void)
{
#ifdef _WIN32
    return (double)GetTickCount64();
#else
    struct timespec time;
    clock_gettime(CLOCK_MONOTONIC, &time);
    return time.tv_sec * 1000.0 + time.tv_nsec / 1000000.0;
#endif
}

static void pause_poll(void)
{
#ifdef _WIN32
    Sleep(50);
#else
    struct timespec delay = {0, 50000000};
    nanosleep(&delay, NULL);
#endif
}

static bool local_regular_file(const char *path)
{
#ifdef _WIN32
    if (!path) return false;
    const int chars = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, NULL, 0);
    if (chars <= 0) return false;
    wchar_t *wide = malloc((size_t)chars * sizeof(*wide));
    if (!wide) return false;
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, wide, chars);
    struct _stat64 info;
    const bool valid = _wstat64(wide, &info) == 0 && (info.st_mode & _S_IFMT) == _S_IFREG &&
                       info.st_size >= 0 && info.st_size <= MAX_FILE_BYTES;
    free(wide);
    return valid;
#else
    struct stat info;
    return path && path[0] == '/' && stat(path, &info) == 0 && S_ISREG(info.st_mode) &&
           info.st_size >= 0 && info.st_size <= MAX_FILE_BYTES;
#endif
}

static void on_pcm(void *opaque, const void *buffer, unsigned frames, int64_t pts)
{
    (void)pts; /* Audio output PTS is a presentation clock, not a file offset. */
    struct analyzer *a = opaque;
    const float *samples = buffer;
    for (unsigned frame = 0; frame < frames; ++frame) {
        const uint64_t chunk = a->frames / FRAMES_PER_CHUNK;
        if (chunk >= MAX_CHUNKS) {
            atomic_store(&a->overflow, true);
            return;
        }
        float peak = a->chunks[chunk];
        for (unsigned channel = 0; channel < CHANNELS; ++channel) {
            const float sample = fabsf(samples[frame * CHANNELS + channel]);
            if (isfinite(sample) && sample > peak) peak = sample;
        }
        a->chunks[chunk] = peak;
        ++a->frames;
    }
}

static void on_stopping(void *opaque, libvlc_media_t *media,
                        libvlc_stopping_reason_t reason)
{
    (void)media;
    struct analyzer *a = opaque;
    atomic_store(&a->stopping_reason, reason);
}

static void print_envelope(const struct analyzer *a, int64_t duration_us,
                           float rate, double elapsed_ms)
{
    float bins[BINS] = {0};
    const uint64_t total = a->frames;
    const uint64_t chunks = (total + FRAMES_PER_CHUNK - 1) / FRAMES_PER_CHUNK;
    for (uint64_t chunk = 0; chunk < chunks; ++chunk) {
        const uint64_t start = chunk * FRAMES_PER_CHUNK;
        const uint64_t end = start + FRAMES_PER_CHUNK < total ? start + FRAMES_PER_CHUNK : total;
        const unsigned first = (unsigned)(start * BINS / total);
        const unsigned last = (unsigned)((end - 1) * BINS / total);
        for (unsigned bin = first; bin <= last; ++bin)
            if (a->chunks[chunk] > bins[bin]) bins[bin] = a->chunks[chunk];
    }
    printf("{\"version\":1,\"durationUs\":%lld,\"sampleRate\":%d,"
           "\"playbackRate\":%.1f,\"decodedFrames\":%llu,\"elapsedMs\":%.0f,\"bins\":[",
           (long long)duration_us, SAMPLE_RATE, rate,
           (unsigned long long)total, elapsed_ms);
    for (unsigned bin = 0; bin < BINS; ++bin)
        printf("%s%.6f", bin ? "," : "", bins[bin]);
    puts("]}");
}

static int analyze(const char *path)
{
    if (!local_regular_file(path)) {
        fputs("waveform: expected a local regular file no larger than 1 GiB\n", stderr);
        return 2;
    }
    struct analyzer a = {0};
    atomic_init(&a.stopping_reason, -1);
    atomic_init(&a.overflow, false);
    a.chunks = calloc(MAX_CHUNKS, sizeof(*a.chunks));
    if (!a.chunks) return 3;

    const char *options[] = {"--ignore-config", "--no-video", "--no-media-library",
                             "--no-metadata-network-access", "--no-sub-autodetect-file"};
    libvlc_instance_t *vlc = libvlc_new((int)(sizeof(options) / sizeof(options[0])), options);
    if (!vlc) { free(a.chunks); return 4; }
    const struct libvlc_media_player_cbs callbacks = {
        .version = 0, .on_media_stopping = on_stopping
    };
    libvlc_media_t *media = libvlc_media_new_path(path);
    libvlc_media_player_t *player = libvlc_media_player_new(vlc, &callbacks, &a);
    if (!media || !player) {
        if (player) libvlc_media_player_release(player);
        if (media) libvlc_media_release(media);
        libvlc_release(vlc);
        free(a.chunks);
        return 5;
    }
    libvlc_audio_set_callbacks(player, on_pcm, NULL, NULL, NULL, NULL, &a);
    libvlc_audio_set_format(player, "FL32", SAMPLE_RATE, CHANNELS);
    libvlc_media_player_set_media(player, media);
    const float requested_rate = 16.0f;
    const bool rate_set = libvlc_media_player_set_rate(player, requested_rate) == 0;
    const double start = monotonic_ms();
    const bool started = libvlc_media_player_play(player) == 0;
    int64_t duration_us = -1;
    libvlc_state_t state = libvlc_NothingSpecial;
    if (started) {
        do {
            pause_poll();
            state = libvlc_media_player_get_state(player);
            const int64_t current_length = libvlc_media_player_get_length(player);
            if (current_length > 0) duration_us = current_length;
        } while (atomic_load(&a.stopping_reason) < 0 && state != libvlc_Error &&
                 !atomic_load(&a.overflow) && duration_us <= MAX_DURATION_US &&
                 monotonic_ms() - start < MAX_WALL_MS);
    }
    const float effective_rate = libvlc_media_player_get_rate(player);
    const double elapsed_ms = monotonic_ms() - start;
    libvlc_media_player_stop_async(player);
    libvlc_media_player_release(player);
    libvlc_media_release(media);
    libvlc_release(vlc);
    const bool complete = started && state != libvlc_Error &&
        atomic_load(&a.stopping_reason) == libvlc_stopping_reason_eos &&
        !atomic_load(&a.overflow) && duration_us > 0 &&
        duration_us <= MAX_DURATION_US && a.frames > 0 && rate_set &&
        fabsf(effective_rate - requested_rate) < 0.01f;
    if (complete) print_envelope(&a, duration_us, effective_rate, elapsed_ms);
    else fprintf(stderr, "waveform: incomplete state=%d reason=%d duration=%lld frames=%llu rate=%.1f elapsed=%.0fms\n",
                 state, atomic_load(&a.stopping_reason), (long long)duration_us,
                 (unsigned long long)a.frames, effective_rate, elapsed_ms);
    free(a.chunks);
    return complete ? 0 : 6;
}

#ifdef _WIN32
int wmain(int argc, wchar_t **argv)
{
    if (argc != 2) return 2;
    const int bytes = WideCharToMultiByte(CP_UTF8, 0, argv[1], -1, NULL, 0, NULL, NULL);
    if (bytes <= 0) return 2;
    char *path = malloc((size_t)bytes);
    if (!path) return 3;
    WideCharToMultiByte(CP_UTF8, 0, argv[1], -1, path, bytes, NULL, NULL);
    const int status = analyze(path);
    free(path);
    return status;
}
#else
int main(int argc, char **argv)
{
    return argc == 2 ? analyze(argv[1]) : 2;
}
#endif
