/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifndef VLC_PLAYER_HISTORY_FILTER_H
#define VLC_PLAYER_HISTORY_FILTER_H
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

/* Portable UTF-8 filename/URI glob: '*' crosses separators, '?' matches one character.
 * Patterns are separated by ';'. Empty patterns never exclude media. */
static inline const char *vlc_player_history_Next(const char *text)
{
    ++text;
    while (((unsigned char)*text & 0xc0) == 0x80) ++text;
    return text;
}
static inline bool vlc_player_history_MatchesOne(const char *uri,
                                                const char *pattern, size_t size)
{
    const char *end = pattern + size, *star = NULL, *retry = NULL;
    while (*uri) {
        if (pattern < end && *pattern == '?') { ++pattern; uri = vlc_player_history_Next(uri); }
        else if (pattern < end && *pattern == *uri) { ++pattern; ++uri; }
        else if (pattern < end && *pattern == '*') { star = pattern++; retry = uri; }
        else if (star) { pattern = star + 1; retry = vlc_player_history_Next(retry); uri = retry; }
        else return false;
    }
    while (pattern < end && *pattern == '*') ++pattern;
    return size > 0 && pattern == end;
}
static inline bool vlc_player_history_Matches(const char *uri, const char *patterns)
{
    if (!uri || !patterns) return false;
    const char *start = patterns;
    do {
        const char *end = strchr(start, ';');
        if (!end) end = start + strlen(start);
        while (start < end && (*start == ' ' || *start == '\t')) ++start;
        const char *trimmed = end;
        while (trimmed > start && (trimmed[-1] == ' ' || trimmed[-1] == '\t')) --trimmed;
        if (vlc_player_history_MatchesOne(uri, start, (size_t)(trimmed - start))) return true;
        start = *end ? end + 1 : end;
    } while (*start);
    return false;
}
#endif
