/* ----------------------------------------------------------------------- *
 *
 *   Copyright 2016 Clémentine Maurice
 *   Copyright 2021 Guillaume Didier
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 *   Boston MA 02110-1301, USA; either version 2 of the License, or
 *   (at your option) any later version. *    
 *    
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *   
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * ----------------------------------------------------------------------- */


#define _GNU_SOURCE
#include "cpuid.h"
#include <assert.h>
#include <errno.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "util.h"
#include "arch.h"
#include "wrmsr.h"
#include "rdmsr.h"

#define PAGEMAP_ENTRY 8
#define GET_BIT(X, Y) (X & ((uint64_t)1 << Y)) >> Y
#define GET_PFN(X) (X & 0x7FFFFFFFFFFFFF)

const int __endian_bit = 1;
#define is_bigendian() ((*(char *)&__endian_bit) == 0)

uintptr_t read_pagemap(char *path_buf, uintptr_t virt_addr) {
    int i, c, status;
    uint64_t file_offset;
    uintptr_t read_val;
    FILE *f;

    f = fopen(path_buf, "rb");
    if (!f) {
        printf("Error! Cannot open %s\n", path_buf);
        return -1;
    }

    // Shifting by virt-addr-offset number of bytes
    // and multiplying by the size of an address (the size of an entry in
    // pagemap file)
    file_offset = virt_addr / getpagesize() * PAGEMAP_ENTRY;
    status = fseek(f, file_offset, SEEK_SET);
    if (status) {
        perror("Failed to do fseek!");
        return -1;
    }
    errno = 0;
    read_val = 0;
    unsigned char c_buf[PAGEMAP_ENTRY];
    for (i = 0; i < PAGEMAP_ENTRY; i++) {
        c = getc(f);
        if (c == EOF) {
            printf("\nReached end of the file\n");
            return 0;
        }
        if (is_bigendian())
            c_buf[i] = c;
        else
            c_buf[PAGEMAP_ENTRY - i - 1] = c;
    }
    for (i = 0; i < PAGEMAP_ENTRY; i++) {
        read_val = (read_val << 8) + c_buf[i];
    }
    if (GET_BIT(read_val, 63)) {
        // printf("PFN: 0x%llx\n",(unsigned long long) GET_PFN(read_val));
    } else {
        // printf("Page not present\n");
        return 0;
    }
    if (GET_BIT(read_val, 62)) {
        printf("Page swapped\n");
        return 0;
    }
    fclose(f);

    uintptr_t phys_addr;
    phys_addr = GET_PFN(read_val) << 12 | (virt_addr & 0xFFF);

    return phys_addr;
}

unsigned long long partition(unsigned long long a[], unsigned long long l, unsigned long long r) {
    unsigned long long pivot, i, j, t;
    pivot = a[l];
    i = l;
    j = r + 1;

    while (1) {
        do
            ++i;
        while (a[i] <= pivot && i <= r);
        do
            --j;
        while (a[j] > pivot);
        if (i >= j)
            break;
        t = a[i];
        a[i] = a[j];
        a[j] = t;
    }

    t = a[l];
    a[l] = a[j];
    a[j] = t;
    return j;
}

void quicksort(unsigned long long a[], unsigned long long l, unsigned long long r) {
    unsigned long long j;
    if (l < r) {
        // divide and conquer
        j = partition(a, l, r);
        quicksort(a, l, j - 1);
        quicksort(a, j + 1, r);
    }
}

unsigned long long cboxes[4];

void start_counters() {
    int i;
    	
    nb_cores = 4;
    int cpu_model = 94;

	if (determine_class_uarch(cpu_model) < 0) {
        exit(EXIT_FAILURE);
    }

	if (setup_perf_counters(class, archi, nb_cores) < 0) {
        exit(EXIT_FAILURE);
    }

    // Disable counters
    uint64_t val[] = {val_disable_ctrs};
    wrmsr_on_cpu_0(msr_unc_perf_global_ctr, 1, val);

    // Reset counters
    val[0] = val_reset_ctrs;
    for (i = 0; i < nb_cores; i++) {
        wrmsr_on_cpu_0(msr_unc_cbo_per_ctr0[i], 1, val);
    }

    // Select event to monitor
    val[0] = val_select_evt_core;
    for (i = 0; i < nb_cores; i++) {
        wrmsr_on_cpu_0(msr_unc_cbo_perfevtsel0[i], 1, val);
    }

    // Enable counting
    val[0] = val_enable_ctrs;
    // val[0] = val_enable_ctrs;
    wrmsr_on_cpu_0(msr_unc_perf_global_ctr, 1, val);

    for (i = 0; i < nb_cores; i++) {
        //printf("res temp %llu\n", res_temp);
        cboxes[i] = rdmsr_on_cpu_0(msr_unc_cbo_per_ctr0[i]);
    }
}


int end_counters() {
    int i = 0;

    unsigned long long res_temp;
    for (i = 0; i < nb_cores; i++) {
        res_temp = rdmsr_on_cpu_0(msr_unc_cbo_per_ctr0[i]);
        //printf("res temp %llu\n", res_temp);
        cboxes[i] = (res_temp - cboxes[i]);
    }

    int slice = 0;

    // Finding the slice in which the address is
    for (i = 0; i < 4; i++) {
        printf("Slice %d %llu\n", i, cboxes[i]);
        if (cboxes[i] > cboxes[slice]) {
            slice = i;
        }
    }

    return slice;
}