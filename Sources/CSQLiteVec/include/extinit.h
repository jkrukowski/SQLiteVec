#ifndef EXTINIT_H
#define EXTINIT_H

#include <stdio.h>
#include "sqlite3.h"

#ifdef __cplusplus
extern "C" {
#endif

int core_vec_init();

int sqlite3_vec_init(
    sqlite3 *db,
    char **pzErrMsg,
    const sqlite3_api_routines *pApi
);

#ifdef __cplusplus
}  /* end of the 'extern "C"' block */
#endif

#endif /* extinit_h */
