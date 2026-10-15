/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
#include "controlbar_profile_model.hpp"

#include "qt.hpp"
#include "player/control_list_model.hpp"
#include "player/player_controlbar_model.hpp"

decltype (ControlbarProfileModel::m_defaults)
    ControlbarProfileModel::m_defaults =
        {
            {
                Style::EMPTY_STYLE,
                N_("Empty Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {

                                },
                                {

                                },
                                {

                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {

                                },
                                {

                                },
                                {

                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {

                                },
                                {

                                },
                                {

                                }
                            }
                        }
                    }
                }
            },
            {
                Style::DEFAULT_STYLE,
                N_("Default Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::NEXT_BUTTON
                                },
                                {

                                },
                                {
                                    ControlListModel::VOLUME,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::LANG_BUTTON,
                                    ControlListModel::SETTINGS_BUTTON,
                                    ControlListModel::PLAYLIST_BUTTON
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::SKIP_BACK_15_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::SKIP_FW_15_BUTTON,
                                    ControlListModel::NEXT_BUTTON
                                },
                                {

                                },
                                {
                                    ControlListModel::VOLUME,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::PLAYLIST_BUTTON
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {
                                    ControlListModel::ARTWORK_INFO
                                },
                                {
                                    ControlListModel::RANDOM_BUTTON,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::LOOP_BUTTON
                                },
                                {
                                    ControlListModel::VOLUME,
                                    ControlListModel::PLAYER_SWITCH_BUTTON
                                }
                            }
                        }
                    }
                }
            },
            {
                Style::MINIMALIST_STYLE,
                N_("Minimalist Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::RECORD_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::NAVIGATION_BUTTONS,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PLAYLIST_BUTTON
                                }, {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::RECORD_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::NAVIGATION_BUTTONS,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PLAYLIST_BUTTON
                                }, {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {
                                    ControlListModel::ARTWORK_INFO
                                },
                                {
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON
                                }, {}
                            }
                        }
                    }
                }
            },
            {
                Style::ONE_LINER_STYLE,
                N_("One-liner Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::FULLSCREEN_BUTTON,
                                    ControlListModel::PLAYLIST_BUTTON,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::RECORD_BUTTON,
                                    ControlListModel::SNAPSHOT_BUTTON,
                                    ControlListModel::ATOB_BUTTON,
                                    ControlListModel::FRAME_NEXT_BUTTON
                                },
                                {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::FULLSCREEN_BUTTON,
                                    ControlListModel::PLAYLIST_BUTTON,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::RECORD_BUTTON,
                                    ControlListModel::SNAPSHOT_BUTTON,
                                    ControlListModel::ATOB_BUTTON,
                                    ControlListModel::FRAME_NEXT_BUTTON
                                },
                                {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {
                                    ControlListModel::ARTWORK_INFO
                                },
                                {
                                    ControlListModel::RANDOM_BUTTON,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::LOOP_BUTTON
                                }, {}
                            }
                        }
                    }
                }
            },
            {
                Style::SIMPLEST_STYLE,
                N_("Simplest Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {
                                    ControlListModel::VOLUME
                                },
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::STOP_BUTTON
                                },
                                {
                                    ControlListModel::FULLSCREEN_BUTTON
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {
                                    ControlListModel::VOLUME
                                },
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::STOP_BUTTON
                                },
                                {
                                    ControlListModel::FULLSCREEN_BUTTON
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {
                                    ControlListModel::ARTWORK_INFO
                                },
                                {
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::NEXT_BUTTON
                                }, {}
                            }
                        }
                    }
                }
            },
            {
                Style::CLASSIC_STYLE,
                N_("Classic Style"),
                {
                    {
                        PlayerControlbarModel::Videoplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::FULLSCREEN_BUTTON,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PLAYLIST_BUTTON,
                                    ControlListModel::LOOP_BUTTON,
                                    ControlListModel::RANDOM_BUTTON
                                },
                                {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Audioplayer,
                        {
                            {
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::FULLSCREEN_BUTTON,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PLAYLIST_BUTTON,
                                    ControlListModel::LOOP_BUTTON,
                                    ControlListModel::RANDOM_BUTTON
                                },
                                {},
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    },
                    {
                        PlayerControlbarModel::Miniplayer,
                        {
                            {
                                {
                                    ControlListModel::ARTWORK_INFO
                                },
                                {
                                    ControlListModel::PLAY_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PREVIOUS_BUTTON,
                                    ControlListModel::STOP_BUTTON,
                                    ControlListModel::NEXT_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::FULLSCREEN_BUTTON,
                                    ControlListModel::EXTENDED_BUTTON,
                                    ControlListModel::WIDGET_SPACER,
                                    ControlListModel::PLAYLIST_BUTTON,
                                    ControlListModel::LOOP_BUTTON,
                                    ControlListModel::RANDOM_BUTTON
                                },
                                {
                                    ControlListModel::VOLUME
                                }
                            }
                        }
                    }
                }
            }
        };


// Upgrade only the untouched old audio layout; preserve custom arrangements.
void ControlbarProfileModel::upgradeAudioDefaults(ControlbarProfile *profile)
{
    using C = ControlListModel;
    const auto audio = profile->getModelData(PlayerControlbarModel::Audioplayer);
    const QVector<int> oldLeft = {C::PREVIOUS_BUTTON, C::PLAY_BUTTON, C::NEXT_BUTTON};
    const QVector<int> oldRight = {C::VOLUME, C::EXTENDED_BUTTON, C::LANG_BUTTON,
                                   C::SETTINGS_BUTTON, C::PLAYLIST_BUTTON};
    if (audio[0] != oldLeft || !audio[1].isEmpty() || audio[2] != oldRight) return;
    profile->setModelData(PlayerControlbarModel::Audioplayer, {{
        {C::PREVIOUS_BUTTON, C::SKIP_BACK_15_BUTTON, C::PLAY_BUTTON,
         C::SKIP_FW_15_BUTTON, C::NEXT_BUTTON}, {},
        {C::VOLUME, C::EXTENDED_BUTTON, C::PLAYLIST_BUTTON}
    }});
    profile->resetDirty();
}

// Add header layouts only to profiles written before header editing existed.
// An intentionally empty saved header is a valid customized layout.
void ControlbarProfileModel::upgradeHeaderDefaults(ControlbarProfile *profile)
{
    using C = ControlListModel;
    for (const auto identifier : {PlayerControlbarModel::VideoplayerHeader,
                                 PlayerControlbarModel::AudioplayerHeader}) {
        if (!profile->getModel(identifier))
            profile->setModelData(identifier, {{{C::SOURCE_SIDEBAR_BUTTON, C::FOLDER_NAME_WIDGET},
                                                {C::FILE_NAME_WIDGET}, {}}});
    }
    profile->resetDirty();
}
