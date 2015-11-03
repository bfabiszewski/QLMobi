/** @file debug.h
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#ifndef debug_h
#define debug_h

#if defined(MOBI_DEBUG)
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

#endif /* debug_h */
