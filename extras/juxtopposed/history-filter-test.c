/* Regression checks for the privacy rule used by the real player. */
#include "../../src/player/history_filter.h"
#include <stdio.h>

int main(void)
{
    struct { const char *uri, *patterns; bool expected; } cases[] = {
        {"file:///videos/movie.mkv", "", false},
        {"file:///videos/movie.mkv", "   ; ; ", false},
        {"file:///videos/movie.mkv", "*.mkv", true},
        {"file:///videos/movie.mp4", "*.mkv", false},
        {"file:///private/clip.mp4", "*.mkv; */private/*", true},
        {"http://localhost/stream", "http://*", true},
        {"https://localhost/stream", "http://*", false},
        {"file:///vídeo.mp4", "*/v?deo.mp4", true},
        {"file:///vídeo.mp4", "*/vídeo.mp4", true},
        {"file:///video.mp4", "*/v?deo.mp4", true},
        {"file:///videos/movie.mkv", "*movie*.*", true},
        {"file:///videos/movie.mkv", "*movie*.*bad", false},
        {"file:///videos/movie.mkv", "*a*b*c*", false},
        {"file:///videos/movie.mkv", "**.mkv", true},
        {"file:///videos/movie.mkv", "*.MKV", false},
        {NULL, "*", false}, {"file:///clip", NULL, false}
    };
    for (size_t i = 0; i < sizeof(cases)/sizeof(cases[0]); ++i)
        if (vlc_player_history_Matches(cases[i].uri, cases[i].patterns) != cases[i].expected) {
            fprintf(stderr, "history filter case %zu FAIL\n", i);
            return 1;
        }
    puts("history filter: 17 cases PASS");
    return 0;
}
