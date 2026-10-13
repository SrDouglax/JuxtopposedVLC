/****************************************************************************
 * catalog.hpp : Curated configuration entries for the QML preferences view
 ****************************************************************************/
#ifndef VLC_QT_PREFERENCES_CATALOG_HPP
#define VLC_QT_PREFERENCES_CATALOG_HPP

#include <cstddef>

namespace PrefsCatalog
{
struct Option
{
    const char *category;
    const char *name;
};

const Option *options();
size_t count();
}

#endif
