#pragma once

#include <qstring.h>
#include <qstringlist.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;

class PlayerAlias : public settings::ObjectNode {
    CONFIG_NODE(PlayerAlias, settings::ObjectNode)

    CONFIG_PROPERTY(QString, from, {})
    CONFIG_PROPERTY(QString, to, {})
};
CONFIG_LIST_TYPE(PlayerAlias, PlayerAliasList)

class DiscordArpcOverride : public settings::ObjectNode {
    CONFIG_NODE(DiscordArpcOverride, settings::ObjectNode)

    CONFIG_PROPERTY(QString, appName, u"Caelestia Shell"_s)
    CONFIG_PROPERTY(QString, details, {})
    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, largeImage, {})
    CONFIG_PROPERTY(QString, smallImage, {})
    CONFIG_PROPERTY(QString, state, {})
};

class DiscordArpc : public settings::ObjectNode {
    CONFIG_NODE(DiscordArpc, settings::ObjectNode)

    CONFIG_PROPERTY(bool, arpcEnabled, false)
    CONFIG_PROPERTY(QString, arpcClientId, u"1126685412586733678"_s)
    CONFIG_PROPERTY(bool, caelestiaInfo, false)
    CONFIG_PROPERTY(bool, steamAutoDetect, false)
    CONFIG_PROPERTY(QStringList, steamBlacklist, {})
    CONFIG_PROPERTY(QStringList, targetWindows, {})
    CONFIG_GLOBAL_SUBOBJECT(DiscordArpcOverride, manualOverride)
};

class ServiceConfig : public settings::ObjectNode {
    CONFIG_NODE(ServiceConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, weatherLocation, {})
    // Auto guesses based on locale
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, weatherUnits, TemperatureUnit::Auto)
    // Always Celsius by default cause apparently even imperial system users don't use Fahrenheit for perf temps?
    CONFIG_GLOBAL_ENUM_PROPERTY(TemperatureUnit, sensorUnits, TemperatureUnit::Celsius)
    // Binary (KiB/MiB/GiB) or decimal (KB/MB/GB) data sizes
    CONFIG_GLOBAL_ENUM_PROPERTY(DataUnit, dataUnits, DataUnit::Binary)
    CONFIG_GLOBAL_ENUM_PROPERTY(ClockFormat, clockFormat, ClockFormat::Auto)
    CONFIG_GLOBAL_ENUM_PROPERTY(GpuType, gpuType, GpuType::Auto)
    CONFIG_GLOBAL_PROPERTY(int, visualiserBars, 60)
    CONFIG_GLOBAL_PROPERTY(qreal, audioIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, brightnessIncrement, 0.1)
    CONFIG_GLOBAL_PROPERTY(qreal, maxVolume, 1.0)
    CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultPlayer, u"Spotify"_s)
    CONFIG_GLOBAL_LIST(PlayerAliasList, playerAliases,
        DEFAULT_ARG({
            vmap({ { u"from"_s, u"com.github.th_ch.youtube_music"_s }, { u"to"_s, u"YT Music"_s } }),
        }))
    CONFIG_GLOBAL_ENUM_PROPERTY(LyricsBackend, lyricsBackend, LyricsBackend::Auto)
    CONFIG_GLOBAL_SUBOBJECT(DiscordArpc, discordArpc)
};

} // namespace caelestia::shell::config
